#!/bin/bash
# ========================================
# Script de Inicialização EC2
# Sistema de Agendamento - 4Minds
# ========================================
# Este script é executado automaticamente na primeira inicialização da instância EC2
# Configura: Python, Django, Nginx, Gunicorn, PostgreSQL client, SSL (Let's Encrypt)

set -e  # Sair em caso de erro
set -x  # Mostrar comandos executados (para debug)

# ========================================
# VARIÁVEIS (Substituídas pelo Terraform)
# ========================================
DB_HOST="${db_address}"
DB_PORT="${db_port}"
DB_NAME="${db_name}"
DB_USER="${db_username}"
DB_PASSWORD="${db_password}"
PROJECT_NAME="${project_name}"
DOMAIN_NAME="${domain_name}"

# ========================================
# CONFIGURAÇÃO DE LOGS
# ========================================
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "========================================="
echo "Iniciando configuração do servidor EC2"
echo "Data: $(date)"
echo "Domínio: $DOMAIN_NAME"
echo "========================================="

# ========================================
# ATUALIZAR SISTEMA
# ========================================
echo "[1/15] Atualizando sistema operacional..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get upgrade -y

# ========================================
# INSTALAR DEPENDÊNCIAS
# ========================================
echo "[2/15] Instalando dependências do sistema..."
apt-get install -y \
    python3.11 \
    python3.11-venv \
    python3-pip \
    python3.11-dev \
    build-essential \
    nginx \
    postgresql-client \
    libpq-dev \
    git \
    supervisor \
    certbot \
    python3-certbot-nginx \
    awscli \
    curl \
    wget \
    vim \
    htop

# ========================================
# CRIAR USUÁRIO DA APLICAÇÃO
# ========================================
echo "[3/15] Criando usuário da aplicação..."
if ! id -u django > /dev/null 2>&1; then
    useradd -m -s /bin/bash django
    echo "Usuário django criado"
else
    echo "Usuário django já existe"
fi

# ========================================
# CRIAR ESTRUTURA DE DIRETÓRIOS
# ========================================
echo "[4/15] Criando estrutura de diretórios..."
mkdir -p /home/django/app
mkdir -p /var/log/django
mkdir -p /var/log/gunicorn
mkdir -p /home/django/media
mkdir -p /home/django/staticfiles

chown -R django:django /home/django
chown -R django:django /var/log/django
chown -R django:django /var/log/gunicorn

# ========================================
# CLONAR REPOSITÓRIO
# ========================================
echo "[5/15] Configurando repositório..."
cd /home/django/app

# ⚠️ AJUSTAR: Substituir pela URL real do seu repositório GitHub
# Por enquanto, criar estrutura básica
# Quando tiver o repo, descomente:
# git clone https://github.com/4Minds/s_agendamento.git .

echo "Repositório configurado"

# ========================================
# CRIAR .env.production
# ========================================
echo "[6/15] Criando arquivo .env.production..."
cat > /home/django/app/.env.production <<EOF
DEBUG=False
SECRET_KEY=TEMPORARY_KEY_WILL_BE_REPLACED_AFTER_SSH
ALLOWED_HOSTS=$DOMAIN_NAME,www.$DOMAIN_NAME
DJANGO_SETTINGS_MODULE=core.settings_production
ENVIRONMENT=production

DB_NAME=$DB_NAME
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
DB_HOST=$DB_HOST
DB_PORT=$DB_PORT

HTTPS_REDIRECT=True
SECURE_SSL_REDIRECT=True
SECURE_PROXY_SSL_HEADER=True
SESSION_COOKIE_SECURE=True
CSRF_COOKIE_SECURE=True

AWS_REGION=us-east-1

EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USE_TLS=True
EMAIL_HOST_USER=fourmindsorg@gmail.com
EMAIL_HOST_PASSWORD=CONFIGURE_APP_PASSWORD_APOS_SSH
DEFAULT_FROM_EMAIL=Sistema de Agendamentos <noreply@$DOMAIN_NAME>

LOG_LEVEL=INFO
MONITORING_ENABLED=True
HEALTH_CHECK_ENABLED=True
EOF

