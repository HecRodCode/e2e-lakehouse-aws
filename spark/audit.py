from datetime import datetime, timezone
from pathlib import Path

from pyspark.sql import SparkSession
from pyspark.sql.types import (
    DoubleType, LongType, StringType, StructField, StructType, TimestampNTZType,
)

TABLE = "glue.ops.pipeline_runs"
DDL = Path("sql/ops/pipeline_runs.sql")

SCHEMA = StructType([
    StructField("run_id", StringType()),
    StructField("pipeline", StringType()),
    StructField("status", StringType()),
    StructField("started_at", TimestampNTZType()),
    StructField("finished_at", TimestampNTZType()),
    StructField("duration_seconds", DoubleType()),
    StructField("rows_read", LongType()),
    StructField("rows_written", LongType()),
    StructField("rows_rejected", LongType()),
    StructField("details", StringType()),
    StructField("error_message", StringType()),
])


def utc_now() -> datetime:
    """Hora UTC sin zona (coincide con TIMESTAMP_NTZ)."""
    return datetime.now(timezone.utc).replace(tzinfo=None)


def run_row(run_id, pipeline, status, started_at, finished_at,
            rows_read=None, rows_written=None, rows_rejected=None,
            details=None, error_message=None) -> tuple:
    duration = (finished_at - started_at).total_seconds()
    return (run_id, pipeline, status, started_at, finished_at, duration,
            rows_read, rows_written, rows_rejected, details, error_message)


def ensure_table(spark: SparkSession) -> None:
    spark.sql(DDL.read_text().strip().rstrip(";"))


def record_run(spark: SparkSession, **fields) -> None:
    spark.createDataFrame([run_row(**fields)], SCHEMA).writeTo(TABLE).append()