#!/bin/bash
set -e

# Configurações
EC2_IP="44.205.204.166"
EC2_USER="ubuntu"
SSH_KEY="~/.ssh/s-agendamento-key.pem"
DOMAIN="fourmindstech.com.br"

echo "🚀 Iniciando deploy da aplicação Django..."

# 1. Conectar via SSH e configurar servidor
ssh -i $SSH_KEY $EC2_USER@$EC2_IP << 'ENDSSH'
set -e

echo "📦 Atualizando sistema..."
sudo apt-get update
sudo apt-get upgrade -y

echo "📦 Instalando dependências..."
sudo apt-get install -y python3 python3-pip python3-venv nginx git curl

echo "📁 Criando estrutura de diretórios..."
sudo mkdir -p /var/www/agendamento
sudo chown -R ubuntu:ubuntu /var/www/agendamento

echo "🔽 Clonando repositório..."
cd /var/www/agendamento
git clone https://github.com/fourmindsorg/s_agendamento.git .

echo "🐍 Criando ambiente virtual..."
python3 -m venv venv
source venv/bin/activate

echo "📦 Instalando dependências Python..."
pip install --upgrade pip
pip install -r requirements.txt
pip install gunicorn

echo "⚙️ Configurando Django..."
cat > .env << 'EOF'
DEBUG=False
SECRET_KEY=django-insecure-4minds-agendamento-2025-super-secret-key
ALLOWED_HOSTS=fourmindstech.com.br,www.fourmindstech.com.br,44.205.204.166
DATABASE_URL=postgresql://agendamento_user:4MindsAgendamento2025!SecureDB#Pass@s-agendamento-db.cgr24gyuwi3d.us-east-1.rds.amazonaws.com:5432/agendamento_db
AWS_STORAGE_BUCKET_NAME=s-agendamento-static-djet24kp
AWS_S3_REGION_NAME=us-east-1
EOF

echo "🗄️ Executando migrações..."
python manage.py migrate

echo "👤 Criando superusuário..."
python manage.py shell << 'PYEOF'
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser('admin', 'admin@fourmindstech.com.br', 'admin123')
    print("Superusuário criado com sucesso!")
PYEOF

echo "📦 Coletando arquivos estáticos..."
python manage.py collectstatic --noinput

echo "🌐 Configurando Nginx..."
sudo tee /etc/nginx/sites-available/agendamento > /dev/null << 'NGINXEOF'
server {
    listen 80;
    server_name fourmindstech.com.br www.fourmindstech.com.br api.fourmindstech.com.br admin.fourmindstech.com.br;
    
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    location /static/ {
        alias /var/www/agendamento/staticfiles/;
    }
    
    location /media/ {
        alias /var/www/agendamento/media/;
    }
}
NGINXEOF

sudo ln -sf /etc/nginx/sites-available/agendamento /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx

echo "🔧 Configurando Gunicorn como serviço..."
sudo tee /etc/systemd/system/gunicorn.service > /dev/null << 'GUNICORNEOF'
[Unit]
Description=gunicorn daemon for Django
After=network.target

[Service]
User=ubuntu
Group=www-data
WorkingDirectory=/var/www/agendamento
ExecStart=/var/www/agendamento/venv/bin/gunicorn --workers 3 --bind 127.0.0.1:8000 core.wsgi:application

[Install]
WantedBy=multi-user.target
GUNICORNEOF

sudo systemctl daemon-reload
sudo systemctl start gunicorn
sudo systemctl enable gunicorn

echo "✅ Deploy concluído com sucesso!"
echo "🌐 Website disponível em: http://fourmindstech.com.br"

ENDSSH

echo "✅ Deploy completo!"
echo "🌐 Acesse: http://fourmindstech.com.br"
echo "👤 Admin: http://fourmindstech.com.br/admin/"
echo "📝 Usuário: admin | Senha: admin123"

