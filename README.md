# E2E Lakehouse en AWS

Proyecto de portafolio para construir un lakehouse de punta a punta con
Amazon S3, Apache Iceberg, AWS Glue Data Catalog, Spark y Athena. El repositorio
incluye infraestructura como código, procesamiento de REES46 y consultas para
explorar y validar las capas de datos.

## Arquitectura

```text
REES46 (CSV)
    |
    v
Landing (Parquet en S3)
    |
    v
Bronze (Iceberg, datos de origen y auditoría)
    |
    v
Silver (Iceberg, limpieza, deduplicación y cuarentena)
    |
    v
Gold (pendiente: modelos analíticos)
```

Landing conserva los datos de origen en Parquet particionado por fecha.
Bronze los registra en Iceberg con metadatos de ingesta. Silver aplica las
reglas de calidad descritas en el
[ADR de limpieza](docs/decisions/001-reglas-de-limpieza.md). Gold será la capa
de modelos de negocio.

Actualmente Spark se ejecuta localmente y utiliza AWS para acceder a S3 y Glue.
El código de VPC y EC2 es una extensión futura para experimentar con cómputo
distribuido; no es necesario para ejecutar el flujo actual.

## Tecnologías

- AWS S3 para almacenamiento.
- Apache Iceberg y AWS Glue Data Catalog para tablas.
- Apache Spark para ingesta y transformación.
- Amazon Athena para consultas y validación.
- Terraform para infraestructura.
- Python 3.11, `uv` y pytest para el entorno y las pruebas.

## Requisitos

- Python 3.11 y [`uv`](https://docs.astral.sh/uv/).
- Java 17 para Spark.
- AWS CLI y acceso autorizado a la cuenta/región donde se despliega el
  proyecto.
- Terraform para crear la infraestructura. El procesamiento local requiere
  que los buckets y las bases de Glue ya existan.
- El archivo REES46 de octubre de 2019, obtenido desde el
  [dataset original en Kaggle](https://www.kaggle.com/datasets/mkechinov/ecommerce-behavior-data-from-multi-category-store).

No se incluyen credenciales, archivos de estado de Terraform ni datos fuente
en el repositorio.

## Preparar el entorno local

Desde la raíz del proyecto:

```bash
uv sync --all-groups
```

Configura el perfil de AWS y la región mediante tu mecanismo de autenticación
habitual. Por ejemplo, si ya tienes un perfil local llamado `lakehouse`:

```bash
export AWS_PROFILE=lakehouse
export AWS_REGION=us-east-2
```

Si la infraestructura ya está desplegada, obtén el nombre del bucket desde el
output de Terraform, no desde un valor copiado del README:

```bash
terraform -chdir=infra/data_lake output -raw datalake_bucket
export DATALAKE_BUCKET="$(terraform -chdir=infra/data_lake output -raw datalake_bucket)"
```

Comprueba que la identidad local es la esperada antes de ejecutar jobs:

```bash
aws sts get-caller-identity
```

## Ejecutar y probar

Los comandos se ejecutan desde la raíz para que Spark encuentre los DDL en
`sql/`.

Ingesta un día de landing en Bronze:

```bash
uv run python -m spark.jobs.bronze_ingest 2019-10-01
```

El job de Bronze procesa un día por invocación. Para cargar el mes completo,
invócalo para cada día disponible en landing. Después, reconstruye Silver y la
cuarentena desde Bronze:

```bash
uv run python -m spark.jobs.silver_transform
```

Estos jobs escriben en AWS. Revisa las variables de entorno, el perfil, las
tablas destino y el código antes de ejecutarlos. No son comandos de solo
lectura.

Las pruebas locales no necesitan una cuenta AWS:

```bash
make test
```

`make` es un ejecutor de comandos: guarda atajos para las tareas repetidas.
Los targets disponibles (`test` y `sql-lint`) solo ejecutan validaciones
locales; no crean ni destruyen infraestructura.

## Infraestructura

Terraform está organizado por módulos:

- `infra/bootstrap`: bucket para el estado remoto de Terraform.
- `infra/data_lake`: buckets del lake y de resultados de Athena, bases Glue y
  workgroup.
- `infra/cluster`: red y recursos de cómputo para una etapa futura.

El bootstrap se ejecuta una sola vez. El módulo `infra/data_lake` usa estado
remoto y requiere una configuración local de backend basada en
`infra/data_lake/backend.hcl.example`; completa esos valores para tu entorno
sin subir el archivo local a Git.

Antes de cualquier `terraform apply`, revisa el plan y confirma cuenta,
región, costos y recursos a crear. No se recomienda aplicar el módulo de
clúster como parte del desarrollo local actual.

## Documentación y consultas

- [Estado y siguientes pasos](docs/project-status.md)
- [ADR 001: reglas de limpieza de REES46](docs/decisions/001-reglas-de-limpieza.md)
- [SQL de landing](sql/landing/rees46_events.sql)
- [DDL de Bronze](sql/bronze/rees46_events.sql)
- [DDL de Silver](sql/silver/rees46_events.sql)
- [DDL de cuarentena](sql/silver/rees46_events_quarantine.sql)
- [DDL de auditoría](sql/ops/pipeline_runs.sql)
- [Consultas Athena por propósito](sql/verification/)

Las consultas de `sql/verification/` son de solo lectura y están separadas
por tema: conteos y comparación de capas, calidad/nulos, cuarentena, snapshots
y métricas de archivos. Los DDL crean tablas; los jobs Spark escriben datos.

Para ejecutar consultas de Athena, selecciona la región en la que desplegaste
el proyecto y el workgroup configurado para el lake. Las rutas S3 de los DDL
deben apuntar a tus propios buckets. En
[`sql/landing/rees46_events.sql`](sql/landing/rees46_events.sql), reemplaza
`your-datalake-bucket` por el nombre devuelto por Terraform.
