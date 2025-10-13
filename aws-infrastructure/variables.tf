variable "aws_region" {
  description = "Região AWS"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Sistema completo para agendamento de clientes com interface moderna, responsiva e sistema de temas personalizáveis."
  type        = string
  default     = "sistema-agendamento"
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "db_username" {
  description = "Usuário do banco de dados"
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "Senha do banco de dados"
  type        = string
  sensitive   = true
}

variable "domain_name" {
  description = "Domínio do site (ex: fourmindstech.com.br)"
  type        = string
  default     = "fourmindstech.com.br"
}

variable "instance_type" {
  description = "Tipo da instância EC2"
  type        = string
  default     = "t2.micro"
}

variable "db_instance_class" {
  description = "Classe da instância RDS - FREE TIER: db.t4g.micro (ARM)"
  type        = string
  default     = "db.t4g.micro"
}

variable "allocated_storage" {
  description = "Armazenamento alocado para RDS (GB)"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Armazenamento máximo para RDS (GB) - FREE TIER: keep at 20GB"
  type        = number
  default     = 20
}

variable "backup_retention_period" {
  description = "Período de retenção de backup (dias)"
  type        = number
  default     = 7
}

variable "multi_az" {
  description = "Habilitar Multi-AZ para RDS"
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "Proteção contra exclusão do RDS"
  type        = bool
  default     = false
}

variable "enable_cloudfront" {
  description = "Habilitar CloudFront CDN"
  type        = bool
  default     = false
}

variable "enable_waf" {
  description = "Habilitar WAF"
  type        = bool
  default     = false
}

variable "enable_ssl" {
  description = "Habilitar SSL/TLS"
  type        = bool
  default     = true
}

variable "ssl_certificate_arn" {
  description = "ARN do certificado SSL (se usar ACM)"
  type        = string
  default     = ""
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks permitidos para SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "tags" {
  description = "Tags adicionais para recursos"
  type        = map(string)
  default     = {}
}

variable "notification_email" {
  description = "Email para notificações de alerta"
  type        = string
  default     = ""
}

variable "log_retention_days" {
  description = "Dias de retenção de logs - FREE TIER: 7 days recommended"
  type        = number
  default     = 7
}

variable "enable_monitoring" {
  description = "Habilitar monitoramento detalhado"
  type        = bool
  default     = true
}

variable "cpu_threshold" {
  description = "Limite de CPU para alertas (%)"
  type        = number
  default     = 80
}

variable "memory_threshold" {
  description = "Limite de memória para alertas (%)"
  type        = number
  default     = 80
}

variable "disk_threshold" {
  description = "Limite de disco para alertas (%)"
  type        = number
  default     = 85
}