chown django:django /home/django/app/.env.production
chmod 600 /home/django/app/.env.production

echo ".env.production criado"

# ========================================
# CRIAR VIRTUALENV
# ========================================
echo "[7/15] Criando ambiente virtual Python..."
cd /home/django/app
python3.11 -m venv venv
chown -R django:django venv

echo "Virtualenv criado"

# ========================================
# INSTALAR DEPENDÊNCIAS PYTHON
# ========================================
echo "[8/15] Instalando dependências Python..."
su - django <<'DJANGO_USER'
cd /home/django/app
source venv/bin/activate
pip install --upgrade pip setuptools wheel
pip install \
    Django==5.2.6 \
    psycopg2-binary==2.9.9 \
    gunicorn==21.2.0 \
    whitenoise==6.6.0 \
    python-dotenv==1.0.0 \
    boto3==1.34.0 \
    django-storages==1.14.2
DJANGO_USER

echo "Dependências Python instaladas"

# ========================================
# CONFIGURAR GUNICORN
# ========================================
echo "[9/15] Configurando Gunicorn..."
cat > /etc/supervisor/conf.d/gunicorn.conf <<EOF
[program:gunicorn]
directory=/home/django/app
command=/home/django/app/venv/bin/gunicorn core.wsgi:application \
    --bind 0.0.0.0:8000 \
    --workers 3 \
    --worker-class sync \
    --timeout 60 \
    --max-requests 1000 \
    --max-requests-jitter 50 \
    --access-logfile /var/log/gunicorn/access.log \
    --error-logfile /var/log/gunicorn/error.log \
    --log-level info
user=django
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/var/log/gunicorn/gunicorn.log
environment=DJANGO_SETTINGS_MODULE="core.settings_production"
stopasgroup=true
killasgroup=true
EOF

echo "Gunicorn configurado"

# ========================================
# CONFIGURAR NGINX
# ========================================
echo "[10/15] Configurando Nginx..."
cat > /etc/nginx/sites-available/$PROJECT_NAME <<'NGINX_EOF'
server {
    listen 80;
    server_name DOMAIN_NAME_PLACEHOLDER www.DOMAIN_NAME_PLACEHOLDER;

    client_max_body_size 20M;
    client_body_timeout 60s;

    # Security headers
    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Static files
    location /static/ {
        alias /home/django/app/staticfiles/;
        expires 30d;
        add_header Cache-Control "public, immutable";
        access_log off;
    }

    # Media files
    location /media/ {
        alias /home/django/app/media/;
        expires 30d;
        add_header Cache-Control "public";
        access_log off;
    }

    # Health check (sem log)
    location /health/ {
        proxy_pass http://127.0.0.1:8000;
        access_log off;
    }

    # Django application
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_redirect off;
        proxy_buffering off;
        proxy_read_timeout 60s;
        proxy_connect_timeout 60s;
    }
}
NGINX_EOF

# Substituir placeholder pelo domínio real
sed -i "s/DOMAIN_NAME_PLACEHOLDER/$DOMAIN_NAME/g" /etc/nginx/sites-available/$PROJECT_NAME

# Ativar site
ln -sf /etc/nginx/sites-available/$PROJECT_NAME /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Testar configuração
nginx -t

echo "Nginx configurado"

# ========================================
# MIGRATIONS E COLLECTSTATIC
# ========================================
echo "[11/15] Executando migrations Django..."

# ⚠️ Quando tiver o código real, descomentar:
# su - django <<'DJANGO_MIGRATIONS'
# cd /home/django/app
# source venv/bin/activate
# python manage.py migrate --noinput
# python manage.py collectstatic --noinput --clear
# python manage.py create_4minds_superuser || true
# DJANGO_MIGRATIONS

echo "Migrations executadas (ou puladas se código não disponível)"

# ========================================
# REINICIAR SERVIÇOS
# ========================================
echo "[12/15] Iniciando serviços..."
systemctl daemon-reload
systemctl restart supervisor
systemctl enable supervisor
systemctl restart nginx
systemctl enable nginx

# Aguardar serviços iniciarem
sleep 5

