#!/bin/bash

# Script de Correção para EC2
# Execute este script na EC2 para corrigir problemas comuns

set -e
set -x

echo "🔧 INICIANDO CORREÇÃO DA EC2"
echo "============================="

# 1. Verificar se estamos no diretório correto
cd /home/ubuntu
if [ ! -d "s_agendamento" ]; then
    echo "📥 Clonando repositório..."
    git clone https://github.com/fourmindsorg/s_agendamento.git
fi

cd s_agendamento

# 2. Instalar dependências se necessário
echo "📦 Verificando dependências do sistema..."
sudo apt update
sudo apt install -y python3 python3-pip python3-venv python3-dev postgresql-client nginx git libpq-dev build-essential

# 3. Configurar ambiente virtual
echo "🐍 Configurando ambiente virtual..."
if [ ! -d ".venv" ]; then
    python3 -m venv .venv
fi

source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# 4. Criar arquivo .env
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

# 5. Executar migrações
echo "🗄️ Executando migrações..."
python manage.py migrate

# 6. Criar superusuário se não existir
echo "👤 Criando superusuário..."
echo "from django.contrib.auth import get_user_model; User = get_user_model(); User.objects.create_superuser('admin', 'admin@fourmindstech.com.br', 'admin123') if not User.objects.filter(username='admin').exists() else print('Superusuário já existe')" | python manage.py shell

# 7. Coletar arquivos estáticos
echo "📁 Coletando arquivos estáticos..."
python manage.py collectstatic --noinput

# 8. Instalar Gunicorn
echo "🔧 Instalando Gunicorn..."
pip install gunicorn

# 9. Parar serviços existentes
echo "🛑 Parando serviços existentes..."
sudo systemctl stop gunicorn 2>/dev/null || true
sudo systemctl stop nginx 2>/dev/null || true

# 10. Configurar Gunicorn
echo "⚙️ Configurando Gunicorn..."
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

# 11. Configurar Nginx
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

# 12. Ativar configurações
echo "🔄 Ativando configurações..."
sudo ln -sf /etc/nginx/sites-available/agendamento-4minds /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# 13. Corrigir permissões
echo "🔐 Corrigindo permissões..."
sudo chown -R ubuntu:www-data /home/ubuntu/s_agendamento
sudo chmod -R 755 /home/ubuntu/s_agendamento

# 14. Testar configuração do Nginx
echo "🧪 Testando configuração do Nginx..."
sudo nginx -t

# 15. Recarregar e iniciar serviços
echo "🚀 Iniciando serviços..."
sudo systemctl daemon-reload
sudo systemctl start gunicorn
sudo systemctl enable gunicorn
sudo systemctl restart nginx

# 16. Aguardar um pouco
echo "⏳ Aguardando serviços iniciarem..."
sleep 10

# 17. Verificar status
echo "✅ Verificando status dos serviços..."
sudo systemctl status gunicorn --no-pager
sudo systemctl status nginx --no-pager

# 18. Testar aplicação
echo "🌐 Testando aplicação..."
curl -I http://localhost:8000/ || echo "❌ Aplicação local não responde"
curl -I http://3.80.178.120/ || echo "❌ Aplicação externa não responde"

# 19. Mostrar logs se houver erro
echo "📋 Logs do Gunicorn (últimas 10 linhas):"
sudo journalctl -u gunicorn --no-pager -n 10

echo "📋 Logs do Nginx (últimas 10 linhas):"
sudo journalctl -u nginx --no-pager -n 10

echo ""
echo "🎉 CORREÇÃO CONCLUÍDA!"
echo "🌐 Acesse: http://3.80.178.120"
echo "🌐 Acesse: http://fourmindstech.com.br (após configurar DNS)"
echo "👤 Admin: http://3.80.178.120/admin"
echo "👤 Usuário: admin | Senha: admin123"
