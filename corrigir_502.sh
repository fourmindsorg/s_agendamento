#!/bin/bash

# Script para corrigir erro 502 Bad Gateway
echo "🔧 CORRIGINDO ERRO 502 BAD GATEWAY"
echo "=================================="

# 1. Verificar se estamos no diretório correto
cd /home/ubuntu
if [ ! -d "s_agendamento" ]; then
    echo "❌ Diretório s_agendamento não existe. Clonando..."
    git clone https://github.com/fourmindsorg/s_agendamento.git
fi

cd s_agendamento

# 2. Ativar ambiente virtual
echo "🐍 Ativando ambiente virtual..."
if [ -d ".venv" ]; then
    source .venv/bin/activate
    echo "✅ Ambiente virtual ativado"
else
    echo "❌ Ambiente virtual não existe. Criando..."
    python3 -m venv .venv
    source .venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt
fi

# 3. Criar arquivo .env se não existir
if [ ! -f ".env" ]; then
    echo "⚙️ Criando arquivo .env..."
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
fi

# 4. Executar migrações
echo "🗄️ Executando migrações..."
python manage.py migrate

# 5. Criar superusuário se não existir
echo "👤 Verificando superusuário..."
echo "from django.contrib.auth import get_user_model; User = get_user_model(); User.objects.create_superuser('admin', 'admin@fourmindstech.com.br', 'admin123') if not User.objects.filter(username='admin').exists() else print('Superusuário já existe')" | python manage.py shell

# 6. Coletar arquivos estáticos
echo "📁 Coletando arquivos estáticos..."
python manage.py collectstatic --noinput

# 7. Parar serviços existentes
echo "🛑 Parando serviços existentes..."
sudo systemctl stop gunicorn 2>/dev/null || true
sudo systemctl stop nginx 2>/dev/null || true
sudo pkill -f gunicorn 2>/dev/null || true

# 8. Instalar Gunicorn se não estiver instalado
echo "🔧 Instalando Gunicorn..."
pip install gunicorn

# 9. Configurar Gunicorn
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

# 11. Ativar configurações
echo "🔄 Ativando configurações..."
sudo ln -sf /etc/nginx/sites-available/agendamento-4minds /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# 12. Corrigir permissões
echo "🔐 Corrigindo permissões..."
sudo chown -R ubuntu:www-data /home/ubuntu/s_agendamento
sudo chmod -R 755 /home/ubuntu/s_agendamento

# 13. Testar configuração do Nginx
echo "🧪 Testando configuração do Nginx..."
sudo nginx -t

# 14. Iniciar serviços
echo "🚀 Iniciando serviços..."
sudo systemctl daemon-reload
sudo systemctl start gunicorn
sudo systemctl enable gunicorn
sudo systemctl restart nginx

# 15. Aguardar serviços iniciarem
echo "⏳ Aguardando serviços iniciarem..."
sleep 15

# 16. Verificar status
echo "✅ Verificando status dos serviços..."
echo "📊 Status do Gunicorn:"
sudo systemctl is-active gunicorn || echo "❌ Gunicorn não está ativo"

echo "📊 Status do Nginx:"
sudo systemctl is-active nginx || echo "❌ Nginx não está ativo"

# 17. Testar aplicação
echo "🌐 Testando aplicação..."
timeout 10 curl -I http://localhost:8000/ 2>/dev/null && echo "✅ Aplicação local responde" || echo "❌ Aplicação local não responde"
timeout 10 curl -I http://3.80.178.120/ 2>/dev/null && echo "✅ Aplicação externa responde" || echo "❌ Aplicação externa não responde"

# 18. Mostrar logs se houver erro
echo "📋 Logs do Gunicorn (últimas 10 linhas):"
sudo journalctl -u gunicorn --no-pager -n 10

echo "📋 Logs do Nginx (últimas 10 linhas):"
sudo journalctl -u nginx --no-pager -n 10

echo ""
echo "🎉 CORREÇÃO CONCLUÍDA!"
echo "🌐 Acesse: http://3.80.178.120"
echo "👤 Admin: http://3.80.178.120/admin"
echo "👤 Usuário: admin | Senha: admin123"
echo ""
echo "📝 NOTA: O domínio fourmindstech.com.br só funcionará após configurar o DNS"
echo "🔧 Configure DNS: A @ → 3.80.178.120 e CNAME www → fourmindstech.com.br"
