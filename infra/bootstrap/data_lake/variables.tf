variable "region" {
  description = "Región de AWS del proyecto"
  type        = string
  default     = "us-east-2"
}

variable "layers" {
  description = "Capas medallion: una base de Glue por capa"
  type        = set(string)
  default     = ["bronze", "silver", "gold"]
}

variable "athena_scan_limit_bytes" {
  description = "Límite de bytes escaneados por consulta en Athena"
  type        = number
  default     = 10737418240 # 10 GB
}