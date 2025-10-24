# ========================================
# Script de Deploy Completo - Sistema de Agendamento 4Minds (PowerShell)
# ========================================
# Este script:
# 1. Coleta informações da infraestrutura AWS
# 2. Atualiza configurações do sistema
# 3. Realiza deploy da aplicação Django na EC2
# ========================================

param(
    [string]$InstanceId = "",
    [string]$KeyPath = "s-agendamento-key.pem",
    [switch]$SkipDeploy = $false
)

# Configurações
$ErrorActionPreference = "Stop"

# Função para log
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        default { "Cyan" }
    }
    Write-Host "[$timestamp] $Message" -ForegroundColor $color
}

# Verificar se estamos no diretório correto
if (-not (Test-Path "main.tf")) {
    Write-Log "Execute este script no diretório infrastructure/" "ERROR"
    exit 1
}

Write-Log "🚀 Iniciando deploy completo do Sistema de Agendamento 4Minds"

# ========================================
# 1. COLETAR INFORMAÇÕES DA INFRAESTRUTURA
# ========================================

Write-Log "📊 Coletando informações da infraestrutura AWS..."

# Verificar se o Terraform está inicializado
if (-not (Test-Path ".terraform")) {
    Write-Log "Inicializando Terraform..."
    terraform init
}

# Coletar outputs do Terraform
Write-Log "Coletando outputs do Terraform..."
terraform output -json | Out-File -FilePath "terraform_outputs.json" -Encoding UTF8

# Extrair informações importantes
$terraformOutput = terraform output -json | ConvertFrom-Json

$InstanceId = if ($InstanceId) { $InstanceId } else { $terraformOutput.instance_id.value }
$InstanceIp = $terraformOutput.instance_public_ip.value
$InstanceDns = $terraformOutput.instance_public_dns.value
$RdsEndpoint = $terraformOutput.rds_endpoint.value
$StaticBucket = $terraformOutput.static_bucket.value
$MediaBucket = $terraformOutput.media_bucket.value
$VpcId = $terraformOutput.vpc_id.value

# Verificar se as informações foram coletadas
if (-not $InstanceId -or -not $InstanceIp) {
    Write-Log "Não foi possível coletar informações da infraestrutura. Verifique se o Terraform foi aplicado corretamente." "ERROR"
    exit 1
}

Write-Log "Informações coletadas:" "SUCCESS"
Write-Host "  - Instance ID: $InstanceId"
Write-Host "  - IP Público: $InstanceIp"
Write-Host "  - DNS Público: $InstanceDns"
Write-Host "  - RDS Endpoint: $RdsEndpoint"
Write-Host "  - Static Bucket: $StaticBucket"
Write-Host "  - Media Bucket: $MediaBucket"
Write-Host "  - VPC ID: $VpcId"

# ========================================
# 2. ATUALIZAR CONFIGURAÇÕES DO SISTEMA
# ========================================

Write-Log "⚙️ Atualizando configurações do sistema..."

# Criar arquivo .env para produção
Write-Log "Criando arquivo .env para produção..."
$envContent = @"
# Configurações de Produção - Sistema de Agendamento 4Minds
# Gerado automaticamente em $(Get-Date)

# Django
DEBUG=False
SECRET_KEY=django-insecure-4minds-agendamento-2025-super-secret-key
ALLOWED_HOSTS=$InstanceIp,$InstanceDns,fourmindstech.com.br,www.fourmindstech.com.br,api.fourmindstech.com.br,admin.fourmindstech.com.br

# Banco de Dados
DB_NAME=agendamento_db
DB_USER=agendamento_user
DB_PASSWORD=4MindsAgendamento2025!SecureDB#Pass
DB_HOST=$RdsEndpoint
DB_PORT=5432

# AWS S3
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_STORAGE_BUCKET_NAME_STATIC=$StaticBucket
AWS_STORAGE_BUCKET_NAME_MEDIA=$MediaBucket
AWS_S3_REGION_NAME=us-east-1

# Email (configurar conforme necessário)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=
SMTP_PASSWORD=
DEFAULT_FROM_EMAIL=Sistema de Agendamentos <noreply@fourmindstech.com.br>

# HTTPS
HTTPS_REDIRECT=False

