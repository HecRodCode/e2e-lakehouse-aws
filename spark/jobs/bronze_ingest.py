import os
import sys
from pathlib import Path

from pyspark.sql import functions as F

from spark.session import get_spark

BUCKET = os.environ["DATALAKE_BUCKET"]
BASE = f"s3a://{BUCKET}/landing/rees46/"
TABLE = "glue.bronze.rees46_events"
DDL = Path("sql/bronze/rees46_events.sql")

COLUMNS = [
    "event_time", "event_type", "product_id", "category_id", "category_code",
    "brand", "price", "user_id", "user_session", "event_date",
    "_ingested_at", "_source", "_batch_id",
]


def main(day: str) -> None:
    spark = get_spark(f"bronze-ingest-{day}")
    spark.conf.set("spark.sql.session.timeZone", "UTC")
    spark.conf.set("spark.sql.sources.partitionOverwriteMode", "dynamic")

    spark.sql(DDL.read_text().strip().rstrip(";"))

    batch_id = f"rees46-{day}"
    raw = spark.read.option("basePath", BASE).parquet(f"{BASE}event_date={day}/")
    n_in = raw.count()
    if n_in == 0:
        raise SystemExit(f"Lote {batch_id}: landing vacío, no se escribe nada.")

    df = (
        raw.withColumn("_ingested_at", F.current_timestamp())
        .withColumn("_source", F.lit("rees46"))
        .withColumn("_batch_id", F.lit(batch_id))
        .select(*COLUMNS)
    )
    df.writeTo(TABLE).overwritePartitions()

    n_out = spark.table(TABLE).where(F.col("event_date") == F.lit(day).cast("date")).count()
    print(f"batch={batch_id} leídas={n_in} en_bronze={n_out}")
    if n_in != n_out:
        raise SystemExit("El conteo en Bronce no coincide con el de landing.")
    spark.stop()


if __name__ == "__main__":
    main(sys.argv[1])