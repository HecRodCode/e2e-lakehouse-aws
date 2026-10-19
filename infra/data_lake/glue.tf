resource "aws_glue_catalog_database" "layer" {
  for_each = var.layers

  name         = each.key
  description  = "Capa ${each.key} del lakehouse"
  location_uri = "s3://${aws_s3_bucket.this["datalake"].id}/${each.key}/"
}