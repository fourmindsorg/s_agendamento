# Configuração simplificada do Terraform para s-agendamento
# Foco: Criar infraestrutura básica sem lógica complexa de reutilização

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

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-vpc"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-igw"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Subnet Pública
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-public-subnet-1"
    Environment = var.environment
    Project     = var.project_name
    Type        = "Public"
  }
}

# Subnets Privadas
resource "aws_subnet" "private" {
  count = 2

  vpc_id            = aws_vpc.main.id
  cidr_block        = count.index == 0 ? var.private_subnet_1_cidr : var.private_subnet_2_cidr
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name        = "${var.project_name}-private-subnet-${count.index + 1}"
    Environment = var.environment
    Project     = var.project_name
    Type        = "Private"
  }
}

# Route Table Pública
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = local.igw_id
  }

  tags = {
    Name        = "${var.project_name}-public-rt"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Associação da Route Table Pública
resource "aws_route_table_association" "public" {
  subnet_id      = local.public_subnet_id
  route_table_id = aws_route_table.public.id
}

# Security Group para EC2
resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-ec2-sg"
  description = "Security group for EC2 instance"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP access"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS access"
  }

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Django development server"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name        = "${var.project_name}-ec2-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Security Group para RDS
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "Security group for RDS"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
    description     = "PostgreSQL access from EC2"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name        = "${var.project_name}-rds-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}

# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = local.private_subnet_ids

  tags = {
    Name        = "${var.project_name}-db-subnet-group"
    Environment = var.environment
    Project     = var.project_name
  }
}

# RDS Instance
resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-db"
  
  engine         = "postgres"
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class
  
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_type          = var.db_storage_type
  storage_encrypted     = true
  
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password
  
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  
  backup_retention_period = var.backup_retention_period
  backup_window          = var.backup_window
  maintenance_window     = var.maintenance_window
  
  skip_final_snapshot = true
  deletion_protection = false

  tags = {
    Name        = "${var.project_name}-db"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Elastic IP
resource "aws_eip" "main" {
  domain = "vpc"

  tags = {
    Name        = "${var.project_name}-eip"
    Environment = var.environment
    Project     = var.project_name
  }
}

# EC2 Instance
resource "aws_instance" "django_server" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_pair_name

  subnet_id                   = local.public_subnet_id
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  associate_public_ip_address = true

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  user_data = base64encode(file("${path.module}/user_data_simple.sh"))

  tags = {
    Name        = "${var.project_name}-django-server"
    Environment = var.environment
    Project     = var.project_name
  }
}

# EIP Association
resource "aws_eip_association" "django_eip" {
  instance_id   = aws_instance.django_server.id
  allocation_id = aws_eip.main.id
}

# S3 Bucket para arquivos estáticos
resource "aws_s3_bucket" "static" {
  bucket = "${var.project_name}-static-${var.bucket_suffix}"

  tags = {
    Name        = "${var.project_name}-static"
    Environment = var.environment
    Project     = var.project_name
    Type        = "Static"
  }
}

# S3 Bucket para arquivos de mídia
resource "aws_s3_bucket" "media" {
  bucket = "${var.project_name}-media-${var.bucket_suffix}"

  tags = {
    Name        = "${var.project_name}-media"
    Environment = var.environment
    Project     = var.project_name
    Type        = "Media"
  }
}

# Configurações de segurança dos buckets S3
resource "aws_s3_bucket_public_access_block" "static" {
  bucket = aws_s3_bucket.static.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "media" {
  bucket = aws_s3_bucket.media.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Versionamento dos buckets
resource "aws_s3_bucket_versioning" "static" {
  bucket = aws_s3_bucket.static.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "media" {
  bucket = aws_s3_bucket.media.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Criptografia dos buckets
resource "aws_s3_bucket_server_side_encryption_configuration" "static" {
  bucket = aws_s3_bucket.static.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "media" {
  bucket = aws_s3_bucket.media.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

# Locals
locals {
  igw_id = aws_internet_gateway.main.id
  public_subnet_id = aws_subnet.public.id
  private_subnet_ids = aws_subnet.private[*].id
  
  # Tags comuns
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    CreatedBy   = "4Minds-Team"
  }
}

# Outputs
output "vpc_id" {
  description = "ID da VPC"
  value       = aws_vpc.main.id
}

output "instance_id" {
  description = "ID da instância EC2"
  value       = aws_instance.django_server.id
}

output "instance_public_dns" {
  description = "DNS público da instância EC2"
  value       = aws_instance.django_server.public_dns
}

output "rds_endpoint" {
  description = "Endpoint do RDS"
  value       = aws_db_instance.main.endpoint
}

output "static_bucket" {
  description = "Nome do bucket S3 para arquivos estáticos"
  value       = aws_s3_bucket.static.bucket
}

output "media_bucket" {
  description = "Nome do bucket S3 para arquivos de mídia"
  value       = aws_s3_bucket.media.bucket
}

output "infrastructure_status" {
  description = "Status da infraestrutura"
  value = {
    vpc_created      = "created"
    ec2_created      = "created"
    rds_created      = "created"
    s3_created       = "created"
    resources_reused = false
  }
}
