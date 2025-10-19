# ========================================
# Configurações Terraform - EC2 Only
# Sistema de Agendamento - 4Minds
# ========================================

# Região AWS
aws_region = "us-east-1"

# Nome do projeto
project_name = "agendamento-4minds"

# Ambiente
environment = "prod"

# Domínio
domain_name = "fourmindstech.com.br"

# Tipo da instância EC2
instance_type = "t2.micro"  # FREE TIER: 750 horas/mês

# Tags
tags = {
  Environment = "production"
  Project     = "agendamento-4minds"
  Owner       = "4Minds"
  Domain      = "fourmindstech.com.br"
  FreeTier    = "true"
  ManagedBy   = "Terraform"
}
