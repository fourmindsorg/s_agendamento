# ========================================
# AWS Infrastructure - Sistema de Agendamento
# Configurado para AWS FREE TIER
# ========================================
#
# Este arquivo contém a infraestrutura completa otimizada para o Free Tier da AWS.
# Todos os recursos foram configurados para permanecer dentro dos limites gratuitos.
#
# RECURSOS INCLUÍDOS (Free Tier):
# - VPC com subnets públicas e privadas
# - EC2 t2.micro (750 horas/mês)
# - RDS PostgreSQL db.t2.micro (750 horas/mês, 20GB)
# - S3 para arquivos estáticos (5GB, 20k GET, 2k PUT)
# - CloudWatch Logs e Alarmes (5GB, 10 alarmes)
# - SNS para notificações (1,000 emails/mês)
#
# DOMÍNIO: fourmindstech.com.br
#
# IMPORTANTE:
# - Execute apenas UMA instância EC2 e UMA RDS simultaneamente
# - Monitore seu uso no AWS Cost Explorer
# - Free Tier é válido por 12 meses após criar a conta AWS
#
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
  region = var.aws_region
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Subnet Pública
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet"
  }
}

# Subnets Privadas para RDS
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${var.project_name}-private-subnet-1"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "${var.project_name}-private-subnet-2"
  }
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Key Pair - Usar chave existente ou criar nova
resource "aws_key_pair" "deployer" {
  key_name   = "${var.project_name}-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC9EDcKpFmkNctpBieANBmV3kq6mxd/u8xkKoC+h4dF5wcF/X5IatBNSYyl5KwkZymaXC4De+qcxGnwCoP6MtLEz2Js9hyjpT//sK8Lk+4+uU+RiwApXEAa0RzzpEQFXTxVu//tDyAmslvfOxSHf37wa93TRejB/hb8XZpNHkiOCaP13yEZxd2eZaDGpvHG6BMVBLTXfdhOx4ORCeuXvWQdML5uePOnonWFePc0lr9HrsImep3dJprl+6cpqczhU2OkF9AScIUB+1ZYJaCVbLGWJEenhoPT+Mfwbt8dVWBT73vcQWrZihznfIpPdZJqCuCy6oCCi1TNjrCiF+zmLRAw1yEeTjdP4ec2IYIR+2RS/V8Nnzz2sNObwMLx/5ASlqI+rTN3ko9vTDEAxE++TBDD3lo2D7wq8n6nJ0U2woE8o9qlEj+clvpb4RcCimvB6gaA3BDI/3PBd1VQu2aPI10lucJ85SPcMvV4HOahidvp1AHfM96d93Qm0mN2qDyykA6XSsws22j8bw5azGsrFDo62erIcUCkGSGreefE/k3bQnthfvJFEu6HWOaUC0pKamYEEInoBMVpq5jjfoRMzx9SfcZATmzwmpTFp3GMD/FEDlUzTFFxe/4HOzAI+y6HVmY4CcAVsF3JO+bQmpUdzHPWDa+hYjJ9qZhwLZQ73X2rDQ== carlos alberto@TheMachine"
}

# Security Group para EC2
resource "aws_security_group" "ec2_sg" {
  name_prefix = "${var.project_name}-ec2-"
  description = "Security group para EC2"
  vpc_id      = aws_vpc.main.id

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Django (Gunicorn)
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ec2-sg"
  }
}

# Security Group para RDS
resource "aws_security_group" "rds_sg" {
  name_prefix = "${var.project_name}-rds-"
  description = "Security group para RDS"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  tags = {
    Name = "${var.project_name}-rds-sg"
  }
}

# Subnet Group para RDS
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# RDS PostgreSQL - FREE TIER CONFIGURATION
# Free Tier: db.t4g.micro (ARM), 20GB storage, 750 hours/month
resource "aws_db_instance" "postgres" {
  identifier = "${var.project_name}-postgres"

  engine         = "postgres"
  engine_version = "14"          # PostgreSQL 14
  instance_class = "db.t4g.micro" # FREE TIER: 750 hours/month (ARM-based, mais moderno que t2)

  allocated_storage     = 20 # FREE TIER: up to 20GB
  max_allocated_storage = 20 # Keep at 20GB to stay in Free Tier
  storage_type          = "gp2"
  storage_encrypted     = false # Encryption may incur additional costs

  db_name  = "agendamentos_db"
  username = var.db_username
  password = var.db_password

  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  backup_retention_period = 7 # FREE TIER: up to 7 days
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"

  skip_final_snapshot        = true
  deletion_protection        = false
  publicly_accessible        = false
  multi_az                   = false # Single-AZ for Free Tier
  auto_minor_version_upgrade = true

  tags = {
    Name        = "${var.project_name}-postgres"
    Environment = var.environment
    FreeTier    = "true"
  }
}

