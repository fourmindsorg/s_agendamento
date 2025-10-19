#!/bin/bash

# Script de Setup Completo para EC2
# Execute este script diretamente na EC2 via Console AWS

set -e
set -x

echo "🚀 Iniciando setup completo na EC2..."

# 1. Clonar Repositório
echo "📥 Clonando repositório..."
cd /home/ubuntu
git clone https://github.com/fourmindsorg/s_agendamento.git
cd s_agendamento
echo "✅ Repositório clonado"
ls -la

# 2. Instalar Dependências do Sistema
echo "📦 Instalando dependências do sistema..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y python3 python3-pip python3-venv python3-dev postgresql-client nginx git libpq-dev build-essential
echo "✅ Dependências do sistema instaladas"

# 3. Configurar Ambiente Virtual
echo "🐍 Configurando ambiente virtual Python..."
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
echo "✅ Ambiente virtual configurado"

# 4. Criar Arquivo .env
echo "⚙️ Configurando variáveis de ambiente..."
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
ALLOWED_HOSTS=fourmindstech.com.br,www.fourmindstech.com.br,3.80.178.120,localhost,127.0.0.1
SECRET_KEY=4MindsAgendamento2025!SecretKey#Django
EOF
echo "✅ Arquivo .env criado"

# 5. Executar Migrações
echo "🗄️ Executando migrações do banco de dados..."
python manage.py migrate
echo "✅ Migrações executadas"

# 6. Criar Superusuário
echo "👤 Criando superusuário..."
echo "from django.contrib.auth import get_user_model; User = get_user_model(); User.objects.create_superuser('admin', 'admin@fourmindstech.com.br', 'admin123') if not User.objects.filter(username='admin').exists() else print('Superusuário já existe')" | python manage.py shell
echo "✅ Superusuário criado (admin/admin123)"

# 7. Coletar Arquivos Estáticos
echo "📁 Coletando arquivos estáticos..."
python manage.py collectstatic --noinput
echo "✅ Arquivos estáticos coletados"

# 8. Instalar Gunicorn
echo "🔧 Instalando Gunicorn..."
pip install gunicorn
echo "✅ Gunicorn instalado"

# 9. Configurar Gunicorn
echo "⚙️ Configurando serviço Gunicorn..."
sudo tee /etc/systemd/system/gunicorn.service > /dev/null << 'EOF'
[Unit]
Description=Gunicorn daemon for Django
After=network.target

[Service]
User=ubuntu
Group=www-data
WorkingDirectory=/home/ubuntu/s_agendamento
ExecStart=/home/ubuntu/s_agendamento/.venv/bin/gunicorn --workers 3 --bind unix:/home/ubuntu/s_agendamento/gunicorn.sock core.wsgi:application
ExecReload=/bin/kill -s HUP $MAINPID
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
echo "✅ Serviço Gunicorn configurado"

# 10. Configurar Nginx
echo "🌐 Configurando Nginx..."
sudo tee /etc/nginx/sites-available/agendamento-4minds > /dev/null << 'EOF'
server {
    listen 80;
    server_name fourmindstech.com.br www.fourmindstech.com.br 3.80.178.120;

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
echo "✅ Nginx configurado"

# 11. Ativar Configurações
echo "🔄 Ativando configurações..."
sudo ln -sf /etc/nginx/sites-available/agendamento-4minds /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
echo "✅ Configurações ativadas"

# 12. Iniciar Serviços
echo "🚀 Iniciando serviços..."
sudo systemctl daemon-reload
sudo systemctl start gunicorn
sudo systemctl enable gunicorn
sudo systemctl restart nginx
echo "✅ Serviços iniciados"

# 13. Verificar Status
echo "✅ Verificando status dos serviços..."
sudo systemctl status gunicorn --no-pager
sudo systemctl status nginx --no-pager

# 14. Testar Aplicação
echo "🌐 Testando aplicação..."
curl -I http://localhost:8000/ || echo "❌ Aplicação local não está respondendo"
curl -I http://3.80.178.120/ || echo "❌ Aplicação externa não está respondendo"

echo "🎉 Setup completo concluído!"
echo "🌐 Acesse: http://3.80.178.120"
echo "🌐 Acesse: http://fourmindstech.com.br (após configurar DNS)"
echo "👤 Admin: http://3.80.178.120/admin"
echo "👤 Usuário: admin | Senha: admin123"
