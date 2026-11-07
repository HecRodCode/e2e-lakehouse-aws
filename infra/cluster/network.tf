# --- VPC propia del clúster ---------------------------------------------------
# VPC, subred, rutas, internet gateway y endpoint gateway de S3 no tienen cargo
# horario; la EC2, el volumen EBS, la IPv4 publica y la transferencia de datos
# si pueden generar costos.
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "lakehouse-spark" }
}

# La puerta de salida a internet (Maven, SSM, APIs de AWS).
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = { Name = "lakehouse-spark" }
}

# Una sola subred pública, en una sola zona: todo el tráfico entre nodos
# del clúster queda dentro de la misma zona (el tráfico entre zonas se cobra).
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = { Name = "lakehouse-spark-public" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = { Name = "lakehouse-spark-public" }
}

# Todo lo que no sea de la VPC sale por el internet gateway.
resource "aws_route" "internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# S3 por un camino privado dentro de AWS, sin pasar por internet. Gratis.
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.public.id]

  tags = { Name = "lakehouse-spark-s3" }
}

# --- Grupo de seguridad: nadie entra desde internet ---------------------------
# (las descripciones van sin tildes: AWS no las acepta en este campo)
resource "aws_security_group" "cluster" {
  name        = "lakehouse-spark-cluster"
  description = "Spark and Airflow nodes: no inbound from the internet"
  vpc_id      = aws_vpc.this.id

  tags = { Name = "lakehouse-spark-cluster" }
}

# Unica entrada: de las propias maquinas del grupo entre si (master, workers,
# Airflow). Ninguna direccion de internet figura como origen.
resource "aws_vpc_security_group_ingress_rule" "self" {
  security_group_id            = aws_security_group.cluster.id
  referenced_security_group_id = aws_security_group.cluster.id
  ip_protocol                  = "-1"
  description                  = "All traffic between members of this group"
}

# Salida libre: necesaria para Maven, SSM, Glue y S3.
resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.cluster.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Outbound to anywhere"
}