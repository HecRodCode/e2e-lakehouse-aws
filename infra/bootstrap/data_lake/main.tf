data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id

  buckets = {
    datalake = "lakehouse-datalake-${local.account_id}"
    athena   = "lakehouse-athena-results-${local.account_id}"
  }
}

resource "aws_s3_bucket" "this" {
  for_each = local.buckets
  bucket   = each.value
}

resource "aws_s3_bucket_public_access_block" "this" {
  for_each = aws_s3_bucket.this
  bucket   = each.value.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  for_each = aws_s3_bucket.this
  bucket   = each.value.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "datalake" {
  bucket = aws_s3_bucket.this["datalake"].id

  rule {
    id     = "limpiar-multipart-incompletos"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "athena" {
  bucket = aws_s3_bucket.this["athena"].id

  rule {
    id     = "expirar-resultados-a-7-dias"
    status = "Enabled"

    filter {}

    expiration {
      days = 7
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}