# Instância EC2 - FREE TIER CONFIGURATION
# Free Tier: t2.micro, 750 hours/month, 30GB EBS storage
resource "aws_instance" "web_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro" # FREE TIER: 750 hours/month
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  subnet_id              = aws_subnet.public.id

  # Free Tier: 30GB of EBS General Purpose (SSD) storage
  root_block_device {
    volume_type           = "gp2"
    volume_size           = 30 # FREE TIER: up to 30GB
    delete_on_termination = true
    encrypted             = false # Encryption may incur additional costs
  }

  # Disable detailed monitoring to avoid costs
  monitoring = false

  user_data = templatefile("${path.module}/user_data.sh", {
    db_address   = aws_db_instance.postgres.address
    db_port      = aws_db_instance.postgres.port
    db_name      = aws_db_instance.postgres.db_name
    db_username  = aws_db_instance.postgres.username
    db_password  = var.db_password
    project_name = var.project_name
    domain_name  = var.domain_name
    DB_ENDPOINT  = aws_db_instance.postgres.address
    DB_PORT      = aws_db_instance.postgres.port
    DB_NAME      = aws_db_instance.postgres.db_name
    DB_USERNAME  = aws_db_instance.postgres.username
    DB_PASSWORD  = var.db_password
    PROJECT_NAME = var.project_name
    DOMAIN_NAME  = var.domain_name
  })

  tags = {
    Name        = "${var.project_name}-web-server"
    Environment = var.environment
    FreeTier    = "true"
  }
}

# S3 Bucket para arquivos estáticos - FREE TIER CONFIGURATION
# Free Tier: 5GB storage, 20,000 GET requests, 2,000 PUT requests per month
resource "aws_s3_bucket" "static_files" {
  bucket = "${var.project_name}-static-files-${random_string.bucket_suffix.result}"

  tags = {
    Name        = "${var.project_name}-static-files"
    Environment = var.environment
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

# Versioning disabled to avoid additional storage costs
# Enable only if version control is critical
resource "aws_s3_bucket_versioning" "static_files" {
  bucket = aws_s3_bucket.static_files.id
  versioning_configuration {
    status = "Disabled" # Changed to minimize costs
  }
}

# Lifecycle rule to clean up incomplete multipart uploads
resource "aws_s3_bucket_lifecycle_configuration" "static_files" {
  bucket = aws_s3_bucket.static_files.id

  rule {
    id     = "cleanup-incomplete-uploads"
    status = "Enabled"

    # Filter necessário (apply para todos os objetos)
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

# CloudWatch Log Group - FREE TIER CONFIGURATION
# Free Tier: 5GB ingestion, 5GB storage, 7 days retention recommended
resource "aws_cloudwatch_log_group" "django_app" {
  name              = "/aws/ec2/${var.project_name}/django"
  retention_in_days = 7 # Reduced to minimize costs

  tags = {
    Name        = "${var.project_name}-django-logs"
    Environment = var.environment
    FreeTier    = "true"
  }
}

# SNS Topic para alertas - FREE TIER CONFIGURATION
# Free Tier: 1,000 email notifications per month
resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts"

  tags = {
    Name        = "${var.project_name}-alerts"
    Environment = var.environment
    FreeTier    = "true"
  }
}

# SNS Email Subscription (opcional)
resource "aws_sns_topic_subscription" "alerts_email" {
  count     = var.notification_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

# CloudWatch Alarms - FREE TIER CONFIGURATION
# Free Tier: 10 alarms, 1 million API requests
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.project_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = var.cpu_threshold
  alarm_description   = "Alert when EC2 CPU exceeds ${var.cpu_threshold}%"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = aws_instance.web_server.id
  }

  tags = {
    Name        = "${var.project_name}-high-cpu-alarm"
    Environment = var.environment
    FreeTier    = "true"
  }
}

# RDS CPU Alarm
resource "aws_cloudwatch_metric_alarm" "rds_high_cpu" {
  alarm_name          = "${var.project_name}-rds-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = var.cpu_threshold
  alarm_description   = "Alert when RDS CPU exceeds ${var.cpu_threshold}%"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.postgres.id
  }

  tags = {
    Name        = "${var.project_name}-rds-high-cpu-alarm"
    Environment = var.environment
    FreeTier    = "true"
  }
}

# RDS Storage Space Alarm
resource "aws_cloudwatch_metric_alarm" "rds_low_storage" {
  alarm_name          = "${var.project_name}-rds-low-storage"
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
    Name        = "${var.project_name}-rds-low-storage-alarm"
    Environment = var.environment
    FreeTier    = "true"
  }
}

