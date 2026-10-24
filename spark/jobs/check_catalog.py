import os

from pyspark.sql import SparkSession

ICEBERG_VERSION = "1.11.0"
BUCKET = os.environ["DATALAKE_BUCKET"]

spark = (
    SparkSession.builder.appName("check-catalog")
    .master("local[2]")
    .config("spark.driver.memory", "3g")
    .config(
        "spark.jars.packages",
        f"org.apache.iceberg:iceberg-spark-runtime-3.5_2.12:{ICEBERG_VERSION},"
        f"org.apache.iceberg:iceberg-aws-bundle:{ICEBERG_VERSION}",
    )
    .config(
        "spark.sql.extensions",
        "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions",
    )
    .config("spark.sql.catalog.glue", "org.apache.iceberg.spark.SparkCatalog")
    .config("spark.sql.catalog.glue.type", "glue")
    .config("spark.sql.catalog.glue.warehouse", f"s3://{BUCKET}/")
    .config("spark.sql.catalog.glue.io-impl", "org.apache.iceberg.aws.s3.S3FileIO")
    .getOrCreate()
)

spark.sql("SHOW NAMESPACES IN glue").show(truncate=False)
spark.stop()