# Asaas (desabilitado - serviço pago)
ASAAS_API_KEY=
ASAAS_ENV=sandbox
ASAAS_WEBHOOK_TOKEN=
"@

$envContent | Out-File -FilePath "../.env" -Encoding UTF8

# Atualizar settings de produção
Write-Log "Atualizando settings de produção..."
$settingsContent = @'
import os
from pathlib import Path
from .settings import *

# Carregar variáveis de ambiente do arquivo .env
try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = os.environ.get(
    "SECRET_KEY", "django-insecure-4minds-agendamento-2025-super-secret-key"
)

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = os.environ.get("DEBUG", "False").lower() == "true"

# Hosts permitidos para produção
ALLOWED_HOSTS = [
    "localhost",
    "127.0.0.1",
    "0.0.0.0",
]

# Adicionar hosts da variável de ambiente
env_hosts = os.environ.get("ALLOWED_HOSTS", "")
if env_hosts:
    ALLOWED_HOSTS.extend(
        [host.strip() for host in env_hosts.split(",") if host.strip()]
    )

# Database - PostgreSQL para produção
DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": os.environ.get("DB_NAME", "agendamento_db"),
        "USER": os.environ.get("DB_USER", "agendamento_user"),
        "PASSWORD": os.environ.get("DB_PASSWORD", ""),
        "HOST": os.environ.get("DB_HOST", "localhost"),
        "PORT": os.environ.get("DB_PORT", "5432"),
    }
}

# Static files (CSS, JavaScript, Images)
STATIC_URL = "/static/"
STATIC_ROOT = os.path.join(BASE_DIR, "staticfiles")

# Verificar se o diretório static existe antes de adicionar
static_dir = os.path.join(BASE_DIR, "static")
if os.path.exists(static_dir):
    STATICFILES_DIRS = [static_dir]
else:
    STATICFILES_DIRS = []

# Media files
MEDIA_URL = "/media/"
MEDIA_ROOT = os.path.join(BASE_DIR, "media")

# Security settings para produção
SECURE_BROWSER_XSS_FILTER = True
SECURE_CONTENT_TYPE_NOSNIFF = True
X_FRAME_OPTIONS = "DENY"
SECURE_HSTS_SECONDS = 31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True

# HTTPS settings
SECURE_SSL_REDIRECT = os.environ.get("HTTPS_REDIRECT", "False").lower() == "true"
SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")

# Session settings
SESSION_COOKIE_SECURE = os.environ.get("HTTPS_REDIRECT", "False").lower() == "true"
CSRF_COOKIE_SECURE = os.environ.get("HTTPS_REDIRECT", "False").lower() == "true"

# CSRF Trusted Origins - Necessário para forms POST funcionarem
CSRF_TRUSTED_ORIGINS = [
    "https://fourmindstech.com.br",
    "https://www.fourmindstech.com.br",
    "http://fourmindstech.com.br",  # Temporário durante transição HTTP->HTTPS
]

# Email settings
EMAIL_BACKEND = "django.core.mail.backends.smtp.EmailBackend"
EMAIL_HOST = os.environ.get("SMTP_HOST", "smtp.gmail.com")
EMAIL_PORT = int(os.environ.get("SMTP_PORT", "587"))
EMAIL_USE_TLS = True
EMAIL_HOST_USER = os.environ.get("SMTP_USER", "")
EMAIL_HOST_PASSWORD = os.environ.get("SMTP_PASSWORD", "")
DEFAULT_FROM_EMAIL = os.environ.get(
    "DEFAULT_FROM_EMAIL", "Sistema de Agendamentos <noreply@fourmindstech.com.br>"
)

# Logging
LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "handlers": {
        "console": {
            "class": "logging.StreamHandler",
        },
    },
    "root": {
        "handlers": ["console"],
        "level": "INFO",
    },
    "loggers": {
        "django": {
            "handlers": ["console"],
            "level": "INFO",
            "propagate": False,
        },
    },
}

# Cache (usar memória para instância única)
CACHES = {
    "default": {
        "BACKEND": "django.core.cache.backends.locmem.LocMemCache",
        "LOCATION": "unique-snowflake",
    }
}

