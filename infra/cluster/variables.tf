variable "region" {
  description = "Region de AWS del proyecto"
  type        = string
  default     = "us-east-2"
}

variable "availability_zone" {
  description = "Zona de disponibilidad unica donde viviran todas las maquinas"
  type        = string
  default     = "us-east-2a"
}

variable "vpc_cidr" {
  description = "Rango de direcciones de la VPC"
  type        = string
  default     = "10.20.0.0/16"
}

variable "subnet_cidr" {
  description = "Rango de la subred publica"
  type        = string
  default     = "10.20.1.0/24"
}

variable "instance_type" {
  description = "Tipo de instancia de la maquina"
  type        = string
  default     = "m7i-flex.large"
}

variable "disk_gb" {
  description = "Tamano del disco raiz en GB"
  type        = number
  default     = 30
}

variable "instance_profile_name" {
  description = "Instance profile creado en el modulo data_lake"
  type        = string
  default     = "lakehouse-etl-writer"
}