import os

from pyspark.sql import SparkSession

ICEBERG_VERSION = "1.11.0"
HADOOP_VERSION = "3.3.4"  # debe coincidir con los jars hadoop-client de pyspark


def get_spark(app_name: str) -> SparkSession:
    bucket = os.environ["DATALAKE_BUCKET"]
    region = os.environ.get("AWS_REGION", "us-east-2")
    return (
        SparkSession.builder.appName(app_name)
        .master(os.environ.get("SPARK_MASTER", "local[2]"))
        .config("spark.driver.memory", os.environ.get("SPARK_DRIVER_MEMORY", "3g"))
        .config(
            "spark.jars.packages",
            f"org.apache.iceberg:iceberg-spark-runtime-3.5_2.12:{ICEBERG_VERSION},"
            f"org.apache.iceberg:iceberg-aws-bundle:{ICEBERG_VERSION},"
            f"org.apache.hadoop:hadoop-aws:{HADOOP_VERSION}",
        )
        .config(
            "spark.sql.extensions",
            "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions",
        )
        # Catálogo Iceberg sobre Glue (tablas)
        .config("spark.sql.catalog.glue", "org.apache.iceberg.spark.SparkCatalog")
        .config("spark.sql.catalog.glue.type", "glue")
        .config("spark.sql.catalog.glue.warehouse", f"s3://{bucket}/")
        .config("spark.sql.catalog.glue.io-impl", "org.apache.iceberg.aws.s3.S3FileIO")
        # Conector s3a (archivos Parquet sueltos de landing)
        .config(
            "spark.hadoop.fs.s3a.aws.credentials.provider",
            "com.amazonaws.auth.DefaultAWSCredentialsProviderChain",
        )
        .config("spark.hadoop.fs.s3a.endpoint", f"s3.{region}.amazonaws.com")
        .getOrCreate()
    )