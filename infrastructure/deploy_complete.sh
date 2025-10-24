#!/bin/bash

# ========================================
# Script de Deploy Completo - Sistema de Agendamento 4Minds
# ========================================
# Este script:
# 1. Coleta informações da infraestrutura AWS
# 2. Atualiza configurações do sistema
# 3. Realiza deploy da aplicação Django na EC2
# ========================================

set -e  # Parar em caso de erro

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para log
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar se estamos no diretório correto
if [ ! -f "main.tf" ]; then
    error "Execute este script no diretório infrastructure/"
    exit 1
fi

log "🚀 Iniciando deploy completo do Sistema de Agendamento 4Minds"

# ========================================
# 1. COLETAR INFORMAÇÕES DA INFRAESTRUTURA
# ========================================

log "📊 Coletando informações da infraestrutura AWS..."

# Verificar se o Terraform está inicializado
if [ ! -d ".terraform" ]; then
    log "Inicializando Terraform..."
    terraform init
fi

# Coletar outputs do Terraform
log "Coletando outputs do Terraform..."
terraform output -json > terraform_outputs.json

# Extrair informações importantes
INSTANCE_ID=$(terraform output -raw instance_id 2>/dev/null || echo "")
INSTANCE_IP=$(terraform output -raw instance_public_ip 2>/dev/null || echo "")
INSTANCE_DNS=$(terraform output -raw instance_public_dns 2>/dev/null || echo "")
RDS_ENDPOINT=$(terraform output -raw rds_endpoint 2>/dev/null || echo "")
STATIC_BUCKET=$(terraform output -raw static_bucket 2>/dev/null || echo "")
MEDIA_BUCKET=$(terraform output -raw media_bucket 2>/dev/null || echo "")
VPC_ID=$(terraform output -raw vpc_id 2>/dev/null || echo "")

# Verificar se as informações foram coletadas
if [ -z "$INSTANCE_ID" ] || [ -z "$INSTANCE_IP" ]; then
    error "Não foi possível coletar informações da infraestrutura. Verifique se o Terraform foi aplicado corretamente."
    exit 1
fi

success "Informações coletadas:"
echo "  - Instance ID: $INSTANCE_ID"
echo "  - IP Público: $INSTANCE_IP"
echo "  - DNS Público: $INSTANCE_DNS"
echo "  - RDS Endpoint: $RDS_ENDPOINT"
echo "  - Static Bucket: $STATIC_BUCKET"
echo "  - Media Bucket: $MEDIA_BUCKET"
echo "  - VPC ID: $VPC_ID"

# ========================================
# 2. ATUALIZAR CONFIGURAÇÕES DO SISTEMA
# ========================================

log "⚙️ Atualizando configurações do sistema..."

# Criar arquivo .env para produção
log "Criando arquivo .env para produção..."
cat > ../.env << EOF
# Configurações de Produção - Sistema de Agendamento 4Minds
# Gerado automaticamente em $(date)

# Django
DEBUG=False
SECRET_KEY=django-insecure-4minds-agendamento-2025-super-secret-key
ALLOWED_HOSTS=$INSTANCE_IP,$INSTANCE_DNS,fourmindstech.com.br,www.fourmindstech.com.br,api.fourmindstech.com.br,admin.fourmindstech.com.br

# Banco de Dados
DB_NAME=agendamento_db
DB_USER=agendamento_user
DB_PASSWORD=4MindsAgendamento2025!SecureDB#Pass
DB_HOST=$RDS_ENDPOINT
DB_PORT=5432

# AWS S3
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_STORAGE_BUCKET_NAME_STATIC=$STATIC_BUCKET
AWS_STORAGE_BUCKET_NAME_MEDIA=$MEDIA_BUCKET
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
EOF

# Atualizar settings de produção
log "Atualizando settings de produção..."
cat > ../core/settings_production.py << 'EOF'
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
EOF

success "Configurações atualizadas com sucesso!"

# ========================================
# 3. PREPARAR ARQUIVOS PARA DEPLOY
# ========================================

log "📦 Preparando arquivos para deploy..."

# Criar diretório de deploy
mkdir -p deploy_package

# Copiar arquivos necessários
log "Copiando arquivos do projeto..."
cp -r ../agendamentos deploy_package/
cp -r ../authentication deploy_package/
cp -r ../core deploy_package/
cp -r ../financeiro deploy_package/
cp -r ../info deploy_package/
cp -r ../templates deploy_package/
cp -r ../static deploy_package/ 2>/dev/null || true
cp ../manage.py deploy_package/
cp ../requirements.txt deploy_package/
cp ../.env deploy_package/

