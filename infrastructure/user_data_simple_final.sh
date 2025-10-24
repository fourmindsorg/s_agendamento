#!/bin/bash
set -e

# Log de inicialização
echo "$(date): Iniciando configuração simples da instância EC2" >> /var/log/cloud-init-output.log

# Atualizar sistema
echo "$(date): Atualizando sistema..." >> /var/log/cloud-init-output.log
apt-get update
apt-get upgrade -y

# Instalar dependências básicas
echo "$(date): Instalando dependências..." >> /var/log/cloud-init-output.log
apt-get install -y python3 python3-pip python3-venv nginx git

# Criar diretório da aplicação
echo "$(date): Criando diretório da aplicação..." >> /var/log/cloud-init-output.log
mkdir -p /var/www/agendamento
chown -R ubuntu:ubuntu /var/www/agendamento

# Baixar código da aplicação
echo "$(date): Baixando código da aplicação..." >> /var/log/cloud-init-output.log
cd /var/www/agendamento
git clone https://github.com/fourmindsorg/s_agendamento.git .

# Criar ambiente virtual
echo "$(date): Criando ambiente virtual..." >> /var/log/cloud-init-output.log
python3 -m venv venv
source venv/bin/activate

# Instalar dependências Python
echo "$(date): Instalando dependências Python..." >> /var/log/cloud-init-output.log
pip install --upgrade pip
pip install -r requirements.txt
pip install gunicorn psycopg2-binary

# Configurar variáveis de ambiente
echo "$(date): Configurando variáveis de ambiente..." >> /var/log/cloud-init-output.log
cat > .env << 'EOF'
DEBUG=False
SECRET_KEY=django-insecure-4minds-agendamento-2025-super-secret-key
ALLOWED_HOSTS=fourmindstech.com.br,www.fourmindstech.com.br,api.fourmindstech.com.br,admin.fourmindstech.com.br,44.205.204.166
DATABASE_URL=postgresql://agendamento_user:4MindsAgendamento2025!SecureDB#Pass@s-agendamento-db.cgr24gyuwi3d.us-east-1.rds.amazonaws.com:5432/agendamento_db
AWS_STORAGE_BUCKET_NAME=s-agendamento-static-djet24kp
AWS_S3_REGION_NAME=us-east-1
EOF

# Executar migrações do banco
echo "$(date): Executando migrações..." >> /var/log/cloud-init-output.log
python manage.py migrate

# Criar superusuário
echo "$(date): Criando superusuário..." >> /var/log/cloud-init-output.log
python manage.py shell << 'PYEOF'
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser('admin', 'admin@fourmindstech.com.br', 'admin123')
    print("Superusuário criado com sucesso!")
else:
    print("Superusuário já existe!")
PYEOF

# Coletar arquivos estáticos
echo "$(date): Coletando arquivos estáticos..." >> /var/log/cloud-init-output.log
python manage.py collectstatic --noinput

# Configurar nginx
echo "$(date): Configurando Nginx..." >> /var/log/cloud-init-output.log
cat > /etc/nginx/sites-available/agendamento << 'NGINXEOF'
server {
    listen 80;
    server_name fourmindstech.com.br www.fourmindstech.com.br api.fourmindstech.com.br admin.fourmindstech.com.br 44.205.204.166;
    
    client_max_body_size 20M;
    
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 300s;
        proxy_connect_timeout 300s;
    }
    
    location /static/ {
        alias /var/www/agendamento/staticfiles/;
        expires 30d;
    }
    
    location /media/ {
        alias /var/www/agendamento/media/;
        expires 30d;
    }
}
NGINXEOF

# Ativar site nginx
ln -sf /etc/nginx/sites-available/agendamento /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Testar configuração nginx
nginx -t

# Configurar Gunicorn como serviço
echo "$(date): Configurando Gunicorn..." >> /var/log/cloud-init-output.log
cat > /etc/systemd/system/gunicorn.service << 'GUNICORNEOF'
[Unit]
Description=Gunicorn daemon for Django Agendamento
After=network.target

[Service]
User=ubuntu
Group=www-data
WorkingDirectory=/var/www/agendamento
Environment="PATH=/var/www/agendamento/venv/bin"
ExecStart=/var/www/agendamento/venv/bin/gunicorn --workers 3 --bind 127.0.0.1:8000 core.wsgi:application --timeout 120

[Install]
WantedBy=multi-user.target
GUNICORNEOF

# Recarregar e iniciar serviços
systemctl daemon-reload
systemctl enable gunicorn
systemctl start gunicorn
systemctl restart nginx

# Log de inicialização
echo "$(date): Instância EC2 inicializada com sucesso" >> /var/log/cloud-init-output.log
echo "$(date): Configuração completa concluída" >> /var/log/cloud-init-output.log
echo "$(date): Website disponível em: http://44.205.204.166" >> /var/log/cloud-init-output.log
echo "$(date): Admin disponível em: http://44.205.204.166/admin/" >> /var/log/cloud-init-output.log


