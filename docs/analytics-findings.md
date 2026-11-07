# Hallazgos analíticos de REES46

Este documento registra resultados exploratorios obtenidos al ejecutar en
Athena las consultas de [BI](../sql/bi/) sobre las tablas Gold y el perfil de
precio en [analysis](../sql/analysis/).

**Alcance:** este proyecto procesa actualmente solo los eventos de octubre de
2019. El dataset fuente contiene siete meses de comportamiento, desde octubre
de 2019 hasta abril de 2020; los otros meses están disponibles en la fuente,
pero aún no se han incorporado a este lakehouse. Por tanto, los resultados
abajo describen únicamente octubre de 2019, no el período completo ni todo el
negocio. No se actualizan automáticamente al reprocesar o ampliar los datos.
La disponibilidad y cobertura del conjunto están descritas en la
[página fuente del dataset REES46](https://www.kaggle.com/mkechinov/ecommerce-behavior-data-from-multi-category-store).

## Actividad de compra

| Pregunta | Hallazgo |
|---|---|
| ¿Cuántos eventos `purchase` hay en Gold? | 742.773 |
| ¿Qué día tuvo más eventos? | 16 de octubre: 31.393 |
| ¿Cuántos productos distintos aparecen en esos eventos? | 42.241 |
| ¿Qué producto aparece más veces? | `product_id` 1004856: 28.938 eventos; categoría `electronics.smartphone`, marca `samsung`. |
| ¿Qué combinación de categoría y marca tiene más eventos? | `electronics.smartphone` / `samsung`: 143.477; seguida de `electronics.smartphone` / `apple`: 115.360. |

`purchase_events` cuenta eventos de compra, no órdenes ni unidades. El dataset
permite múltiples eventos `purchase` de una misma sesión que pueden formar
parte de una sola orden. Por ello, estos conteos no deben presentarse como
número de órdenes.

La marca y categoría de los resultados se toman de `dim_producto`, cuyos
atributos representan el último evento observado por producto (SCD tipo 1).
No necesariamente son los atributos vigentes en la fecha de cada compra.

## Precio de producto

La documentación del dataset fuente describe `price` como el precio del
producto asociado al evento. No identifica moneda, cantidad comprada ni ID de
orden. En consecuencia, `price` sirve para describir precios observados, pero
no para calcular ingresos: no se debe sumar el precio por evento ni asumir que
cada fila representa una orden o una unidad.

En `gold.fact_ventas` se observó:

| Métrica | Resultado |
|---|---:|
| Eventos `purchase` con precio válido y no imputado | 742.773 |
| Eventos con precio imputado | 0 |
| Productos distintos en esos eventos | 42.241 |
| Precio mínimo observado | 0,77 |
| Precio máximo observado | 2.574,07 |
| Mediana aproximada | 183,50 |
| Promedio del precio por evento | 309,56 |

Los valores están en la unidad numérica original; la fuente consultada no
especifica su moneda. El promedio es un promedio de precios asociados a
eventos, no ingreso promedio por orden.

## Actividad por usuario y sesión

La consulta de cobertura de etapas agrupa por el par `(user_id,
user_session)`. No basta agrupar por `user_session`: en los datos se
encontraron 348 identificadores de sesión asociados a más de un usuario.

| Indicador | Resultado |
|---|---:|
| Pares usuario-sesión | 9.244.770 |
| Pares con `view` | 9.243.001 |
| Pares con `cart` | 573.097 |
| Pares con `purchase` | 629.560 |
| Pares con `view` y `purchase` | 628.621 |
| Pares con los tres tipos (`view`, `cart`, `purchase`) | 291.500 |
| Pares con `view` que también tienen `purchase` | 6,8 % |

La presencia de eventos en una misma sesión mide coocurrencia, no su orden
temporal. El 6,8 % no debe describirse como una tasa de conversión de vistas a
compras sin una definición temporal de embudo y una metodología adicional.

## Consultas que reproducen los hallazgos

- [Actividad de compra por día](../sql/bi/purchase_activity_by_day.sql)
- [Productos con más eventos de compra](../sql/bi/top_products_by_purchase_events.sql)
- [Actividad por categoría y marca](../sql/bi/category_brand_purchase_activity.sql)
- [Cobertura de etapas por usuario y sesión](../sql/bi/session_event_coverage.sql)
- [Perfil de precios de compra](../sql/analysis/purchase_product_price_profile.sql)

Al volver a ejecutar las consultas, los resultados pueden cambiar si cambian
los datos, reglas de transformación o tablas Gold. Las medianas por grupo
usan `approx_percentile` y son aproximadas.