# Verificar status
supervisorctl status || echo "Gunicorn não iniciado (esperado se código não disponível)"
systemctl status nginx --no-pager

echo "Serviços iniciados"

# ========================================
# CONFIGURAR FIREWALL
# ========================================
echo "[13/15] Configurando firewall..."
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

echo "Firewall configurado"

# ========================================
# CONFIGURAR SSL (LET'S ENCRYPT)
# ========================================
echo "[14/15] Configurando SSL com Let's Encrypt..."

# Aguardar DNS propagar
sleep 30

# Verificar se domínio está resolvendo
if host $DOMAIN_NAME | grep -q "has address"; then
    echo "DNS resolvendo para $DOMAIN_NAME, instalando certificado..."
    
    # Solicitar certificado
    certbot --nginx \
        -d $DOMAIN_NAME \
        -d www.$DOMAIN_NAME \
        --non-interactive \
        --agree-tos \
        --email fourmindsorg@gmail.com \
        --redirect \
        --hsts \
        --staple-ocsp \
        --must-staple || echo "Certificado SSL falhará até DNS propagar - execute manualmente depois"
    
    # Configurar renovação automática
    systemctl enable certbot.timer
    systemctl start certbot.timer
    
    echo "SSL configurado"
else
    echo "DNS ainda não propagado. Configure SSL manualmente depois com:"
    echo "sudo certbot --nginx -d $DOMAIN_NAME -d www.$DOMAIN_NAME"
fi

# ========================================
# CONFIGURAR CRON JOBS
# ========================================
echo "[15/15] Configurando tarefas agendadas..."

# Renovação SSL
echo "0 0,12 * * * root certbot renew --quiet" > /etc/cron.d/certbot-renew

# Limpeza de logs (manter últimos 7 dias)
echo "0 2 * * * root find /var/log/django -name '*.log' -mtime +7 -delete" > /etc/cron.d/cleanup-logs
echo "0 2 * * * root find /var/log/gunicorn -name '*.log' -mtime +7 -delete" >> /etc/cron.d/cleanup-logs

echo "Cron jobs configurados"

# ========================================
# CRIAR SCRIPT DE STATUS
# ========================================
cat > /usr/local/bin/app-status <<'STATUS_SCRIPT'
#!/bin/bash
echo "========================================="
echo "Status do Sistema - $(date)"
echo "========================================="
echo ""
echo "Serviços:"
systemctl status nginx --no-pager | head -5
echo ""
supervisorctl status
echo ""
echo "Logs recentes (últimas 10 linhas):"
tail -10 /var/log/gunicorn/gunicorn.log
echo ""
echo "Uso de recursos:"
df -h | grep -E '(Filesystem|/$)'
free -h
echo ""
echo "Health check:"
curl -s http://localhost/health/ || echo "Health check falhou"
echo ""
echo "========================================="
STATUS_SCRIPT

chmod +x /usr/local/bin/app-status

# ========================================
# FINALIZAÇÃO
# ========================================
echo "========================================="
echo "Configuração concluída!"
echo "========================================="
echo "Domínio: $DOMAIN_NAME"
echo "Data: $(date)"
echo ""
echo "Próximos passos:"
echo "1. SSH na instância"
echo "2. Gerar SECRET_KEY: python -c \"from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())\""
echo "3. Editar /home/django/app/.env.production"
echo "4. Configurar EMAIL_HOST_PASSWORD (App Password do Gmail)"
echo "5. Reiniciar: sudo supervisorctl restart gunicorn"
echo ""
echo "Comandos úteis:"
echo "- Status: app-status"
echo "- Logs: tail -f /var/log/gunicorn/gunicorn.log"
echo "- Nginx logs: tail -f /var/log/nginx/error.log"
echo "========================================="

# Enviar notificação (opcional)
# aws sns publish \
#     --region us-east-1 \
#     --topic-arn "arn:aws:sns:us-east-1:ACCOUNT:sistema-agendamento-alerts" \
#     --message "EC2 inicializada com sucesso! Domínio: $DOMAIN_NAME" \
#     --subject "Deploy Completo" 2>/dev/null || true

exit 0

