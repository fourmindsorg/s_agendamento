# Variáveis simplificadas para s-agendamento

variable "aws_region" {
  description = "Região AWS"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nome do projeto"
  type        = string
  default     = "s-agendamento"
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
  default     = "prod"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "O ambiente deve ser dev, staging ou prod."
  }
}

variable "domain_name" {
  description = "Nome do domínio"
  type        = string
  default     = "fourmindstech.com.br"
}

# Configurações de rede
variable "vpc_cidr" {
  description = "CIDR da VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR da subnet pública"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_1_cidr" {
  description = "CIDR da primeira subnet privada"
  type        = string
  default     = "10.0.2.0/24"
}

variable "private_subnet_2_cidr" {
  description = "CIDR da segunda subnet privada"
  type        = string
  default     = "10.0.3.0/24"
}

# Configurações EC2
variable "instance_type" {
  description = "Tipo da instância EC2"
  type        = string
  default     = "t2.micro"
}

variable "ami_id" {
  description = "ID da AMI"
  type        = string
  default     = "ami-0c398cb65a93047f2" # Ubuntu 22.04 LTS
}

variable "key_pair_name" {
  description = "Nome do par de chaves"
  type        = string
  default     = "s-agendamento-key"
}

# Configurações RDS
variable "db_name" {
  description = "Nome do banco de dados"
  type        = string
  default     = "agendamento_db"
}

variable "db_username" {
  description = "Usuário do banco de dados"
  type        = string
  default     = "agendamento_user"
}

variable "db_password" {
  description = "Senha do banco de dados"
  type        = string
  sensitive   = true
  default     = "4MindsAgendamento2025!SecureDB#Pass"
}

variable "db_instance_class" {
  description = "Classe da instância RDS"
  type        = string
  default     = "db.t3.micro"
}

variable "db_engine_version" {
  description = "Versão do PostgreSQL"
  type        = string
  default     = "17.4"
}

variable "db_allocated_storage" {
  description = "Armazenamento alocado do RDS (GB)"
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "Armazenamento máximo alocado do RDS (GB)"
  type        = number
  default     = 100
}

variable "db_storage_type" {
  description = "Tipo de armazenamento do RDS"
  type        = string
  default     = "gp2"
}

variable "backup_retention_period" {
  description = "Período de retenção de backup (dias)"
  type        = number
  default     = 7
}

variable "backup_window" {
  description = "Janela de backup"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Janela de manutenção"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

# Configurações S3
variable "bucket_suffix" {
  description = "Sufixo para os buckets S3"
  type        = string
  default     = "exxyawpx"
}

# Configurações Django
variable "secret_key" {
  description = "Chave secreta do Django"
  type        = string
  sensitive   = true
  default     = "django-insecure-4minds-agendamento-2025-super-secret-key"
}
