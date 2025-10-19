#!/bin/bash

# Script de Deploy Automático do Django na EC2
# Execute este script na instância EC2

set -e  # Parar em caso de erro

echo "🚀 === DEPLOY AUTOMÁTICO DO DJANGO ==="
echo "📅 $(date)"
echo ""

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para log
log() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

# Verificar se está rodando como root
if [ "$EUID" -eq 0 ]; then
    error "Não execute como root! Use: sudo -u ubuntu bash deploy_automatico.sh"
    exit 1
fi

log "1. Navegando para o diretório do projeto..."
cd /home/ubuntu/s_agendamento
pwd

log "2. Verificando estrutura do projeto..."
if [ ! -f "manage.py" ]; then
    error "Arquivo manage.py não encontrado! Verifique se está no diretório correto."
    exit 1
fi
success "Projeto Django encontrado"

log "3. Criando arquivo .env com credenciais do RDS..."
cat > .env << 'EOF'
# Database (RDS PostgreSQL)
DB_ENGINE=django.db.backends.postgresql
DB_NAME=agendamentos_db
DB_USER=postgres
DB_PASSWORD=4MindsAgendamento2025!SecureDB#Pass
DB_HOST=agendamento-4minds-postgres.cgr24gyuwi3d.us-east-1.rds.amazonaws.com
DB_PORT=5432

# AWS S3
AWS_STORAGE_BUCKET_NAME=agendamento-4minds-static-abc123
AWS_S3_REGION_NAME=us-east-1
USE_S3=True

# CloudWatch Logs
CLOUDWATCH_LOG_GROUP=/aws/ec2/agendamento-4minds/django
AWS_REGION_NAME=us-east-1

# SNS Alerts
SNS_TOPIC_ARN=arn:aws:sns:us-east-1:295748148791:agendamento-4minds-alerts

# Django
DEBUG=False
ALLOWED_HOSTS=3.80.178.120,fourmindstech.com.br,localhost,127.0.0.1
SECRET_KEY=4MindsAgendamento2025!SecretKey#Django
EOF
success "Arquivo .env criado"

log "4. Instalando dependências Python..."
pip install --upgrade pip
pip install psycopg2-binary boto3 django-storages watchtower

# Verificar se requirements.txt existe
if [ -f "requirements.txt" ]; then
    pip install -r requirements.txt
    success "Dependências do requirements.txt instaladas"
else
    warning "Arquivo requirements.txt não encontrado"
fi

log "5. Configurando settings.py para produção..."
# Backup do settings original
cp core/settings.py core/settings.py.backup

# Adicionar configurações de produção
cat >> core/settings.py << 'EOF'

# Configurações de produção
import os

# Database
DATABASES = {
    'default': {
        'ENGINE': os.getenv('DB_ENGINE', 'django.db.backends.sqlite3'),
        'NAME': os.getenv('DB_NAME', 'db.sqlite3'),
        'USER': os.getenv('DB_USER', ''),
        'PASSWORD': os.getenv('DB_PASSWORD', ''),
        'HOST': os.getenv('DB_HOST', 'localhost'),
        'PORT': os.getenv('DB_PORT', '5432'),
    }
}

# AWS S3 para arquivos estáticos
if os.getenv('USE_S3', 'False').lower() == 'true':
    AWS_STORAGE_BUCKET_NAME = os.getenv('AWS_STORAGE_BUCKET_NAME')
    AWS_S3_REGION_NAME = os.getenv('AWS_S3_REGION_NAME')
    AWS_S3_CUSTOM_DOMAIN = f'{AWS_STORAGE_BUCKET_NAME}.s3.amazonaws.com'
    
    # Configurações de armazenamento
    STATICFILES_STORAGE = 'storages.backends.s3boto3.S3Boto3Storage'
    DEFAULT_FILE_STORAGE = 'storages.backends.s3boto3.S3Boto3Storage'
    
    # URLs estáticas
    STATIC_URL = f'https://{AWS_S3_CUSTOM_DOMAIN}/static/'
    MEDIA_URL = f'https://{AWS_S3_CUSTOM_DOMAIN}/media/'

# CloudWatch Logs
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'handlers': {
        'cloudwatch': {
            'level': 'INFO',
            'class': 'watchtower.CloudWatchLogsHandler',
            'log_group': os.getenv('CLOUDWATCH_LOG_GROUP', '/aws/ec2/agendamento-4minds/django'),
            'stream_name': 'django-app',
        },
    },
    'loggers': {
        'django': {
            'handlers': ['cloudwatch'],
            'level': 'INFO',
            'propagate': True,
        },
    },
}
EOF
success "Settings.py configurado para produção"

