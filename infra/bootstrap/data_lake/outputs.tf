output "datalake_bucket" {
  value = aws_s3_bucket.this["datalake"].id
}

output "athena_results_bucket" {
  value = aws_s3_bucket.this["athena"].id
}

output "athena_workgroup" {
  value = aws_athena_workgroup.lakehouse.name
}

output "glue_databases" {
  value = [for db in aws_glue_catalog_database.layer : db.name]
}