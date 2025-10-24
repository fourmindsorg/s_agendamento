#!/bin/bash
set -e

# Variáveis do template
DOMAIN_NAME="${domain_name}"
DB_ENDPOINT="${db_endpoint}"
DB_NAME="${db_name}"
DB_USERNAME="${db_username}"
DB_PASSWORD="${db_password}"
SECRET_KEY="${secret_key}"
STATIC_BUCKET="${static_bucket}"
MEDIA_BUCKET="${media_bucket}"

# Log de inicialização
echo "$(date): Iniciando configuração da instância EC2" >> /var/log/cloud-init-output.log

# Atualizar sistema
apt-get update
apt-get upgrade -y

# Instalar dependências
apt-get install -y python3 python3-pip python3-venv nginx postgresql-client git curl unzip

# Instalar Node.js para build de assets
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

# Instalar AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

# Criar usuário para aplicação
useradd -m -s /bin/bash django
usermod -aG www-data django

# Criar diretórios
mkdir -p /var/www/agendamento
mkdir -p /var/log/django
mkdir -p /etc/nginx/sites-available
mkdir -p /etc/nginx/sites-enabled

# Configurar permissões
chown -R django:django /var/www/agendamento
chown -R django:django /var/log/django

# Configurar nginx
cat > /etc/nginx/sites-available/agendamento << NGINX_EOF
server {
    listen 80;
    server_name ${domain_name} www.${domain_name} api.${domain_name} admin.${domain_name};
    
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    location /static/ {
        alias /var/www/agendamento/staticfiles/;
    }
    
    location /media/ {
        alias /var/www/agendamento/media/;
    }
}
NGINX_EOF

# Ativar site nginx
ln -sf /etc/nginx/sites-available/agendamento /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Testar configuração nginx
nginx -t

# Iniciar serviços
systemctl enable nginx
systemctl start nginx

# Instalar supervisor para gerenciar Django
apt-get install -y supervisor

# Configurar supervisor para Django
cat > /etc/supervisor/conf.d/django.conf << SUPERVISOR_EOF
[program:django]
command=/var/www/agendamento/venv/bin/gunicorn --bind 127.0.0.1:8000 core.wsgi:application
directory=/var/www/agendamento
user=django
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/var/log/django/django.log
SUPERVISOR_EOF

systemctl enable supervisor
systemctl start supervisor

# Log de inicialização
echo "$(date): Instância EC2 inicializada com sucesso" >> /var/log/django/startup.log
echo "$(date): Configuração concluída" >> /var/log/cloud-init-output.log
