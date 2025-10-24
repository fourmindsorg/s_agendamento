# Configuração completa da infraestrutura AWS
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

# Gerar string aleatória para sufixo dos buckets
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# VPC
resource "aws_vpc" "main" {
  count = 1

  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-vpc"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main[0].id

  tags = {
    Name        = "${var.project_name}-igw"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Subnet Pública
resource "aws_subnet" "public" {
  count = 1

  vpc_id                  = aws_vpc.main[0].id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-public-subnet-${count.index + 1}"
    Environment = var.environment
    Project     = var.project_name
    Type        = "Public"
  }
}

# Subnet Privada
resource "aws_subnet" "private" {
  count = 1

  vpc_id            = aws_vpc.main[0].id
  cidr_block        = "10.0.2.0/24"
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
  vpc_id = aws_vpc.main[0].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main[0].id
  }

  tags = {
    Name        = "${var.project_name}-public-rt"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Associação da Route Table Pública
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Security Group para EC2
resource "aws_security_group" "ec2" {
  count = 1

  name        = "${var.project_name}-ec2-sg"
  description = "Security group para instância EC2"
  vpc_id      = aws_vpc.main[0].id

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

  # Django (8000)
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-ec2-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Security Group para RDS
resource "aws_security_group" "rds" {
  count = 1

  name        = "${var.project_name}-rds-sg"
  description = "Security group para RDS"
  vpc_id      = aws_vpc.main[0].id

  # PostgreSQL
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2[0].id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-rds-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}

# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  count = 1

  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name        = "${var.project_name}-db-subnet-group"
    Environment = var.environment
    Project     = var.project_name
  }
}

# RDS PostgreSQL
resource "aws_db_instance" "main" {
  count = 1

  identifier = "${var.project_name}-db"

  engine         = "postgres"
  engine_version = "15.4"
  instance_class = "db.t3.micro"

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp2"
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  vpc_security_group_ids = [aws_security_group.rds[0].id]
  db_subnet_group_name   = aws_db_subnet_group.main[0].name

  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  skip_final_snapshot = true
  deletion_protection = false

  tags = {
    Name        = "${var.project_name}-db"
    Environment = var.environment
    Project     = var.project_name
  }
}

# S3 Bucket para arquivos estáticos
resource "aws_s3_bucket" "static" {
  count = 1

  bucket = "${var.project_name}-static-${random_string.bucket_suffix.result}"

  tags = {
    Name        = "${var.project_name}-static"
    Environment = var.environment
    Project     = var.project_name
    Type        = "Static"
  }
}

# S3 Bucket para arquivos de mídia
resource "aws_s3_bucket" "media" {
  count = 1

  bucket = "${var.project_name}-media-${random_string.bucket_suffix.result}"

  tags = {
    Name        = "${var.project_name}-media"
    Environment = var.environment
    Project     = var.project_name
    Type        = "Media"
  }
}

# Configurações dos buckets S3
resource "aws_s3_bucket_versioning" "static" {
  count = length(aws_s3_bucket.static)

  bucket = aws_s3_bucket.static[count.index].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "media" {
  count = length(aws_s3_bucket.media)

  bucket = aws_s3_bucket.media[count.index].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "static" {
  count = length(aws_s3_bucket.static)

  bucket = aws_s3_bucket.static[count.index].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "media" {
  count = length(aws_s3_bucket.media)

  bucket = aws_s3_bucket.media[count.index].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "static" {
  count = length(aws_s3_bucket.static)

  bucket = aws_s3_bucket.static[count.index].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "media" {
  count = length(aws_s3_bucket.media)

  bucket = aws_s3_bucket.media[count.index].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Políticas dos buckets S3
resource "aws_s3_bucket_policy" "static" {
  count = length(aws_s3_bucket.static)

  bucket = aws_s3_bucket.static[count.index].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipal"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.static[count.index].arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/*"
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_policy" "media" {
  count = length(aws_s3_bucket.media)

  bucket = aws_s3_bucket.media[count.index].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipal"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.media[count.index].arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/*"
          }
        }
      }
    ]
  })
}

# Elastic IP
resource "aws_eip" "main" {
  count = 1

  domain = "vpc"

  tags = {
    Name        = "${var.project_name}-eip"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Instância EC2
resource "aws_instance" "django_server" {
  count = 1

  ami           = "ami-0c398cb65a93047f2"  # Ubuntu 22.04 LTS
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public[0].id

  vpc_security_group_ids = [aws_security_group.ec2[0].id]

  # User data script
  user_data = base64encode(templatefile("${path.module}/user_data_robust.sh", {
    domain_name   = var.domain_name
    db_endpoint   = aws_db_instance.main[0].endpoint
    db_name       = var.db_name
    db_username   = var.db_username
    db_password   = var.db_password
    secret_key    = var.secret_key
    static_bucket = aws_s3_bucket.static[0].bucket
    media_bucket  = aws_s3_bucket.media[0].bucket
  }))

  # Configurações de monitoramento
  monitoring = true

  # Configurações de armazenamento
  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }

  # Tags
  tags = {
    Name        = "${var.project_name}-django-server"
    Environment = var.environment
    Project     = var.project_name
  }

  # Lifecycle
  lifecycle {
    create_before_destroy = true
  }
}

# Associar Elastic IP
resource "aws_eip_association" "django_eip" {
  count = 1

  instance_id   = aws_instance.django_server[0].id
  allocation_id = aws_eip.main[0].id
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

# Outputs
output "vpc_id" {
  description = "ID da VPC"
  value       = aws_vpc.main[0].id
}

output "instance_id" {
  description = "ID da instância EC2"
  value       = aws_instance.django_server[0].id
}

output "instance_public_ip" {
  description = "IP público da instância EC2"
  value       = aws_eip.main[0].public_ip
}

output "instance_public_dns" {
  description = "DNS público da instância EC2"
  value       = aws_instance.django_server[0].public_dns
}

output "rds_endpoint" {
  description = "Endpoint do RDS"
  value       = aws_db_instance.main[0].endpoint
}

output "static_bucket" {
  description = "Nome do bucket S3 para arquivos estáticos"
  value       = aws_s3_bucket.static[0].bucket
}

output "media_bucket" {
  description = "Nome do bucket S3 para arquivos de mídia"
  value       = aws_s3_bucket.media[0].bucket
}

output "website_url" {
  description = "URL do website"
  value       = "http://${var.domain_name}"
}

output "admin_url" {
  description = "URL do painel administrativo"
  value       = "http://${var.domain_name}/admin/"
}
