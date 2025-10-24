#!/bin/bash
# Script de configuração inicial da instância EC2 - Versão Simplificada

echo "=== CONFIGURANDO INSTÂNCIA EC2 PARA DJANGO ==="

# Atualizar sistema
echo "Atualizando sistema..."
apt update -y
apt upgrade -y

# Instalar dependências
echo "Instalando dependências..."
apt install -y python3 python3-pip python3-venv nginx supervisor postgresql-client libpq-dev git

# Criar usuário para a aplicação
echo "Criando usuário 'django'..."
adduser --system --group django

# Criar diretório para a aplicação
echo "Criando diretório da aplicação..."
mkdir -p /opt/s-agendamento
chown django:django /opt/s-agendamento

# Configurar ambiente virtual
echo "Configurando ambiente virtual Python..."
sudo -u django python3 -m venv /opt/s-agendamento/venv

# Configurar Nginx
echo "Configurando Nginx..."
tee /etc/nginx/sites-available/s-agendamento > /dev/null <<EOF
server {
    listen 80;
    server_name _;

    location = /favicon.ico { access_log off; log_not_found off; }
    location /static/ {
        alias /opt/s-agendamento/staticfiles/;
    }
    location /media/ {
        alias /opt/s-agendamento/mediafiles/;
    }

    location / {
        include proxy_params;
        proxy_pass http://unix:/opt/s-agendamento/s-agendamento.sock;
    }
}
EOF

ln -sf /etc/nginx/sites-available/s-agendamento /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl restart nginx

# Configurar Supervisor
echo "Configurando Supervisor..."
tee /etc/supervisor/conf.d/s-agendamento.conf > /dev/null <<EOF
[program:s-agendamento]
command=/opt/s-agendamento/venv/bin/gunicorn core.wsgi:application --bind unix:/opt/s-agendamento/s-agendamento.sock
directory=/opt/s-agendamento
user=django
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/opt/s-agendamento/logs/gunicorn.log
environment=DJANGO_SETTINGS_MODULE="core.settings_production_aws"
EOF

mkdir -p /opt/s-agendamento/logs
supervisorctl reread
supervisorctl update

echo "=== CONFIGURAÇÃO EC2 CONCLUÍDA ==="
echo "A instância está pronta para receber o deploy da aplicação Django."