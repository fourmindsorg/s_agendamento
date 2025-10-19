#!/bin/bash
# ========================================
# Script de Inicialização EC2 - Simplificado
# Sistema de Agendamento - 4Minds
# ========================================

set -e  # Sair em caso de erro
set -x  # Mostrar comandos executados

# Variáveis
PROJECT_NAME="${project_name}"
DOMAIN_NAME="${domain_name}"

# Configuração de logs
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "========================================="
echo "Iniciando configuração do servidor EC2"
echo "Data: $(date)"
echo "Domínio: $DOMAIN_NAME"
echo "========================================="

# Atualizar sistema
echo "[1/10] Atualizando sistema operacional..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get upgrade -y

# Instalar dependências básicas
echo "[2/10] Instalando dependências do sistema..."
apt-get install -y \
    python3.11 \
    python3.11-venv \
    python3-pip \
    python3.11-dev \
    build-essential \
    nginx \
    git \
    supervisor \
    curl \
    wget \
    vim \
    htop \
    awscli

# Criar usuário da aplicação
echo "[3/10] Criando usuário da aplicação..."
if ! id -u django > /dev/null 2>&1; then
    useradd -m -s /bin/bash django
    echo "Usuário django criado"
else
    echo "Usuário django já existe"
fi

# Criar estrutura de diretórios
echo "[4/10] Criando estrutura de diretórios..."
mkdir -p /home/django/app
mkdir -p /var/log/django
mkdir -p /var/log/gunicorn
mkdir -p /home/django/media
mkdir -p /home/django/staticfiles

chown -R django:django /home/django
chown -R django:django /var/log/django
chown -R django:django /var/log/gunicorn

# Configurar repositório
echo "[5/10] Configurando repositório..."
cd /home/django/app
echo "Repositório configurado"

# Criar .env básico
echo "[6/10] Criando arquivo .env..."
cat > /home/django/app/.env <<EOF
DEBUG=False
SECRET_KEY=TEMPORARY_KEY_WILL_BE_REPLACED_AFTER_SSH
ALLOWED_HOSTS=$DOMAIN_NAME,www.$DOMAIN_NAME
DJANGO_SETTINGS_MODULE=core.settings_production
ENVIRONMENT=production

HTTPS_REDIRECT=True
SECURE_SSL_REDIRECT=True
SECURE_PROXY_SSL_HEADER=True
SESSION_COOKIE_SECURE=True
CSRF_COOKIE_SECURE=True

AWS_REGION=us-east-1

LOG_LEVEL=INFO
MONITORING_ENABLED=True
HEALTH_CHECK_ENABLED=True
EOF

chown django:django /home/django/app/.env
chmod 600 /home/django/app/.env

# Criar virtualenv
echo "[7/10] Criando ambiente virtual Python..."
cd /home/django/app
python3.11 -m venv venv
chown -R django:django venv

# Instalar dependências Python básicas
echo "[8/10] Instalando dependências Python..."
su - django <<'DJANGO_USER'
cd /home/django/app
source venv/bin/activate
pip install --upgrade pip setuptools wheel
pip install \
    Django==5.2.6 \
    gunicorn==21.2.0 \
    whitenoise==6.6.0 \
    python-dotenv==1.0.0
DJANGO_USER

# Configurar Nginx básico
echo "[9/10] Configurando Nginx..."
cat > /etc/nginx/sites-available/$PROJECT_NAME <<EOF
server {
    listen 80;
    server_name $DOMAIN_NAME www.$DOMAIN_NAME;

    client_max_body_size 20M;

    # Security headers
    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Health check
    location /health/ {
        return 200 'OK';
        add_header Content-Type text/plain;
    }

    # Default response
    location / {
        return 200 'Servidor configurado! Aguardando deploy da aplicação...';
        add_header Content-Type text/plain;
    }
}
EOF

# Ativar site
ln -sf /etc/nginx/sites-available/$PROJECT_NAME /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Testar configuração
nginx -t

# Iniciar serviços
echo "[10/10] Iniciando serviços..."
systemctl restart nginx
systemctl enable nginx

# Configurar firewall
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

echo "========================================="
echo "Configuração básica concluída!"
echo "========================================="
echo "Domínio: $DOMAIN_NAME"
echo "Data: $(date)"
echo ""
echo "Próximos passos:"
echo "1. SSH na instância: ssh -i ~/.ssh/id_rsa ubuntu@$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
echo "2. Fazer deploy da aplicação Django"
echo "3. Configurar banco de dados"
echo "4. Configurar SSL"
echo "========================================="

exit 0
