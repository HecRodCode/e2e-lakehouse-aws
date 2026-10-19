"""Convierte el CSV de REES46 a Parquet particionado por día (zona landing).

La landing conserva los datos tal como llegaron: event_time sigue siendo texto
y no se corrige nada. Solo se agrega event_date para particionar.
"""
import sys
from pathlib import Path

import duckdb


def main(src: str, dst: str) -> None:
    Path(dst).mkdir(parents=True, exist_ok=True)
    Path("data/tmp").mkdir(parents=True, exist_ok=True)

    con = duckdb.connect()
    con.execute("SET memory_limit='4GB'; SET threads=2; SET temp_directory='data/tmp';")
    con.execute(f"""
        COPY (
            SELECT *,
              CAST(replace(event_time, ' UTC', '') AS TIMESTAMP)::DATE AS event_date
            FROM read_csv('{src}', header=true,
              types={{'event_time': 'VARCHAR', 'user_id': 'BIGINT', 'product_id': 'BIGINT'}})
        ) TO '{dst}' (FORMAT parquet, PARTITION_BY (event_date), OVERWRITE_OR_IGNORE)
    """)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])