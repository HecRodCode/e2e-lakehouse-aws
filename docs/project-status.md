# Estado y roadmap

## Alcance actual

El proyecto procesa REES46 localmente con Spark y utiliza S3 y Glue para
almacenar y catalogar las tablas. EC2 y el clúster son una extensión futura,
no una dependencia del trabajo actual.

## Flujo implementado

```text
CSV -> landing (Parquet en S3) -> Bronze (Iceberg) -> Silver (Iceberg)
                                                     -> cuarentena
                                                     -> Gold (fact_ventas, dim_producto, dim_fecha)
```

- **Landing:** archivo de octubre de 2019 en Parquet, particionado por día.
- **Bronze:** conserva filas de landing y agrega metadatos de ingesta.
- **Silver:** tipifica la fecha del evento, imputa precios cuando es posible,
  reemplaza algunos nulos por `unknown` y elimina duplicados exactos.
- **Cuarentena:** separa registros con sesión nula o compras sin precio
  válido.
- **Gold:** `gold.fact_ventas` contiene 742.773 eventos `purchase`;
  `gold.dim_producto` contiene 166.794 productos y `gold.dim_fecha` cubre 31
  días calendario. El último `dbt build` reconstruyó las tres tablas y pasó
  las 19 pruebas, incluidas las relaciones del hecho con ambas dimensiones.

Las reglas de transformación están descritas en el
[ADR 001](decisions/001-reglas-de-limpieza.md).
El esquema Gold está en el README. Los resultados de las primeras consultas
de BI y sus limitaciones están en
[hallazgos analíticos](analytics-findings.md).

## Resultados compartidos de Athena

Los siguientes resultados sirven como referencia para las tablas actualmente
cargadas. Vuelve a ejecutar las consultas correspondientes si reprocesas los
datos.

| Comprobación | Resultado |
|---|---:|
| Filas en Bronze | 42.448.764 |
| Diferencias por día entre landing y Bronze | 0 filas |
| Días en Bronze | 31 |
| Filas en Silver | 42.418.542 |
| Hashes distintos en Silver | 42.418.542 |
| Filas en cuarentena | 2, ambas con `user_session_nulo` |
| Filas removidas al comparar Bronze con Silver | 30.222 |
| Duplicados exactos sobrantes eliminados | 30.220 |
| Filas en `gold.fact_ventas` | 742.773 |
| Filas en `gold.dim_producto` | 166.794 |
| Filas en `gold.dim_fecha` | 31 |

La diferencia total se explica por 30.220 duplicados eliminados y dos filas
en cuarentena. Los archivos SQL organizan las comprobaciones por propósito en
[`sql/verification/`](../sql/verification/).

## Siguientes pasos recomendados

1. Revisar y corregir las advertencias de Ruff, sin mezclar ese trabajo con
   los cambios de reproducibilidad.
2. Formular nuevas preguntas de negocio y revisar si requieren atributos o
   granularidad que aún no ofrece el modelo Gold.
3. Repetir Bronze → Silver en AWS solo cuando se quiera validar ese flujo
   contra la infraestructura desplegada. Esos jobs escriben datos y no forman
   parte de las comprobaciones locales automatizadas.
4. Considerar orquestación y cómputo en EC2 solo cuando el flujo local esté
   claro y exista una necesidad concreta.

## Reproducibilidad local

Se comprobó la instalación bloqueada de dependencias con Python 3.11 en un
entorno virtual limpio. Las pruebas locales pasan (7 pruebas, incluida la
conversión de un CSV pequeño a Parquet particionado); también pasaron SQLFluff
para las consultas de Athena, `dbt parse` y `dbt compile` sin conexión a AWS,
así como las validaciones existentes de Terraform, formato y sintaxis.

Esto valida la instalación y componentes ejecutables localmente, pero no es
una repetición integral del flujo con AWS: Landing, Bronze y Silver requieren
recursos de S3/Glue y los jobs de Bronze y Silver escriben en esas tablas. No
se ejecutaron esos jobs durante la validación. Los pasos de conversión,
carga de Landing y advertencias para operaciones que modifican AWS están en
la sección de ejecución del README.

## Pendientes técnicos conocidos

- Mantener fuera del repositorio credenciales, estado de Terraform y datos
  fuente.
