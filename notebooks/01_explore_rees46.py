import duckdb

con = duckdb.connect()
con.execute("SET memory_limit='4GB'; SET threads=2;")

SRC = "data/raw/2019-Oct.csv"
con.execute(f"""
    CREATE VIEW events AS
    SELECT * FROM read_csv('{SRC}', header=true,
        types={{'event_time': 'VARCHAR', 'user_id': 'BIGINT', 'product_id': 'BIGINT'}})
""")

def q(titulo, sql):
    print(f"\n### {titulo}")
    print(con.execute(sql).df().to_string(index=False))

# q("Esquema", "DESCRIBE events")

# q("Total de filas", "SELECT count(*) AS filas FROM events")

# q("Eventos por tipo", "SELECT event_type, count(*) n FROM events GROUP BY 1 ORDER BY 2 DESC")

# q("Rango de fechas", "SELECT min(event_time) desde, max(event_time) hasta FROM events")

# q("Nulos e inválidos", """SELECT
#   count(*) FILTER (WHERE category_code IS NULL) AS sin_categoria,
#   count(*) FILTER (WHERE brand IS NULL)         AS sin_marca,
#   count(*) FILTER (WHERE user_session IS NULL)  AS sin_sesion,
#   count(*) FILTER (WHERE price IS NULL OR price <= 0) AS precio_invalido
# FROM events""")

# COLS = "event_time, event_type, product_id, category_id, category_code, brand, price, user_id, user_session"

# q("Duplicados exactos (corregido)", f"""
# SELECT count(*) AS grupos_duplicados, coalesce(sum(c - 1), 0) AS filas_sobrantes
# FROM (SELECT count(*) c FROM events GROUP BY {COLS} HAVING count(*) > 1)""")

# q("Duplicados solo en purchase (los que inflarían ventas)", f"""
# SELECT count(*) AS grupos_duplicados, coalesce(sum(c - 1), 0) AS filas_sobrantes
# FROM (SELECT count(*) c FROM events WHERE event_type = 'purchase'
#       GROUP BY {COLS} HAVING count(*) > 1)""")

# q("Llaves nulas", """SELECT
#   count(*) FILTER (WHERE product_id IS NULL)  AS sin_producto,
#   count(*) FILTER (WHERE category_id IS NULL) AS sin_category_id,
#   count(*) FILTER (WHERE user_id IS NULL)     AS sin_usuario,
#   count(*) FILTER (WHERE price IS NULL)       AS precio_nulo
# FROM events""")

# q("Precio cero por tipo de evento", """SELECT event_type, count(*) AS n
# FROM events WHERE price = 0 GROUP BY 1""")

# q("Cardinalidades", """SELECT
#   count(DISTINCT user_id)      AS usuarios,
#   count(DISTINCT user_session) AS sesiones,
#   count(DISTINCT product_id)   AS productos,
#   count(DISTINCT brand)        AS marcas
# FROM events""")

# q("Compras por sesión", """SELECT compras, count(*) AS sesiones FROM (
#   SELECT user_session, count(*) AS compras FROM events
#   WHERE event_type = 'purchase' GROUP BY 1)
# GROUP BY 1 ORDER BY 1 LIMIT 10""")

# q("Precios por tipo de evento", "SELECT event_type, min(price) minimo, median(price) mediana, max(price) maximo FROM events GROUP BY 1")

# q("Productos con precio 0 en view que tienen precio válido en otros eventos", """
# SELECT count(DISTINCT p0.product_id) AS productos_con_cero,
#        count(DISTINCT p0.product_id) FILTER (WHERE pv.product_id IS NOT NULL) AS recuperables
# FROM (SELECT DISTINCT product_id FROM events WHERE price = 0) p0
# LEFT JOIN (SELECT DISTINCT product_id FROM events WHERE price > 0) pv USING (product_id)""")

# q("category_id con category_code nulo y no nulo a la vez", """
# SELECT count(*) AS category_id_mixtos FROM (
#   SELECT category_id FROM events GROUP BY category_id
#   HAVING count(*) FILTER (WHERE category_code IS NULL) > 0
#      AND count(*) FILTER (WHERE category_code IS NOT NULL) > 0)""")

# q("Variabilidad de precio por producto", """
# SELECT
#   count(*) AS productos,
#   count(*) FILTER (WHERE distintos = 1) AS un_solo_precio,
#   count(*) FILTER (WHERE distintos > 1) AS varios_precios,
#   median(max_p / min_p) AS razon_mediana_max_min
# FROM (SELECT product_id, count(DISTINCT price) AS distintos,
#              max(price) AS max_p, min(price) AS min_p
#       FROM events WHERE price > 0 GROUP BY product_id)""")

q("Variación entre productos con más de un precio", """
SELECT count(*) AS productos,
       quantile_cont(ratio, 0.5)  AS p50,
       quantile_cont(ratio, 0.9)  AS p90,
       quantile_cont(ratio, 0.99) AS p99,
       max(ratio)                 AS maximo
FROM (SELECT max(price) / min(price) AS ratio
      FROM events WHERE price > 0
      GROUP BY product_id HAVING count(DISTINCT price) > 1)""")

q("Lo mismo, solo para productos que tienen algún precio 0", """
SELECT count(*) AS productos,
       quantile_cont(ratio, 0.5)  AS p50,
       quantile_cont(ratio, 0.9)  AS p90,
       quantile_cont(ratio, 0.99) AS p99,
       max(ratio)                 AS maximo
FROM (SELECT max(price) / min(price) AS ratio
      FROM events
      WHERE price > 0
        AND product_id IN (SELECT product_id FROM events WHERE price = 0)
      GROUP BY product_id HAVING count(DISTINCT price) > 1)""")