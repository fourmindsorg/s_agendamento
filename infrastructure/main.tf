# =============================================================================
# INFRAESTRUTURA AWS PARA SISTEMA DE AGENDAMENTO
# Arquitetura: Multi-tier, High Availability, Cost-Optimized
# =============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      CreatedBy   = "4Minds-Team"
    }
  }
}

# =============================================================================
# DATA SOURCES - RECURSOS EXISTENTES
# =============================================================================

# Verificar VPC existente
data "aws_vpc" "existing" {
  count = var.reuse_existing_resources ? 1 : 0
  
  filter {
    name   = "tag:Name"
    values = ["${var.project_name}-vpc"]
  }
  
  filter {
    name   = "state"
    values = ["available"]
  }
}

# Verificar Internet Gateway existente
data "aws_internet_gateway" "existing" {
  count = var.reuse_existing_resources ? 1 : 0
  
  filter {
    name   = "tag:Name"
    values = ["${var.project_name}-igw"]
  }
  
  filter {
    name   = "state"
    values = ["available"]
  }
}

# Verificar subnets existentes
data "aws_subnet" "existing_public" {
  count = var.reuse_existing_resources ? 1 : 0
  
  filter {
    name   = "tag:Name"
    values = ["${var.project_name}-public-subnet-1"]
  }
  
  filter {
    name   = "state"
    values = ["available"]
  }
}

data "aws_subnet" "existing_private" {
  count = var.reuse_existing_resources ? 2 : 0
  
  filter {
    name   = "tag:Name"
    values = ["${var.project_name}-private-subnet-1", "${var.project_name}-private-subnet-2"]
  }
  
  filter {
    name   = "state"
    values = ["available"]
  }
}

# Verificar Security Groups existentes
data "aws_security_group" "existing_ec2" {
  count = var.reuse_existing_resources ? 1 : 0
  
  filter {
    name   = "tag:Name"
    values = ["${var.project_name}-ec2-sg"]
  }
}

data "aws_security_group" "existing_rds" {
  count = var.reuse_existing_resources ? 1 : 0
  
  filter {
    name   = "tag:Name"
    values = ["${var.project_name}-rds-sg"]
  }
}

# Verificar RDS existente
data "aws_db_instance" "existing" {
  count = var.reuse_existing_resources ? 1 : 0
  
  db_instance_identifier = "${var.project_name}-db"
}

# Verificar EC2 existente
data "aws_instance" "existing" {
  count = var.reuse_existing_resources ? 1 : 0
  
  filter {
    name   = "tag:Name"
    values = ["${var.project_name}-django-server"]
  }
  
  filter {
    name   = "instance-state-name"
    values = ["running", "pending", "stopped"]
  }
}

# Verificar S3 buckets existentes
data "aws_s3_bucket" "existing_static" {
  count = var.reuse_existing_resources ? 1 : 0
  
  bucket = "${var.project_name}-static-${var.bucket_suffix}"
}

data "aws_s3_bucket" "existing_media" {
  count = var.reuse_existing_resources ? 1 : 0
  
  bucket = "${var.project_name}-media-${var.bucket_suffix}"
}

# Verificar Elastic IP existente
data "aws_eip" "existing" {
  count = var.reuse_existing_resources ? 1 : 0
  
  filter {
    name   = "tag:Name"
    values = ["${var.project_name}-eip"]
  }
  
  filter {
    name   = "domain"
    values = ["vpc"]
  }
}

# Availability Zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Caller Identity
data "aws_caller_identity" "current" {}

# =============================================================================
# LOCALS - LÓGICA DE REUTILIZAÇÃO
# =============================================================================