# Criar script de inicialização para a EC2
log "Criando script de inicialização para EC2..."
cat > deploy_package/init_django.sh << 'EOF'
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
EOF

chmod +x deploy_package/init_django.sh

# Criar arquivo de configuração do deploy
cat > deploy_package/deploy_config.json << EOF
{
    "instance_id": "$INSTANCE_ID",
    "instance_ip": "$INSTANCE_IP",
    "instance_dns": "$INSTANCE_DNS",
    "rds_endpoint": "$RDS_ENDPOINT",
    "static_bucket": "$STATIC_BUCKET",
    "media_bucket": "$MEDIA_BUCKET",
    "vpc_id": "$VPC_ID",
    "deploy_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

success "Arquivos preparados para deploy!"

# ========================================
# 4. REALIZAR DEPLOY NA EC2
# ========================================

log "🚀 Realizando deploy na instância EC2..."

# Verificar se a instância está rodando
log "Verificando status da instância..."
INSTANCE_STATE=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].State.Name' --output text 2>/dev/null || echo "unknown")

if [ "$INSTANCE_STATE" != "running" ]; then
    error "Instância não está rodando. Estado atual: $INSTANCE_STATE"
    exit 1
fi

# Aguardar a instância estar pronta
log "Aguardando instância estar pronta..."
aws ec2 wait instance-running --instance-ids $INSTANCE_ID

# Criar arquivo de chave temporário (se necessário)
if [ ! -f "s-agendamento-key.pem" ]; then
    warning "Chave SSH não encontrada. Você precisará configurar acesso SSH manualmente."
    echo "Para acessar a instância:"
    echo "  ssh -i s-agendamento-key.pem ubuntu@$INSTANCE_IP"
else
    chmod 600 s-agendamento-key.pem
fi

# Copiar arquivos para a instância
log "Copiando arquivos para a instância..."
if [ -f "s-agendamento-key.pem" ]; then
    # Usar SCP para copiar arquivos
    scp -i s-agendamento-key.pem -r deploy_package/* ubuntu@$INSTANCE_IP:/tmp/s-agendamento/
    
    # Executar script de inicialização
    log "Executando script de inicialização na instância..."
    ssh -i s-agendamento-key.pem ubuntu@$INSTANCE_IP "sudo bash /tmp/s-agendamento/init_django.sh"
    
    success "Deploy realizado com sucesso!"
    echo ""
    echo "🌐 URLs de Acesso:"
    echo "  - Website: http://$INSTANCE_IP"
    echo "  - Admin: http://$INSTANCE_IP/admin/"
    echo "  - API: http://$INSTANCE_IP/api/"
    echo ""
    echo "👤 Credenciais de Acesso:"
    echo "  - Usuário: admin"
    echo "  - Senha: admin123"
    echo ""
    echo "🔧 Comandos Úteis:"
    echo "  - SSH: ssh -i s-agendamento-key.pem ubuntu@$INSTANCE_IP"
    echo "  - Logs: sudo supervisorctl tail -f s-agendamento"
    echo "  - Restart: sudo supervisorctl restart s-agendamento"
else
    warning "Chave SSH não encontrada. Execute manualmente:"
    echo "1. Copie os arquivos: scp -r deploy_package/* ubuntu@$INSTANCE_IP:/tmp/s-agendamento/"
    echo "2. Execute o script: ssh ubuntu@$INSTANCE_IP 'sudo bash /tmp/s-agendamento/init_django.sh'"
fi

# ========================================
# 5. LIMPEZA E FINALIZAÇÃO
# ========================================

log "🧹 Limpando arquivos temporários..."
rm -rf deploy_package
rm -f terraform_outputs.json

success "Deploy completo finalizado!"
echo ""
echo "📊 Resumo da Infraestrutura:"
echo "  - Instance ID: $INSTANCE_ID"
echo "  - IP Público: $INSTANCE_IP"
echo "  - RDS Endpoint: $RDS_ENDPOINT"
echo "  - Static Bucket: $STATIC_BUCKET"
echo "  - Media Bucket: $MEDIA_BUCKET"
echo ""
echo "✅ Sistema de Agendamento 4Minds está online!"
