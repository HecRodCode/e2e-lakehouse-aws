resource "aws_glue_catalog_database" "layer" {
  for_each = var.layers

  name         = each.key
  description  = "Capa ${each.key} de la arquitectura medallion"
  location_uri = "s3://${aws_s3_bucket.this["datalake"].id}/${each.key}/"
}