# WhiteNoise para arquivos estáticos (se disponível)
try:
    import whitenoise
    MIDDLEWARE.insert(1, "whitenoise.middleware.WhiteNoiseMiddleware")
    STATICFILES_STORAGE = "whitenoise.storage.StaticFilesStorage"
except ImportError:
    STATICFILES_STORAGE = "django.contrib.staticfiles.storage.StaticFilesStorage"

# Configuração adicional para servir arquivos estáticos
STATICFILES_FINDERS = [
    "django.contrib.staticfiles.finders.FileSystemFinder",
    "django.contrib.staticfiles.finders.AppDirectoriesFinder",
]

# Asaas (desabilitado - serviço pago)
ASAAS_API_KEY = os.environ.get("ASAAS_API_KEY", "")
ASAAS_ENV = os.environ.get("ASAAS_ENV", "sandbox")
ASAAS_WEBHOOK_TOKEN = os.environ.get("ASAAS_WEBHOOK_TOKEN", "")
'@

$settingsContent | Out-File -FilePath "../core/settings_production.py" -Encoding UTF8

Write-Log "Configurações atualizadas com sucesso!" "SUCCESS"

# ========================================
# 3. PREPARAR ARQUIVOS PARA DEPLOY
# ========================================

Write-Log "📦 Preparando arquivos para deploy..."

# Criar diretório de deploy
if (Test-Path "deploy_package") {
    Remove-Item -Recurse -Force "deploy_package"
}
New-Item -ItemType Directory -Path "deploy_package" | Out-Null

# Copiar arquivos necessários
Write-Log "Copiando arquivos do projeto..."
Copy-Item -Recurse "../agendamentos" "deploy_package/"
Copy-Item -Recurse "../authentication" "deploy_package/"
Copy-Item -Recurse "../core" "deploy_package/"
Copy-Item -Recurse "../financeiro" "deploy_package/"
Copy-Item -Recurse "../info" "deploy_package/"
Copy-Item -Recurse "../templates" "deploy_package/"
if (Test-Path "../static") {
    Copy-Item -Recurse "../static" "deploy_package/"
}
Copy-Item "../manage.py" "deploy_package/"
Copy-Item "../requirements.txt" "deploy_package/"
Copy-Item "../.env" "deploy_package/"

# Criar script de inicialização para a EC2
Write-Log "Criando script de inicialização para EC2..."
$initScript = @'
#!/bin/bash

# Script de inicialização do Django na EC2
set -e

# Atualizar sistema
sudo apt-get update -y
sudo apt-get upgrade -y

# Instalar dependências do sistema
sudo apt-get install -y python3 python3-pip python3-venv postgresql-client nginx supervisor

# Criar usuário para a aplicação
sudo useradd -m -s /bin/bash django
sudo usermod -aG sudo django

# Criar diretório da aplicação
sudo mkdir -p /opt/s-agendamento
sudo chown django:django /opt/s-agendamento

