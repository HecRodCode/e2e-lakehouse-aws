import csv

import duckdb

from ingestion.rees46.csv_to_parquet import main


def test_csv_to_partitioned_parquet_preserves_events(tmp_path, monkeypatch):
    monkeypatch.chdir(tmp_path)
    source = tmp_path / "events.csv"
    destination = tmp_path / "landing"
    rows = [
        {
            "event_time": "2019-10-01 10:00:00 UTC",
            "event_type": "view",
            "product_id": "101",
            "category_id": "12",
            "category_code": "electronics.phone",
            "brand": "example",
            "price": "10.5",
            "user_id": "1001",
            "user_session": "session-a",
        },
        {
            "event_time": "2019-10-02 11:30:00 UTC",
            "event_type": "purchase",
            "product_id": "102",
            "category_id": "13",
            "category_code": "electronics.audio",
            "brand": "example",
            "price": "20.0",
            "user_id": "1002",
            "user_session": "session-b",
        },
    ]
    with source.open("w", newline="") as file:
        writer = csv.DictWriter(file, fieldnames=rows[0].keys())
        writer.writeheader()
        writer.writerows(rows)

    main(str(source), str(destination))

    parquet_glob = str(destination / "**" / "*.parquet")
    connection = duckdb.connect()
    result = connection.execute(
        """
        SELECT
            count(*) AS rows,
            count(DISTINCT event_date) AS partition_days,
            count_if(event_time LIKE '% UTC') AS original_timestamp_strings,
            count_if(product_id IS NOT NULL AND user_id IS NOT NULL) AS typed_ids
        FROM read_parquet(?, hive_partitioning = true)
        """,
        [parquet_glob],
    ).fetchone()
    connection.close()

    assert result == (2, 2, 2, 2)
