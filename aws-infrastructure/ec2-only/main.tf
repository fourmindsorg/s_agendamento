# ========================================
# AWS EC2 Instance - Sistema de Agendamento
# Configuração Simplificada - Apenas EC2
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
    Name = "agendamento-4minds-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "agendamento-4minds-igw"
  }
}

# Subnet Pública
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "agendamento-4minds-public-subnet"
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
    Name = "agendamento-4minds-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Key Pair
resource "aws_key_pair" "deployer" {
  key_name   = "agendamento-4minds-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC9EDcKpFmkNctpBieANBmV3kq6mxd/u8xkKoC+h4dF5wcF/X5IatBNSYyl5KwkZymaXC4De+qcxGnwCoP6MtLEz2Js9hyjpT//sK8Lk+4+uU+RiwApXEAa0RzzpEQFXTxVu//tDyAmslvfOxSHf37wa93TRejB/hb8XZpNHkiOCaP13yEZxd2eZaDGpvHG6BMVBLTXfdhOx4ORCeuXvWQdML5uePOnonWFePc0lr9HrsImep3dJprl+6cpqczhU2OkF9AScIUB+1ZYJaCVbLGWJEenhoPT+Mfwbt8dVWBT73vcQWrZihznfIpPdZJqCuCy6oCCi1TNjrCiF+zmLRAw1yEeTjdP4ec2IYIR+2RS/V8Nnzz2sNObwMLx/5ASlqI+rTN3ko9vTDEAxE++TBDD3lo2D7wq8n6nJ0U2woE8o9qlEj+clvpb4RcCimvB6gaA3BDI/3PBd1VQu2aPI10lucJ85SPcMvV4HOahidvp1AHfM96d93Qm0mN2qDyykA6XSsws22j8bw5azGsrFDo62erIcUCkGSGreefE/k3bQnthfvJFEu6HWOaUC0pKamYEEInoBMVpq5jjfoRMzx9SfcZATmzwmpTFp3GMD/FEDlUzTFFxe/4HOzAI+y6HVmY4CcAVsF3JO+bQmpUdzHPWDa+hYjJ9qZhwLZQ73X2rDQ== carlos alberto@TheMachine"
}

# Security Group para EC2
resource "aws_security_group" "ec2_sg" {
  name_prefix = "agendamento-4minds-ec2-"
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
    Name = "agendamento-4minds-ec2-sg"
  }
}

# Instância EC2
resource "aws_instance" "web_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  subnet_id              = aws_subnet.public.id

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 30
    delete_on_termination = true
    encrypted             = false
  }

  monitoring = false

  user_data = templatefile("${path.module}/user_data.sh", {
    project_name = "agendamento-4minds"
    domain_name  = "fourmindstech.com.br"
  })

  tags = {
    Name        = "agendamento-4minds-web-server"
    Environment = "prod"
    FreeTier    = "true"
  }
}

# Outputs
output "vpc_id" {
  description = "ID da VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID da subnet pública"
  value       = aws_subnet.public.id
}

output "ec2_public_ip" {
  description = "IP público da instância EC2"
  value       = aws_instance.web_server.public_ip
}

output "ec2_private_ip" {
  description = "IP privado da instância EC2"
  value       = aws_instance.web_server.private_ip
}

output "ec2_instance_id" {
  description = "ID da instância EC2"
  value       = aws_instance.web_server.id
}

output "security_group_ec2_id" {
  description = "ID do security group da EC2"
  value       = aws_security_group.ec2_sg.id
}

output "application_url" {
  description = "URL da aplicação"
  value       = "https://fourmindstech.com.br"
}

output "ssh_command" {
  description = "Comando SSH para conectar na instância"
  value       = "ssh -i ~/.ssh/id_rsa ubuntu@${aws_instance.web_server.public_ip}"
}
