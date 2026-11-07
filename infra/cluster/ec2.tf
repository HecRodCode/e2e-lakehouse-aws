# Spark Node - Ubuntu 24.04
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

# Instance profile (rol lakehouse-etl-writer).
data "aws_iam_instance_profile" "etl" {
  name = var.instance_profile_name
}

resource "aws_instance" "node" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.cluster.id]
  associate_public_ip_address = true
  iam_instance_profile        = data.aws_iam_instance_profile.etl.name

  # El sistema operativo termina la instancia ocho horas despues del arranque.
  # Al terminarla, AWS elimina el volumen raiz por delete_on_termination.
  instance_initiated_shutdown_behavior = "terminate"

  user_data                   = file("${path.module}/user_data.sh")
  user_data_replace_on_change = true

  # IMDSv2 obligatorio. El límite de saltos en 2 permite que más adelante los
  # contenedores de Docker (Airflow) también obtengan las credenciales del rol.
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.disk_gb
    encrypted             = true
    delete_on_termination = true
  }

  tags = { Name = "lakehouse-spark-node" }

  # Si Canonical publica una imagen, no recrear la máquina
  lifecycle {
    ignore_changes = [ami]
  }
}