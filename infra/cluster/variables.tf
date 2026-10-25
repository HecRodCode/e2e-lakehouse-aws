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
  default     = "24.0.0.0/16"
}

variable "subnet_cidr" {
  description = "Rango de la subred publica"
  type        = string
  default     = "24.0.1.0/24"
}