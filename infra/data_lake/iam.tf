# --- Rol de las máquinas que corren los jobs (etl-writer) ---------------------
data "aws_caller_identity" "iam" {}

locals {
  iam_account_id = data.aws_caller_identity.iam.account_id
  iam_bucket_arn = aws_s3_bucket.this["datalake"].arn
  iam_glue_arn   = "arn:aws:glue:${var.region}:${local.iam_account_id}"
  # Zonas donde el job puede escribir. landing queda fuera: solo se lee.
  iam_rw_layers = ["bronze", "silver", "gold", "ops"]
}

# Quién puede usar el rol: las instancias EC2 (nadie más).
data "aws_iam_policy_document" "ec2_assume" {
  statement {
    sid     = "EC2PuedeUsarElRol"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "etl_writer" {
  name               = "lakehouse-etl-writer"
  description        = "Rol de las instancias EC2 que corren Spark y Airflow"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

# Es lo que se "pega" a la EC2: el instance profile envuelve al rol.
resource "aws_iam_instance_profile" "etl_writer" {
  name = "lakehouse-etl-writer"
  role = aws_iam_role.etl_writer.name
}

# Entrar a la máquina por SSM Session Manager, sin puertos abiertos ni llaves.
resource "aws_iam_role_policy_attachment" "etl_writer_ssm" {
  role       = aws_iam_role.etl_writer.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Qué puede tocar el job: archivos del data lake y tablas del catálogo.
data "aws_iam_policy_document" "etl_writer_data" {
  statement {
    sid       = "ListarElBucketDelLake"
    actions   = ["s3:ListBucket", "s3:GetBucketLocation", "s3:ListBucketMultipartUploads"]
    resources = [local.iam_bucket_arn]
  }

  statement {
    sid       = "LeerLanding"
    actions   = ["s3:GetObject"]
    resources = ["${local.iam_bucket_arn}/landing/*"]
  }

  statement {
    sid       = "LeerArtefactos"
    actions   = ["s3:GetObject"]
    resources = ["${local.iam_bucket_arn}/artifacts/*"]
  }

  statement {
    sid = "LeerYEscribirCapas"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts",
    ]
    resources = [for l in local.iam_rw_layers : "${local.iam_bucket_arn}/${l}/*"]
  }

  statement {
    sid     = "CatalogoGlueParaIceberg"
    actions = ["glue:GetDatabase", "glue:GetTable", "glue:CreateTable", "glue:UpdateTable"]
    resources = concat(
      ["${local.iam_glue_arn}:catalog"],
      [for l in local.iam_rw_layers : "${local.iam_glue_arn}:database/${l}"],
      [for l in local.iam_rw_layers : "${local.iam_glue_arn}:table/${l}/*"],
    )
  }
}

resource "aws_iam_role_policy" "etl_writer_data" {
  name   = "datalake-acceso-minimo"
  role   = aws_iam_role.etl_writer.id
  policy = data.aws_iam_policy_document.etl_writer_data.json
}

output "etl_writer_role_arn" {
  value = aws_iam_role.etl_writer.arn
}

output "etl_instance_profile_name" {
  value = aws_iam_instance_profile.etl_writer.name
}