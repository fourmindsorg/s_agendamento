# ========================================
# Configurações Terraform - AWS Free Tier
# Sistema de Agendamento - 4Minds
# ========================================
# ⚠️ ESTE ARQUIVO CONTÉM INFORMAÇÕES SENSÍVEIS
# ⚠️ NÃO COMMITAR NO GIT

# Região AWS
aws_region = "us-east-1"

# Nome do projeto
project_name = "agendamento-4minds"

# Ambiente
environment = "prod"

# ========================================
# BANCO DE DADOS RDS - FREE TIER
# ========================================

db_username = "postgres"

# ⚠️ IMPORTANTE: Altere esta senha para uma senha FORTE
# Requisitos: 16+ caracteres, números, letras maiúsculas/minúsculas, símbolos
db_password = "4MindsAgendamento2025!SecureDB#Pass"

# ========================================
# INSTÂNCIAS - FREE TIER
# ========================================

# EC2
instance_type = "t2.micro"  # FREE TIER: 750 horas/mês

# RDS - FREE TIER (ARM)
db_instance_class = "db.t4g.micro"  # ✅ FREE TIER: 750 horas/mês (ARM-based, moderno)

# Storage RDS - FREE TIER
allocated_storage = 20             # ✅ FREE TIER: até 20GB
max_allocated_storage = 20         # ✅ Limitado a 20GB para Free Tier

# ========================================
# BACKUP E DISPONIBILIDADE
# ========================================

backup_retention_period = 7        # FREE TIER: até 7 dias
multi_az = false                   # Single-AZ para Free Tier
deletion_protection = false

# ========================================
# DOMÍNIO
# ========================================

domain_name = "fourmindstech.com.br"

# ========================================
# MONITORAMENTO - FREE TIER
# ========================================

enable_monitoring = true
cpu_threshold = 80
memory_threshold = 80
disk_threshold = 85

# Email para alertas
notification_email = "fourmindsorg@gmail.com"

# ========================================
# SEGURANÇA
# ========================================

enable_ssl = true
enable_waf = false          # WAF não está no Free Tier
enable_cloudfront = false   # CloudFront tem Free Tier limitado

# ========================================
# TAGS
# ========================================

tags = {
  Environment = "production"
  Project     = "agendamento-4minds"
  Owner       = "4Minds"
  Domain      = "fourmindstech.com.br"
  FreeTier    = "true"
  ManagedBy   = "Terraform"
}

# ========================================
# RESUMO FREE TIER UTILIZADO
# ========================================
# - EC2 t2.micro: 750h/mês (1 instância 24/7 = OK)
# - RDS db.t2.micro: 750h/mês (1 instância 24/7 = OK)
# - EBS: 30GB (EC2) + 20GB (RDS) = 50GB total (limite: 30GB free)
# - S3: ~1-2GB (limite: 5GB free)
# - Data Transfer: ~5GB/mês (limite: 15GB free)
# - CloudWatch: 5 alarmes (limite: 10 free)
# - SNS: ~50 emails/mês (limite: 1,000 free)
#
# CUSTO ESTIMADO: $0/mês nos primeiros 12 meses
# ========================================