# Copiar arquivos da aplicação
sudo cp -r /tmp/s-agendamento/* /opt/s-agendamento/
sudo chown -R django:django /opt/s-agendamento

# Instalar dependências Python
cd /opt/s-agendamento
sudo -u django python3 -m venv venv
sudo -u django /opt/s-agendamento/venv/bin/pip install --upgrade pip
sudo -u django /opt/s-agendamento/venv/bin/pip install -r requirements.txt

# Executar migrações
sudo -u django /opt/s-agendamento/venv/bin/python manage.py migrate

# Coletar arquivos estáticos
sudo -u django /opt/s-agendamento/venv/bin/python manage.py collectstatic --noinput

# Criar superusuário (se não existir)
sudo -u django /opt/s-agendamento/venv/bin/python manage.py shell -c "
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser('admin', 'admin@fourmindstech.com.br', 'admin123')
    print('Superusuário criado: admin/admin123')
else:
    print('Superusuário já existe')
"

# Configurar Nginx
sudo tee /etc/nginx/sites-available/s-agendamento << 'NGINX_EOF'
server {
    listen 80;
    server_name _;

    location /static/ {
        alias /opt/s-agendamento/staticfiles/;
    }

    location /media/ {
        alias /opt/s-agendamento/media/;
    }

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
NGINX_EOF

# Ativar site do Nginx
sudo ln -sf /etc/nginx/sites-available/s-agendamento /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx
sudo systemctl enable nginx

# Configurar Supervisor
sudo tee /etc/supervisor/conf.d/s-agendamento.conf << 'SUPERVISOR_EOF'
[program:s-agendamento]
command=/opt/s-agendamento/venv/bin/gunicorn --bind 127.0.0.1:8000 core.wsgi:application
directory=/opt/s-agendamento
user=django
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/var/log/supervisor/s-agendamento.log
SUPERVISOR_EOF

# Reiniciar Supervisor
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start s-agendamento

echo "✅ Django deployado com sucesso!"
echo "🌐 Acesse: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
echo "👤 Admin: admin/admin123"
'@

$initScript | Out-File -FilePath "deploy_package/init_django.sh" -Encoding UTF8

# Criar arquivo de configuração do deploy
$deployConfig = @{
    instance_id = $InstanceId
    instance_ip = $InstanceIp
    instance_dns = $InstanceDns
    rds_endpoint = $RdsEndpoint
    static_bucket = $StaticBucket
    media_bucket = $MediaBucket
    vpc_id = $VpcId
    deploy_timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
} | ConvertTo-Json -Depth 10

$deployConfig | Out-File -FilePath "deploy_package/deploy_config.json" -Encoding UTF8

Write-Log "Arquivos preparados para deploy!" "SUCCESS"

# ========================================
# 4. REALIZAR DEPLOY NA EC2 (OPCIONAL)
# ========================================

if (-not $SkipDeploy) {
    Write-Log "🚀 Realizando deploy na instância EC2..."

    # Verificar se a instância está rodando
    Write-Log "Verificando status da instância..."
    try {
        $instanceState = aws ec2 describe-instances --instance-ids $InstanceId --query 'Reservations[0].Instances[0].State.Name' --output text
        if ($instanceState -ne "running") {
            Write-Log "Instância não está rodando. Estado atual: $instanceState" "ERROR"
            exit 1
        }
    }
    catch {
        Write-Log "Erro ao verificar status da instância: $($_.Exception.Message)" "WARNING"
    }

    # Verificar se a chave SSH existe
    if (-not (Test-Path $KeyPath)) {
        Write-Log "Chave SSH não encontrada em: $KeyPath" "WARNING"
        Write-Log "Para realizar o deploy manualmente:" "WARNING"
        Write-Host "1. Copie os arquivos: scp -r deploy_package/* ubuntu@$InstanceIp:/tmp/s-agendamento/"
        Write-Host "2. Execute o script: ssh ubuntu@$InstanceIp 'sudo bash /tmp/s-agendamento/init_django.sh'"
    }
    else {
        Write-Log "Chave SSH encontrada. Iniciando deploy..."
        Write-Log "Para realizar o deploy, execute os comandos manualmente:" "WARNING"
        Write-Host "scp -i $KeyPath -r deploy_package/* ubuntu@$InstanceIp:/tmp/s-agendamento/"
        Write-Host "ssh -i $KeyPath ubuntu@$InstanceIp 'sudo bash /tmp/s-agendamento/init_django.sh'"
    }
}

# ========================================
# 5. FINALIZAÇÃO
# ========================================

Write-Log "🧹 Deploy preparado com sucesso!" "SUCCESS"
Write-Host ""
Write-Host "📊 Resumo da Infraestrutura:"
Write-Host "  - Instance ID: $InstanceId"
Write-Host "  - IP Público: $InstanceIp"
Write-Host "  - RDS Endpoint: $RdsEndpoint"
Write-Host "  - Static Bucket: $StaticBucket"
Write-Host "  - Media Bucket: $MediaBucket"
Write-Host ""
Write-Host "🌐 URLs de Acesso (após deploy):"
Write-Host "  - Website: http://$InstanceIp"
Write-Host "  - Admin: http://$InstanceIp/admin/"
Write-Host "  - API: http://$InstanceIp/api/"
Write-Host ""
Write-Host "👤 Credenciais de Acesso:"
Write-Host "  - Usuário: admin"
Write-Host "  - Senha: admin123"
Write-Host ""
Write-Host "✅ Sistema de Agendamento 4Minds está pronto para deploy!"
