# Variáveis para configuração simplificada
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
    error_message = "Environment deve ser dev, staging ou prod."
  }
}

variable "domain_name" {
  description = "Nome do domínio"
  type        = string
  default     = "fourmindstech.com.br"
}

variable "instance_type" {
  description = "Tipo da instância EC2"
  type        = string
  default     = "t2.micro"
}

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
  default     = "4MindsAgendamento2025!SecureDB#Pass"
  sensitive   = true
}

variable "secret_key" {
  description = "Chave secreta do Django"
  type        = string
  default     = "django-insecure-4minds-agendamento-2025-super-secret-key"
  sensitive   = true
}
