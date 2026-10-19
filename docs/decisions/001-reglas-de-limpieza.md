# ADR 001: Reglas de limpieza para REES46 (eventos e-commerce)

- **Estado:** Aceptado
- **Fecha:** 2026-10-18
- **Alcance:** capas Bronze y Silver, fuente REES46 (muestra: octubre de 2019)

## Contexto

Exploramos el archivo `2019-Oct.csv` (≈5 GB descomprimido) con DuckDB antes de
diseñar el pipeline. El dataset trae eventos de comportamiento de una tienda
en línea: 9 columnas, sin identificador de evento.

| Hallazgo                                        | Valor                                                          |
| ----------------------------------------------- | -------------------------------------------------------------- |
| Filas totales                                   | 42.448.764 (1 al 31 de oct 2019, sin huecos)                   |
| view / cart / purchase                          | 40.779.399 / 926.516 / 742.849                                 |
| `category_code` nulo                            | 13.515.609 (31,8 %)                                            |
| `brand` nulo                                    | 6.113.008 (14,4 %)                                             |
| `user_session` nulo                             | 2                                                              |
| Precio = 0                                      | 68.523 en view, 150 en cart, 0 en purchase                     |
| Precios negativos o nulos                       | 0                                                              |
| Llaves nulas (product_id, category_id, user_id) | 0                                                              |
| Duplicados exactos                              | 18.099 grupos, 30.220 filas sobrantes (0,07 %)                 |
| Duplicados exactos en purchase                  | 76 grupos, 76 filas sobrantes                                  |
| Usuarios / sesiones / productos / marcas        | 3.022.290 / 9.244.421 / 166.794 / 3.445                        |
| Compras por sesión                              | 549.299 sesiones con 1; 60.647 con 2; 12.859 con 3; cola larga |
| `event_time`                                    | texto con sufijo ` UTC`                                        |

## Decisiones

1. **Bronze es append-only y conserva todo**, incluidos duplicados y precios
   en 0. No se corrige nada en esta capa; solo se agregan columnas de auditoría
   (`_ingested_at`, `_source`, `_batch_id`). La idempotencia se logra con el
   `_batch_id`: re-ejecutar un lote reemplaza ese lote, no lo duplica.

2. **`event_time`:** en Silver se quita el sufijo ` UTC` y se convierte a
   `TIMESTAMP` en UTC. Se agrega `event_date` (DATE) como columna de partición.

3. **Precio = 0 en view/cart:** el precio se considera inválido (un producto
   no cuesta 0). En Silver se intenta recuperar con el último precio válido
   del mismo producto anterior al evento (si no hay anterior, el siguiente más
   cercano). La fila se conserva siempre porque el evento ocurrió y es
   necesaria para el embudo. Se agregan dos columnas:
   - `price_imputed` (boolean): true si el precio fue recuperado.
   - `price_is_valid` (boolean): false si no existe ningún precio válido para
     el producto; en ese caso `price` queda en `NULL`.

4. **Precio nulo o ≤ 0 en purchase:** la fila va a la tabla de cuarentena
   con el motivo. Hoy no ocurre en octubre, pero la regla debe existir y
   estar probada, porque una venta sin precio válido contaminaría
   `fact_ventas`.

5. **`user_session` nulo:** la fila va a cuarentena con el motivo
   (2 filas en octubre).

6. **`category_code` y `brand` nulos:** se conservan y se rellenan con el
   valor explícito `'unknown'`. Descartar estas filas eliminaría casi un
   tercio de los eventos.

7. **Duplicados exactos:** en Silver se elimina el sobrante conservando una
   copia, usando un hash de las 9 columnas (`event_hash`) como llave de
   deduplicación. **Suposición documentada:** el dataset no trae id de evento,
   por lo que no podemos distinguir un error de captura de dos acciones
   idénticas legítimas en el mismo segundo. Se asume lo primero, dado que
   afecta al 0,07 % de las filas y al 0,01 % de las compras.

8. **Granularidad de `fact_ventas`:** una fila por evento `purchase`
   (línea de compra), **no** por sesión. Hay sesiones con varias compras
   (≈ 80.000 sesiones con 2 o más solo contando hasta 10), así que agregar a
   nivel de sesión perdería información.

9. **`dim_clientes`:** el dataset solo trae `user_id`, sin atributos
   personales. Para practicar SCD tipo 2 y enmascaramiento de PII, los
   atributos (correo, ciudad) se generarán con Faker y se marcarán como
   sintéticos en el contrato de datos.

## Consecuencias

- Silver necesita dos salidas: tabla limpia y tabla de cuarentena, con el
  motivo del rechazo como columna.

- Las reglas 3 a 7 se implementan como pruebas de calidad (dbt tests o
  Great Expectations) y se validan en CI.

- Si la suposición de la regla 7 resultara errónea, Bronze conserva los
  datos originales y se puede reprocesar Silver sin volver a descargar.

## Pendiente de verificar

- ¿Los productos con precio 0 en view tienen un precio válido en otros
  eventos? Si es así, se podría reconstruir el precio en vez de dejarlo nulo.

- ¿Un mismo `category_id` aparece con `category_code` en unas filas y nulo en
  otras? Si es así, el `category_code` nulo se puede rellenar desde otras filas
  del mismo `category_id` en lugar de dejarlo como `'unknown'`.

## Verificaciones realizadas (2026-10-19)

- De 11.095 productos con precio 0 en algún evento, 9.948 (≈ 90 %) tienen
  un precio válido en otros eventos, por lo que se recuperan (decisión 3).
  Los 1.147 restantes quedan con `price = NULL`.

- Ningún `category_id` aparece a la vez con `category_code` nulo y no nulo:
  los nulos corresponden a categorías completas sin código, por lo que no
  se pueden reconstruir y se mantiene el valor `'unknown'` (decisión 6).

- Variación de precio: el 70 % de los productos tiene un único precio en el
  mes. Entre los 2.118 productos a imputar que tienen más de un precio, la
  razón máx/mín tiene mediana 1,12, p90 1,45 y p99 2,15. Se acepta el error
  de usar el precio válido más cercano en el tiempo (el anterior; si no existe,
  el siguiente) porque: (a) ≈7.830 de los 9.948 recuperables tienen un solo
  precio, (b) el impacto no alcanza a `fact_ventas` (ningún `purchase` tiene
  precio 0) y (c) `price_imputed` permite excluir estos valores aguas abajo.