locals {
  # VPC
  vpc_id = var.reuse_existing_resources && length(data.aws_vpc.existing) > 0 ? data.aws_vpc.existing[0].id : aws_vpc.main[0].id
  
  # Internet Gateway
  igw_id = var.reuse_existing_resources && length(data.aws_internet_gateway.existing) > 0 ? data.aws_internet_gateway.existing[0].id : aws_internet_gateway.main[0].id
  
  # Subnets
  public_subnet_id = var.reuse_existing_resources && length(data.aws_subnet.existing_public) > 0 ? data.aws_subnet.existing_public[0].id : aws_subnet.public[0].id
  private_subnet_ids = var.reuse_existing_resources && length(data.aws_subnet.existing_private) > 0 ? data.aws_subnet.existing_private[*].id : [aws_subnet.private[0].id, aws_subnet.private[1].id]
  
  # Security Groups
  ec2_sg_id = var.reuse_existing_resources && length(data.aws_security_group.existing_ec2) > 0 ? data.aws_security_group.existing_ec2[0].id : aws_security_group.ec2[0].id
  rds_sg_id = var.reuse_existing_resources && length(data.aws_security_group.existing_rds) > 0 ? data.aws_security_group.existing_rds[0].id : aws_security_group.rds[0].id
  
  # RDS
  rds_endpoint = var.reuse_existing_resources && length(data.aws_db_instance.existing) > 0 ? data.aws_db_instance.existing[0].endpoint : aws_db_instance.main[0].endpoint
  
  # S3 Buckets
  static_bucket = var.reuse_existing_resources && length(data.aws_s3_bucket.existing_static) > 0 ? data.aws_s3_bucket.existing_static[0].bucket : aws_s3_bucket.static[0].bucket
  media_bucket = var.reuse_existing_resources && length(data.aws_s3_bucket.existing_media) > 0 ? data.aws_s3_bucket.existing_media[0].bucket : aws_s3_bucket.media[0].bucket
  
  # Elastic IP
  eip_id = var.reuse_existing_resources && length(data.aws_eip.existing) > 0 ? data.aws_eip.existing[0].id : aws_eip.main[0].id
  eip_public_ip = var.reuse_existing_resources && length(data.aws_eip.existing) > 0 ? data.aws_eip.existing[0].public_ip : aws_eip.main[0].public_ip
  
  # EC2
  instance_id = var.reuse_existing_resources && length(data.aws_instance.existing) > 0 ? data.aws_instance.existing[0].id : aws_instance.django_server[0].id
}

# =============================================================================
# RECURSOS AWS - CRIAR APENAS SE NÃO EXISTIREM
# =============================================================================

# VPC
resource "aws_vpc" "main" {
  count = var.reuse_existing_resources && length(data.aws_vpc.existing) > 0 ? 0 : 1
  
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  count = var.reuse_existing_resources && length(data.aws_internet_gateway.existing) > 0 ? 0 : 1
  
  vpc_id = local.vpc_id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Subnet Pública
resource "aws_subnet" "public" {
  count = var.reuse_existing_resources && length(data.aws_subnet.existing_public) > 0 ? 0 : 1
  
  vpc_id                  = local.vpc_id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet-1"
    Type = "Public"
  }
}

# Subnets Privadas (Multi-AZ para RDS)
resource "aws_subnet" "private" {
  count = var.reuse_existing_resources && length(data.aws_subnet.existing_private) > 0 ? 0 : 2
  
  vpc_id            = local.vpc_id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.project_name}-private-subnet-${count.index + 1}"
    Type = "Private"
  }
}

# Route Table Pública
resource "aws_route_table" "public" {
  count = var.reuse_existing_resources && length(data.aws_subnet.existing_public) > 0 ? 0 : 1
  
  vpc_id = local.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = local.igw_id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# Associação da Route Table Pública
resource "aws_route_table_association" "public" {
  count = var.reuse_existing_resources && length(data.aws_subnet.existing_public) > 0 ? 0 : 1
  
  subnet_id      = local.public_subnet_id
  route_table_id = aws_route_table.public[0].id
}

# Security Group para EC2
resource "aws_security_group" "ec2" {
  count = var.reuse_existing_resources && length(data.aws_security_group.existing_ec2) > 0 ? 0 : 1
  
  name        = "${var.project_name}-ec2-sg"
  description = "Security group for EC2 instance"
  vpc_id      = local.vpc_id

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidrs
    description = "SSH access"
  }

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP access"
  }

  # HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS access"
  }

  # Django (8000)
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
    Name = "${var.project_name}-ec2-sg"
  }
}

# Security Group para RDS
resource "aws_security_group" "rds" {
  count = var.reuse_existing_resources && length(data.aws_security_group.existing_rds) > 0 ? 0 : 1
  
  name        = "${var.project_name}-rds-sg"
  description = "Security group for RDS"
  vpc_id      = local.vpc_id

  # PostgreSQL
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [local.ec2_sg_id]
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
    Name = "${var.project_name}-rds-sg"
  }
}

# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  count = var.reuse_existing_resources && length(data.aws_db_instance.existing) > 0 ? 0 : 1
  
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = local.private_subnet_ids

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# RDS PostgreSQL
resource "aws_db_instance" "main" {
  count = var.reuse_existing_resources && length(data.aws_db_instance.existing) > 0 ? 0 : 1
  
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

  vpc_security_group_ids = [local.rds_sg_id]
  db_subnet_group_name   = aws_db_subnet_group.main[0].name

  backup_retention_period = var.backup_retention_period
  backup_window          = var.backup_window
  maintenance_window     = var.maintenance_window

  skip_final_snapshot = true
  deletion_protection = var.deletion_protection

  # Configurações de performance
  performance_insights_enabled = var.performance_insights_enabled
  monitoring_interval         = var.monitoring_interval
  monitoring_role_arn        = var.monitoring_interval > 0 ? aws_iam_role.rds_enhanced_monitoring[0].arn : null

  tags = {
    Name = "${var.project_name}-db"
  }
}

