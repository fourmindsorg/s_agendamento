#!/bin/bash
set -e

echo "🔧 Corrigindo configuração da aplicação Django..."

# Verificar se o diretório existe
if [ -d /var/www/agendamento ]; then
    echo "✅ Diretório Django existe"
    cd /var/www/agendamento
else
    echo "❌ Criando diretório Django..."
    sudo mkdir -p /var/www/agendamento
    sudo chown -R ubuntu:ubuntu /var/www/agendamento
    cd /var/www/agendamento
fi

# Clonar repositório se não existir
if [ ! -d .git ]; then
    echo "📥 Clonando repositório..."
    git clone https://github.com/fourmindsorg/s_agendamento.git .
else
    echo "✅ Repositório já existe"
fi

# Criar ambiente virtual se não existir
if [ ! -d venv ]; then
    echo "🐍 Criando ambiente virtual..."
    python3 -m venv venv
fi

# Ativar ambiente virtual
source venv/bin/activate

# Instalar dependências
echo "📦 Instalando dependências..."
pip install --upgrade pip
pip install -r requirements.txt
pip install gunicorn psycopg2-binary

# Configurar variáveis de ambiente
echo "⚙️ Configurando variáveis de ambiente..."
cat > .env << 'EOF'
DEBUG=False
SECRET_KEY=django-insecure-4minds-agendamento-2025-super-secret-key
ALLOWED_HOSTS=fourmindstech.com.br,www.fourmindstech.com.br,api.fourmindstech.com.br,admin.fourmindstech.com.br,44.205.204.166
DATABASE_URL=postgresql://agendamento_user:4MindsAgendamento2025!SecureDB#Pass@s-agendamento-db.cgr24gyuwi3d.us-east-1.rds.amazonaws.com:5432/agendamento_db
AWS_STORAGE_BUCKET_NAME=s-agendamento-static-djet24kp
AWS_S3_REGION_NAME=us-east-1
EOF

# Executar migrações
echo "🗄️ Executando migrações..."
python manage.py migrate

# Criar superusuário
echo "👤 Criando superusuário..."
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
echo "📦 Coletando arquivos estáticos..."
python manage.py collectstatic --noinput

# Configurar Nginx
echo "🌐 Configurando Nginx..."
sudo tee /etc/nginx/sites-available/agendamento > /dev/null << 'NGINXEOF'
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

# Ativar site Nginx
sudo ln -sf /etc/nginx/sites-available/agendamento /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Testar configuração Nginx
sudo nginx -t

# Configurar Gunicorn como serviço
echo "🔧 Configurando Gunicorn..."
sudo tee /etc/systemd/system/gunicorn.service > /dev/null << 'GUNICORNEOF'
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
sudo systemctl daemon-reload
sudo systemctl enable gunicorn
sudo systemctl start gunicorn
sudo systemctl restart nginx

echo "✅ Configuração concluída!"
echo "🌐 Website: http://44.205.204.166"
echo "👤 Admin: http://44.205.204.166/admin/"
echo "📝 Usuário: admin | Senha: admin123"
