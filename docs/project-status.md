# Estado y roadmap

## Alcance actual

El proyecto procesa REES46 localmente con Spark y utiliza S3 y Glue para
almacenar y catalogar las tablas. EC2 y el clúster son una extensión futura,
no una dependencia del trabajo actual.

## Flujo implementado

```text
CSV -> landing (Parquet en S3) -> Bronze (Iceberg) -> Silver (Iceberg)
                                                     -> cuarentena
                                                     -> Gold (pendiente)
```

- **Landing:** archivo de octubre de 2019 en Parquet, particionado por día.
- **Bronze:** conserva filas de landing y agrega metadatos de ingesta.
- **Silver:** tipifica la fecha del evento, imputa precios cuando es posible,
  reemplaza algunos nulos por `unknown` y elimina duplicados exactos.
- **Cuarentena:** separa registros con sesión nula o compras sin precio
  válido.
- **Gold:** todavía no implementada; contendrá los modelos analíticos.

Las reglas de transformación están descritas en el
[ADR 001](decisions/001-reglas-de-limpieza.md).

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

La diferencia total se explica por 30.220 duplicados eliminados y dos filas
en cuarentena. Los archivos SQL organizan las comprobaciones por propósito en
[`sql/verification/`](../sql/verification/).

## Siguientes pasos recomendados

1. Repetir las validaciones de Bronze y Silver después de cualquier
   reproceso, y guardar el resultado de Athena fuera de este README.
2. Confirmar que el flujo Spark puede correrse localmente desde un entorno
   limpio con la configuración de AWS proporcionada por cada desarrollador.
3. Diseñar Gold definiendo primero la granularidad y las llaves de los hechos
   y dimensiones. En particular, `fact_ventas` debe representar un evento
   `purchase`, no una sesión.
4. Implementar un primer modelo Gold con dbt-athena y agregar pruebas de
   calidad.
5. Considerar orquestación y cómputo en EC2 solo cuando el flujo local
   Bronze → Silver → Gold esté claro y exista una necesidad concreta.

## Pendientes técnicos conocidos

- Revisar advertencias existentes de Ruff.
- Mantener fuera del repositorio credenciales, estado de Terraform y datos
  fuente.
- Revisar los CIDR del módulo de clúster antes de considerar cualquier
  despliegue. Ese módulo no es necesario para la etapa actual.
