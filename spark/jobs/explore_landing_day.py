import os

from spark.session import get_spark

BUCKET = os.environ["DATALAKE_BUCKET"]
BASE = f"s3a://{BUCKET}/landing/rees46/"
DAY = "2019-10-15"

spark = get_spark("explore-landing-day")

df = (
    spark.read.option("basePath", BASE)
    .parquet(f"{BASE}event_date={DAY}/")
)

df.printSchema()
print("filas:", df.count())
df.show(5, truncate=False)
spark.stop()