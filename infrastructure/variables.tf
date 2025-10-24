# =============================================================================
# VARIÁVEIS TERRAFORM - SISTEMA DE AGENDAMENTO
# =============================================================================

# =============================================================================
# CONFIGURAÇÕES BÁSICAS
# =============================================================================

variable "aws_region" {
  description = "Região AWS"
  type        = string
  default     = "us-east-1"
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.aws_region))
    error_message = "A região AWS deve conter apenas letras minúsculas, números e hífens."
  }
}

variable "project_name" {
  description = "Nome do projeto"
  type        = string
  default     = "s-agendamento"
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "O nome do projeto deve conter apenas letras minúsculas, números e hífens."
  }
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
  default     = "prod"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment deve ser dev, staging ou prod."
  }
}

variable "domain_name" {
  description = "Nome do domínio"
  type        = string
  default     = "fourmindstech.com.br"
}

# =============================================================================
# CONFIGURAÇÕES DE REUTILIZAÇÃO
# =============================================================================

variable "reuse_existing_resources" {
  description = "Se deve reutilizar recursos existentes ao invés de criar novos"
  type        = bool
  default     = true
}

variable "bucket_suffix" {
  description = "Sufixo para buckets S3 (para evitar conflitos)"
  type        = string
  default     = "exxyawpx"
}

# =============================================================================
# CONFIGURAÇÕES DE REDE
# =============================================================================

variable "vpc_cidr" {
  description = "CIDR da VPC"
  type        = string
  default     = "10.0.0.0/16"
  
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "O CIDR da VPC deve ser válido."
  }
}

variable "public_subnet_cidr" {
  description = "CIDR da subnet pública"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidrs" {
  description = "CIDRs das subnets privadas (Multi-AZ)"
  type        = list(string)
  default     = ["10.0.2.0/24", "10.0.3.0/24"]
  
  validation {
    condition     = length(var.private_subnet_cidrs) >= 2
    error_message = "Deve haver pelo menos 2 subnets privadas para RDS Multi-AZ."
  }
}

variable "allowed_ssh_cidrs" {
  description = "CIDRs permitidos para SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# =============================================================================
# CONFIGURAÇÕES EC2
# =============================================================================

variable "ami_id" {
  description = "ID da AMI (Ubuntu 22.04 LTS)"
  type        = string
  default     = "ami-0c398cb65a93047f2"
}

variable "instance_type" {
  description = "Tipo da instância EC2"
  type        = string
  default     = "t2.micro"
  
  validation {
    condition     = can(regex("^[a-z0-9]+\\.[a-z0-9]+$", var.instance_type))
    error_message = "O tipo da instância deve ser válido (ex: t2.micro)."
  }
}

variable "root_volume_type" {
  description = "Tipo do volume raiz"
  type        = string
  default     = "gp3"
  
  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2"], var.root_volume_type)
    error_message = "O tipo do volume deve ser gp2, gp3, io1 ou io2."
  }
}

variable "root_volume_size" {
  description = "Tamanho do volume raiz (GB)"
  type        = number
  default     = 20
  
  validation {
    condition     = var.root_volume_size >= 8 && var.root_volume_size <= 1000
    error_message = "O tamanho do volume deve estar entre 8 e 1000 GB."
  }
}

variable "detailed_monitoring" {
  description = "Se deve habilitar monitoramento detalhado da EC2"
  type        = bool
  default     = false
}

# =============================================================================
# CONFIGURAÇÕES RDS
# =============================================================================

variable "db_name" {
  description = "Nome do banco de dados"
  type        = string
  default     = "agendamento_db"
  
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]*$", var.db_name))
    error_message = "O nome do banco deve começar com letra e conter apenas letras, números e underscore."
  }
}

variable "db_username" {
  description = "Usuário do banco de dados"
  type        = string
  default     = "agendamento_user"
  
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]*$", var.db_username))
    error_message = "O nome do usuário deve começar com letra e conter apenas letras, números e underscore."
  }
}

