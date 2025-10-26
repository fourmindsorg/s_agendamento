#!/bin/bash
# Script para completar o deploy da aplicação Django real

echo "=== COMPLETANDO DEPLOY DA APLICAÇÃO DJANGO REAL ==="

# Atualizar sistema
echo "Atualizando sistema..."
apt update -y
apt upgrade -y

# Instalar dependências
echo "Instalando dependências..."
apt install -y python3 python3-pip python3-venv nginx supervisor postgresql-client libpq-dev git curl

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

# Clonar repositório da aplicação
echo "Clonando repositório da aplicação..."
cd /opt/s-agendamento
sudo -u django git clone https://github.com/4Minds-Team/s-agendamento.git .

# Instalar dependências Python
echo "Instalando dependências Python..."
sudo -u django /opt/s-agendamento/venv/bin/pip install -r requirements.txt

# Configurar arquivo .env
echo "Configurando arquivo .env..."
sudo -u django tee /opt/s-agendamento/.env > /dev/null <<EOF
SECRET_KEY=django-insecure-4minds-agendamento-2025-super-secret-key
DEBUG=False
ALLOWED_HOSTS=['*', 'fourmindstech.com.br', 'www.fourmindstech.com.br']
DATABASE_URL=postgres://agendamento_user:4MindsAgendamento2025!SecureDB#Pass@s-agendamento-db.cgr24gyuwi3d.us-east-1.rds.amazonaws.com:5432/agendamento_db
AWS_STORAGE_BUCKET_NAME_STATIC=s-agendamento-static-exxyawpx
AWS_STORAGE_BUCKET_NAME_MEDIA=s-agendamento-media-exxyawpx
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
AWS_S3_REGION_NAME=us-east-1
EOF

# Executar migrações
echo "Executando migrações..."
sudo -u django /opt/s-agendamento/venv/bin/python manage.py migrate --noinput

# Coletar arquivos estáticos
echo "Coletando arquivos estáticos..."
sudo -u django /opt/s-agendamento/venv/bin/python manage.py collectstatic --noinput

# Criar superusuário
echo "Criando superusuário..."
sudo -u django /opt/s-agendamento/venv/bin/python manage.py shell -c "
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser('admin', 'admin@example.com', 'admin123')
    print('Superusuário criado: admin/admin123')
else:
    print('Superusuário já existe')
"

# Configurar Nginx
echo "Configurando Nginx..."
tee /etc/nginx/sites-available/s-agendamento > /dev/null <<EOF
server {
    listen 80;
    server_name _ fourmindstech.com.br www.fourmindstech.com.br;

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

# Ativar site
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

# Criar diretório de logs
mkdir -p /opt/s-agendamento/logs
chown django:django /opt/s-agendamento/logs

# Reiniciar Supervisor
supervisorctl reread
supervisorctl update
supervisorctl start s-agendamento

echo "=== DEPLOY DA APLICAÇÃO DJANGO REAL CONCLUÍDO ==="
echo "Aplicação disponível em:"
echo "- http://98.91.238.63"
echo "- http://fourmindstech.com.br"
echo "- Admin: http://fourmindstech.com.br/admin (admin/admin123)"
