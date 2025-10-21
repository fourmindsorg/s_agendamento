# ========================================
# AWS Other Services - Sistema de Agendamento
# RDS, S3, CloudWatch, SNS, etc.
# ========================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Variables
variable "db_password" {
  description = "Password for the RDS database"
  type        = string
  sensitive   = true
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC (usar a existente)
data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = ["agendamento-4minds-vpc"]
  }
}

# Subnets (usar as existentes)
data "aws_subnet" "public" {
  filter {
    name   = "tag:Name"
    values = ["agendamento-4minds-public-subnet"]
  }
}

# Criar subnets privadas para o RDS
resource "aws_subnet" "private_1" {
  vpc_id            = data.aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name        = "agendamento-4minds-private-subnet-1"
    Environment = "prod"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id            = data.aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name        = "agendamento-4minds-private-subnet-2"
    Environment = "prod"
  }
}

# Security Group EC2 (usar o existente)
data "aws_security_group" "ec2_sg" {
  filter {
    name   = "tag:Name"
    values = ["agendamento-4minds-ec2-sg"]
  }
}

# Security Group para RDS
resource "aws_security_group" "rds_sg" {
  name_prefix = "agendamento-4minds-rds-"
  description = "Security group para RDS"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [data.aws_security_group.ec2_sg.id]
  }

  tags = {
    Name = "agendamento-4minds-rds-sg"
  }
}

# Subnet Group para RDS
resource "aws_db_subnet_group" "main" {
  name       = "agendamento-4minds-db-subnet-group"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]

  tags = {
    Name = "agendamento-4minds-db-subnet-group"
  }
}

# RDS PostgreSQL
resource "aws_db_instance" "postgres" {
  identifier = "agendamento-4minds-postgres"

  engine         = "postgres"
  engine_version = "14"
  instance_class = "db.t4g.micro"

  allocated_storage     = 20
  max_allocated_storage = 20
  storage_type          = "gp2"
  storage_encrypted     = false

  db_name  = "agendamentos_db"
  username = "postgres"
  password = var.db_password

  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"

  skip_final_snapshot        = true
  deletion_protection        = false
  publicly_accessible        = false
  multi_az                   = false
  auto_minor_version_upgrade = true

  tags = {
    Name        = "agendamento-4minds-postgres"
    Environment = "prod"
    FreeTier    = "true"
  }
}

# S3 Bucket
resource "aws_s3_bucket" "static_files" {
  bucket = "agendamento-4minds-static-files-${random_string.bucket_suffix.result}"

  tags = {
    Name        = "agendamento-4minds-static-files"
    Environment = "prod"
    FreeTier    = "true"
  }
}

resource "aws_s3_bucket_public_access_block" "static_files" {
  bucket = aws_s3_bucket.static_files.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "static_files" {
  bucket = aws_s3_bucket.static_files.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "static_files" {
  bucket = aws_s3_bucket.static_files.id

  rule {
    id     = "cleanup-incomplete-uploads"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "django_app" {
  name              = "/aws/ec2/agendamento-4minds/django"
  retention_in_days = 7

  tags = {
    Name        = "agendamento-4minds-django-logs"
    Environment = "prod"
    FreeTier    = "true"
  }
}

# SNS Topic
resource "aws_sns_topic" "alerts" {
  name = "agendamento-4minds-alerts"

  tags = {
    Name        = "agendamento-4minds-alerts"
    Environment = "prod"
    FreeTier    = "true"
  }
}

# SNS Email Subscription
resource "aws_sns_topic_subscription" "alerts_email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = "fourmindsorg@gmail.com"
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "agendamento-4minds-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alert when EC2 CPU exceeds 80%"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = data.aws_instance.web_server.id
  }

  tags = {
    Name        = "agendamento-4minds-high-cpu-alarm"
    Environment = "prod"
    FreeTier    = "true"
  }
}

# RDS CPU Alarm
resource "aws_cloudwatch_metric_alarm" "rds_high_cpu" {
  alarm_name          = "agendamento-4minds-rds-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alert when RDS CPU exceeds 80%"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.postgres.id
  }

  tags = {
    Name        = "agendamento-4minds-rds-high-cpu-alarm"
    Environment = "prod"
    FreeTier    = "true"
  }
}

# RDS Storage Space Alarm
resource "aws_cloudwatch_metric_alarm" "rds_low_storage" {
  alarm_name          = "agendamento-4minds-rds-low-storage"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = 2147483648 # 2GB in bytes
  alarm_description   = "Alert when RDS free storage is less than 2GB"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.postgres.id
  }

  tags = {
    Name        = "agendamento-4minds-rds-low-storage-alarm"
    Environment = "prod"
    FreeTier    = "true"
  }
}

# Data source para instância EC2 existente
data "aws_instance" "web_server" {
  filter {
    name   = "tag:Name"
    values = ["agendamento-4minds-web-server"]
  }
}

# Outputs
output "rds_endpoint" {
  description = "Endpoint do RDS"
  value       = aws_db_instance.postgres.endpoint
}

output "rds_port" {
  description = "Porta do RDS"
  value       = aws_db_instance.postgres.port
}

output "rds_database_name" {
  description = "Nome do banco de dados"
  value       = aws_db_instance.postgres.db_name
}

output "rds_username" {
  description = "Usuário do banco de dados"
  value       = aws_db_instance.postgres.username
  sensitive   = true
}

output "s3_bucket_name" {
  description = "Nome do bucket S3"
  value       = aws_s3_bucket.static_files.bucket
}

output "s3_bucket_arn" {
  description = "ARN do bucket S3"
  value       = aws_s3_bucket.static_files.arn
}

output "sns_topic_arn" {
  description = "ARN do tópico SNS"
  value       = aws_sns_topic.alerts.arn
}

output "cloudwatch_log_group" {
  description = "Nome do grupo de logs CloudWatch"
  value       = aws_cloudwatch_log_group.django_app.name
}

output "database_connection_string" {
  description = "String de conexão com o banco de dados"
  value       = "postgresql://${aws_db_instance.postgres.username}:4MindsAgendamento2025!SecureDB#Pass@${aws_db_instance.postgres.endpoint}:${aws_db_instance.postgres.port}/${aws_db_instance.postgres.db_name}"
  sensitive   = true
}