log "6. Testando conexão com o banco de dados..."
python manage.py check --database default
success "Conexão com RDS testada com sucesso"

log "7. Executando migrações do banco de dados..."
python manage.py migrate
success "Migrações executadas"

log "8. Criando superusuário..."
echo "from django.contrib.auth import get_user_model; User = get_user_model(); User.objects.create_superuser('admin', 'admin@4minds.com.br', 'admin123')" | python manage.py shell
success "Superusuário criado (admin/admin123)"

log "9. Coletando arquivos estáticos..."
python manage.py collectstatic --noinput
success "Arquivos estáticos coletados"

log "10. Configurando Gunicorn..."
sudo tee /etc/systemd/system/gunicorn.service > /dev/null << 'EOF'
[Unit]
Description=Gunicorn daemon for Django
After=network.target

[Service]
User=ubuntu
Group=www-data
WorkingDirectory=/home/ubuntu/s_agendamento
ExecStart=/usr/bin/python3 -m gunicorn --bind unix:/home/ubuntu/s_agendamento/gunicorn.sock core.wsgi:application
ExecReload=/bin/kill -s HUP $MAINPID
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
success "Gunicorn configurado"

log "11. Configurando Nginx..."
sudo tee /etc/nginx/sites-available/agendamento-4minds > /dev/null << 'EOF'
server {
    listen 80;
    server_name 3.80.178.120 fourmindstech.com.br;

    location = /favicon.ico { access_log off; log_not_found off; }
    
    location /static/ {
        root /home/ubuntu/s_agendamento;
    }
    
    location /media/ {
        root /home/ubuntu/s_agendamento;
    }

    location / {
        include proxy_params;
        proxy_pass http://unix:/home/ubuntu/s_agendamento/gunicorn.sock;
    }
}
EOF

# Ativar site
sudo ln -sf /etc/nginx/sites-available/agendamento-4minds /etc/nginx/sites-enabled
sudo rm -f /etc/nginx/sites-enabled/default
success "Nginx configurado"

log "12. Testando configuração do Nginx..."
sudo nginx -t
success "Configuração do Nginx válida"

log "13. Configurando permissões..."
sudo chown -R ubuntu:www-data /home/ubuntu/s_agendamento
sudo chmod -R 755 /home/ubuntu/s_agendamento
success "Permissões configuradas"

log "14. Reiniciando serviços..."
sudo systemctl daemon-reload
sudo systemctl restart gunicorn
sudo systemctl restart nginx
sudo systemctl enable gunicorn
sudo systemctl enable nginx
success "Serviços reiniciados e habilitados"

log "15. Verificando status dos serviços..."
echo "Status do Gunicorn:"
sudo systemctl is-active gunicorn
echo "Status do Nginx:"
sudo systemctl is-active nginx

log "16. Testando aplicação..."
sleep 5
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/ | grep -q "200\|301\|302"; then
    success "Aplicação respondendo corretamente"
else
    warning "Aplicação pode não estar respondendo corretamente"
fi

echo ""
echo "🎉 =================================="
echo "✅ DEPLOY CONCLUÍDO COM SUCESSO!"
echo "=================================="
echo ""
echo "🌐 URLs de Acesso:"
echo "   • Aplicação: http://3.80.178.120"
echo "   • Admin: http://3.80.178.120/admin"
echo ""
echo "👤 Credenciais do Admin:"
echo "   • Usuário: admin"
echo "   • Senha: admin123"
echo ""
echo "🔧 Comandos Úteis:"
echo "   • Ver logs: sudo journalctl -u gunicorn -f"
echo "   • Reiniciar: sudo systemctl restart gunicorn nginx"
echo "   • Status: sudo systemctl status gunicorn nginx"
echo ""
echo "📊 Recursos AWS Utilizados:"
echo "   • EC2: i-029805f836fb2f238 (3.80.178.120)"
echo "   • RDS: agendamento-4minds-postgres"
echo "   • S3: agendamento-4minds-static-abc123"
echo "   • SNS: agendamento-4minds-alerts"
echo "   • CloudWatch: /aws/ec2/agendamento-4minds/django"
echo ""
echo "✨ Deploy finalizado em $(date)"