variable "db_password" {
  description = "Senha do banco de dados"
  type        = string
  default     = "4MindsAgendamento2025!SecureDB#Pass"
  sensitive   = true
  
  validation {
    condition     = length(var.db_password) >= 8
    error_message = "A senha deve ter pelo menos 8 caracteres."
  }
}

variable "db_instance_class" {
  description = "Classe da instância RDS"
  type        = string
  default     = "db.t3.micro"
}

variable "db_engine_version" {
  description = "Versão do PostgreSQL"
  type        = string
  default     = "15.4"
}

variable "db_allocated_storage" {
  description = "Armazenamento alocado do RDS (GB)"
  type        = number
  default     = 20
  
  validation {
    condition     = var.db_allocated_storage >= 20 && var.db_allocated_storage <= 1000
    error_message = "O armazenamento deve estar entre 20 e 1000 GB."
  }
}

variable "db_max_allocated_storage" {
  description = "Armazenamento máximo alocado do RDS (GB)"
  type        = number
  default     = 100
  
  validation {
    condition     = var.db_max_allocated_storage >= 20
    error_message = "O armazenamento máximo deve ser pelo menos 20 GB."
  }
}

variable "db_storage_type" {
  description = "Tipo de armazenamento do RDS"
  type        = string
  default     = "gp2"
  
  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2"], var.db_storage_type)
    error_message = "O tipo de armazenamento deve ser gp2, gp3, io1 ou io2."
  }
}

variable "backup_retention_period" {
  description = "Período de retenção de backup do RDS (dias)"
  type        = number
  default     = 7
  
  validation {
    condition     = var.backup_retention_period >= 0 && var.backup_retention_period <= 35
    error_message = "O período de retenção deve estar entre 0 e 35 dias."
  }
}

variable "backup_window" {
  description = "Janela de backup do RDS (UTC)"
  type        = string
  default     = "03:00-04:00"
  
  validation {
    condition     = can(regex("^[0-2][0-9]:[0-5][0-9]-[0-2][0-9]:[0-5][0-9]$", var.backup_window))
    error_message = "A janela de backup deve estar no formato HH:MM-HH:MM."
  }
}

variable "maintenance_window" {
  description = "Janela de manutenção do RDS (UTC)"
  type        = string
  default     = "sun:04:00-sun:05:00"
  
  validation {
    condition     = can(regex("^(sun|mon|tue|wed|thu|fri|sat):[0-2][0-9]:[0-5][0-9]-(sun|mon|tue|wed|thu|fri|sat):[0-2][0-9]:[0-5][0-9]$", var.maintenance_window))
    error_message = "A janela de manutenção deve estar no formato day:HH:MM-day:HH:MM."
  }
}

variable "deletion_protection" {
  description = "Se deve habilitar proteção contra deleção do RDS"
  type        = bool
  default     = false
}

variable "performance_insights_enabled" {
  description = "Se deve habilitar Performance Insights"
  type        = bool
  default     = false
}

variable "monitoring_interval" {
  description = "Intervalo de monitoramento do RDS (0, 1, 5, 10, 15, 30, 60)"
  type        = number
  default     = 0
  
  validation {
    condition     = contains([0, 1, 5, 10, 15, 30, 60], var.monitoring_interval)
    error_message = "O intervalo de monitoramento deve ser 0, 1, 5, 10, 15, 30 ou 60."
  }
}

# =============================================================================
# CONFIGURAÇÕES DJANGO
# =============================================================================

variable "secret_key" {
  description = "Chave secreta do Django"
  type        = string
  default     = "django-insecure-4minds-agendamento-2025-super-secret-key"
  sensitive   = true
  
  validation {
    condition     = length(var.secret_key) >= 50
    error_message = "A chave secreta deve ter pelo menos 50 caracteres."
  }
}