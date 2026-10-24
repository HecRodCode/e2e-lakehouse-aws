from datetime import datetime, timezone
from pathlib import Path

from pyspark.sql import DataFrame, Window, functions as F

from spark.session import get_spark

BRONZE = "glue.bronze.rees46_events"
SILVER = "glue.silver.rees46_events"
QUARANTINE = "glue.silver.rees46_events_quarantine"
DDLS = [
    Path("sql/silver/rees46_events.sql"),
    Path("sql/silver/rees46_events_quarantine.sql"),
]

HASH_COLS = [
    "event_time", "event_type", "product_id", "category_id", "category_code",
    "brand", "price", "user_id", "user_session",
]
SILVER_COLUMNS = [
    "event_time", "event_date", "event_type", "product_id", "category_id",
    "category_code", "brand", "price", "price_imputed", "price_is_valid",
    "user_id", "user_session", "event_hash", "_silver_batch_id", "_processed_at",
]
QUARANTINE_COLUMNS = [
    "event_time", "event_date", "event_type", "product_id", "category_id",
    "category_code", "brand", "price", "user_id", "user_session",
    "reject_reason", "_silver_batch_id", "_processed_at",
]


def split_quarantine(df: DataFrame) -> tuple[DataFrame, DataFrame]:
    reason = (
        F.when(F.col("user_session").isNull(), F.lit("user_session_nulo"))
        .when(
            (F.col("event_type") == "purchase")
            & (F.col("price").isNull() | (F.col("price") <= 0)),
            F.lit("purchase_sin_precio_valido"),
        )
    )
    flagged = df.withColumn("reject_reason", reason)
    clean = flagged.where(F.col("reject_reason").isNull()).drop("reject_reason")
    rejected = flagged.where(F.col("reject_reason").isNotNull())
    return clean, rejected


def clean_events(df: DataFrame) -> DataFrame:
    parts = [F.coalesce(F.col(c).cast("string"), F.lit("<NULL>")) for c in HASH_COLS]
    return (
        df.withColumn("event_hash", F.sha2(F.concat_ws("\x1f", *parts), 256))
        .dropDuplicates(["event_hash"])
        .withColumn(
            "event_time",
            F.regexp_replace("event_time", r" UTC$", "").cast("timestamp_ntz"),
        )
        .withColumn("category_code", F.coalesce("category_code", F.lit("unknown")))
        .withColumn("brand", F.coalesce("brand", F.lit("unknown")))
        .withColumn("price_imputed", F.lit(False))
        .withColumn("price_is_valid", F.coalesce(F.col("price") > 0, F.lit(False)))
    )


def impute_prices(df: DataFrame) -> DataFrame:
    """ADR regla 3: un precio <= 0 o nulo se reemplaza por el precio válido del
    mismo producto más cercano en el tiempo (el anterior; si no hay, el siguiente)."""
    is_ok = F.coalesce(F.col("price") > 0, F.lit(False))
    base = df.withColumn("_valid_price", F.when(is_ok, F.col("price")))

    # Solo los productos que tienen algún precio inválido necesitan la ventana
    affected = base.where(~is_ok).select("product_id").distinct()
    ordered = Window.partitionBy("product_id").orderBy("event_time", "event_hash")
    before = ordered.rowsBetween(Window.unboundedPreceding, Window.currentRow)
    after = ordered.rowsBetween(Window.currentRow, Window.unboundedFollowing)

    fills = (
        base.join(F.broadcast(affected), "product_id")
        .withColumn(
            "_fill",
            F.coalesce(
                F.last("_valid_price", ignorenulls=True).over(before),
                F.first("_valid_price", ignorenulls=True).over(after),
            ),
        )
        .where(~is_ok)
        .select("event_hash", "_fill")
    )

    return (
        base.join(F.broadcast(fills), "event_hash", "left")
        .withColumn("price_imputed", F.col("_fill").isNotNull())
        .withColumn("price", F.when(is_ok, F.col("price")).otherwise(F.col("_fill")))
        .withColumn("price_is_valid", F.col("price").isNotNull())
        .drop("_valid_price", "_fill")
    )


def main() -> None:
    spark = get_spark("silver-transform")
    spark.conf.set("spark.sql.session.timeZone", "UTC")
    try:
        for ddl in DDLS:
            spark.sql(ddl.read_text().strip().rstrip(";"))

        batch_id = "silver-" + datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S")
        stamp = F.current_timestamp().cast("timestamp_ntz")

        bronze = spark.table(BRONZE)
        n_in = bronze.count()
        if n_in == 0:
            raise SystemExit("Bronce está vacío.")

        ok, rejected = split_quarantine(bronze)

        silver = (
            impute_prices(clean_events(ok))
            .withColumn("_silver_batch_id", F.lit(batch_id))
            .withColumn("_processed_at", stamp)
            .select(*SILVER_COLUMNS)
        )
        silver.writeTo(SILVER).overwritePartitions()

        # Silver se reconstruye completa; la cuarentena también
        spark.sql(f"DELETE FROM {QUARANTINE}")
        (
            rejected.withColumn("_silver_batch_id", F.lit(batch_id))
            .withColumn("_processed_at", stamp)
            .select(*QUARANTINE_COLUMNS)
            .writeTo(QUARANTINE)
            .append()
        )

        s = spark.table(SILVER)
        n_silver = s.count()
        n_quar = spark.table(QUARANTINE).count()
        n_imputed = s.where("price_imputed").count()
        n_no_price = s.where("NOT price_is_valid").count()
        n_dups = n_in - n_quar - n_silver
        print(
            f"{batch_id} bronce={n_in} silver={n_silver} cuarentena={n_quar} "
            f"duplicados_eliminados={n_dups} precios_imputados={n_imputed} "
            f"sin_precio_valido={n_no_price}"
        )
        if n_dups < 0:
            raise SystemExit("Silver + cuarentena superan lo leído de Bronce.")
    finally:
        spark.stop()


if __name__ == "__main__":
    main()