resource "aws_athena_workgroup" "lakehouse" {
  name          = "lakehouse"
  force_destroy = true

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = false
    bytes_scanned_cutoff_per_query     = var.athena_scan_limit_bytes

    result_configuration {
      output_location = "s3://${aws_s3_bucket.this["athena"].id}/results/"

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }
}