# S3 Bucket para arquivos estáticos
resource "aws_s3_bucket" "static" {
  count = var.reuse_existing_resources && length(data.aws_s3_bucket.existing_static) > 0 ? 0 : 1
  
  bucket = "${var.project_name}-static-${var.bucket_suffix}"

  tags = {
    Name = "${var.project_name}-static"
    Type = "Static"
  }
}

# S3 Bucket para arquivos de mídia
resource "aws_s3_bucket" "media" {
  count = var.reuse_existing_resources && length(data.aws_s3_bucket.existing_media) > 0 ? 0 : 1
  
  bucket = "${var.project_name}-media-${var.bucket_suffix}"

  tags = {
    Name = "${var.project_name}-media"
    Type = "Media"
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

# Elastic IP
resource "aws_eip" "main" {
  count = var.reuse_existing_resources && length(data.aws_eip.existing) > 0 ? 0 : 1
  
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-eip"
  }
}

# Instância EC2
resource "aws_instance" "django_server" {
  count = var.reuse_existing_resources && length(data.aws_instance.existing) > 0 ? 0 : 1
  
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = local.public_subnet_id

  vpc_security_group_ids = [local.ec2_sg_id]

  # User data script
  user_data = base64encode(templatefile("${path.module}/user_data_simple.sh", {
    domain_name   = var.domain_name
    db_endpoint   = local.rds_endpoint
    db_name       = var.db_name
    db_username   = var.db_username
    db_password   = var.db_password
    secret_key    = var.secret_key
    static_bucket = local.static_bucket
    media_bucket  = local.media_bucket
    aws_region    = var.aws_region
  }))

  # Configurações de monitoramento
  monitoring = var.detailed_monitoring

  # Configurações de armazenamento
  root_block_device {
    volume_type = var.root_volume_type
    volume_size = var.root_volume_size
    encrypted   = true
  }

  # Tags
  tags = {
    Name = "${var.project_name}-django-server"
  }

  # Lifecycle
  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      user_data,
      ami
    ]
  }
}

# Associar Elastic IP
resource "aws_eip_association" "django_eip" {
  count = var.reuse_existing_resources && length(data.aws_instance.existing) > 0 ? 0 : 1
  
  instance_id   = local.instance_id
  allocation_id = local.eip_id
}

# IAM Role para Enhanced Monitoring do RDS
resource "aws_iam_role" "rds_enhanced_monitoring" {
  count = var.monitoring_interval > 0 ? 1 : 0
  
  name = "${var.project_name}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-rds-monitoring-role"
  }
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  count = var.monitoring_interval > 0 ? 1 : 0
  
  role       = aws_iam_role.rds_enhanced_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# =============================================================================
# OUTPUTS
# =============================================================================

output "vpc_id" {
  description = "ID da VPC"
  value       = local.vpc_id
}

output "instance_id" {
  description = "ID da instância EC2"
  value       = local.instance_id
}

output "instance_public_ip" {
  description = "IP público da instância EC2"
  value       = local.eip_public_ip
}

output "instance_public_dns" {
  description = "DNS público da instância EC2"
  value       = var.reuse_existing_resources && length(data.aws_instance.existing) > 0 ? data.aws_instance.existing[0].public_dns : aws_instance.django_server[0].public_dns
}

output "rds_endpoint" {
  description = "Endpoint do RDS"
  value       = local.rds_endpoint
}

output "static_bucket" {
  description = "Nome do bucket S3 para arquivos estáticos"
  value       = local.static_bucket
}

output "media_bucket" {
  description = "Nome do bucket S3 para arquivos de mídia"
  value       = local.media_bucket
}

output "website_url" {
  description = "URL do website"
  value       = "http://${var.domain_name}"
}

output "admin_url" {
  description = "URL do painel administrativo"
  value       = "http://${var.domain_name}/admin/"
}

output "infrastructure_status" {
  description = "Status da infraestrutura"
  value = {
    vpc_created           = var.reuse_existing_resources && length(data.aws_vpc.existing) > 0 ? "reused" : "created"
    ec2_created           = var.reuse_existing_resources && length(data.aws_instance.existing) > 0 ? "reused" : "created"
    rds_created           = var.reuse_existing_resources && length(data.aws_db_instance.existing) > 0 ? "reused" : "created"
    s3_created            = var.reuse_existing_resources && length(data.aws_s3_bucket.existing_static) > 0 ? "reused" : "created"
    resources_reused      = var.reuse_existing_resources
  }
}