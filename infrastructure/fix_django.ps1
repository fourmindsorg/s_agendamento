# Script para corrigir a configuração do Django
Write-Host "🔧 Corrigindo configuração da aplicação Django..." -ForegroundColor Cyan

$INSTANCE_ID = "i-0bb8edf79961f187a"
$EC2_IP = "44.205.204.166"
$EC2_USER = "ubuntu"

# Script para executar na instância EC2
$fixScript = @"
#!/bin/bash
set -e

echo "🔧 Verificando status dos serviços..."

# Verificar se o Django está rodando
if systemctl is-active --quiet gunicorn; then
    echo "✅ Gunicorn está rodando"
else
    echo "❌ Gunicorn não está rodando. Iniciando..."
    sudo systemctl start gunicorn
    sudo systemctl enable gunicorn
fi

# Verificar se o Nginx está configurado corretamente
if [ -f /etc/nginx/sites-enabled/agendamento ]; then
    echo "✅ Site do Nginx configurado"
else
    echo "❌ Site do Nginx não configurado. Configurando..."
    
    # Configurar Nginx para Django
    sudo tee /etc/nginx/sites-available/agendamento > /dev/null << 'EOF'
server {
    listen 80;
    server_name fourmindstech.com.br www.fourmindstech.com.br api.fourmindstech.com.br admin.fourmindstech.com.br 44.205.204.166;
    
    client_max_body_size 20M;
    
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
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
EOF

    # Ativar site
    sudo ln -sf /etc/nginx/sites-available/agendamento /etc/nginx/sites-enabled/
    sudo rm -f /etc/nginx/sites-enabled/default
    
    # Testar configuração
    sudo nginx -t
    
    # Reiniciar Nginx
    sudo systemctl restart nginx
fi

# Verificar se o Django está instalado
if [ -d /var/www/agendamento ]; then
    echo "✅ Diretório Django existe"
    cd /var/www/agendamento
    
    # Verificar se o ambiente virtual existe
    if [ -d venv ]; then
        echo "✅ Ambiente virtual existe"
        source venv/bin/activate
        
        # Verificar se o Django está instalado
        if python -c "import django; print(django.get_version())" 2>/dev/null; then
            echo "✅ Django está instalado"
        else
            echo "❌ Django não está instalado. Instalando..."
            pip install django gunicorn psycopg2-binary
        fi
        
        # Verificar se o arquivo .env existe
        if [ -f .env ]; then
            echo "✅ Arquivo .env existe"
        else
            echo "❌ Arquivo .env não existe. Criando..."
            cat > .env << 'ENVEOF'
DEBUG=False
SECRET_KEY=django-insecure-4minds-agendamento-2025-super-secret-key
ALLOWED_HOSTS=fourmindstech.com.br,www.fourmindstech.com.br,api.fourmindstech.com.br,admin.fourmindstech.com.br,44.205.204.166
DATABASE_URL=postgresql://agendamento_user:4MindsAgendamento2025!SecureDB#Pass@s-agendamento-db.cgr24gyuwi3d.us-east-1.rds.amazonaws.com:5432/agendamento_db
AWS_STORAGE_BUCKET_NAME=s-agendamento-static-djet24kp
AWS_S3_REGION_NAME=us-east-1
ENVEOF
        fi
        
        # Executar migrações
        echo "🔄 Executando migrações..."
        python manage.py migrate
        
        # Coletar arquivos estáticos
        echo "📦 Coletando arquivos estáticos..."
        python manage.py collectstatic --noinput
        
        # Criar superusuário se não existir
        echo "👤 Verificando superusuário..."
        python manage.py shell << 'PYEOF'
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser('admin', 'admin@fourmindstech.com.br', 'admin123')
    print("Superusuário criado com sucesso!")
else:
    print("Superusuário já existe!")
PYEOF
        
    else
        echo "❌ Ambiente virtual não existe. Criando..."
        python3 -m venv venv
        source venv/bin/activate
        pip install --upgrade pip
        pip install django gunicorn psycopg2-binary
    fi
else
    echo "❌ Diretório Django não existe. Criando..."
    sudo mkdir -p /var/www/agendamento
    sudo chown -R ubuntu:ubuntu /var/www/agendamento
    cd /var/www/agendamento
    
    # Clonar repositório
    git clone https://github.com/fourmindsorg/s_agendamento.git .
    
    # Criar ambiente virtual
    python3 -m venv venv
    source venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt
    pip install gunicorn psycopg2-binary
fi

# Configurar Gunicorn como serviço
echo "🔧 Configurando Gunicorn como serviço..."
sudo tee /etc/systemd/system/gunicorn.service > /dev/null << 'EOF'
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
EOF

# Recarregar e iniciar serviços
sudo systemctl daemon-reload
sudo systemctl enable gunicorn
sudo systemctl start gunicorn

# Reiniciar Nginx
sudo systemctl restart nginx

echo "✅ Configuração concluída!"
echo "🌐 Website: http://44.205.204.166"
echo "👤 Admin: http://44.205.204.166/admin/"
echo "📝 Usuário: admin | Senha: admin123"
"@

# Salvar script
$fixScript | Out-File -FilePath "fix_django.sh" -Encoding UTF8

Write-Host "📤 Enviando script de correção para a instância EC2..." -ForegroundColor Yellow

# Enviar e executar script via SSH
wsl scp -i ~/.ssh/s-agendamento-key.pem fix_django.sh ${EC2_USER}@${EC2_IP}:/home/ubuntu/
wsl ssh -i ~/.ssh/s-agendamento-key.pem ${EC2_USER}@${EC2_IP} "chmod +x fix_django.sh && sudo ./fix_django.sh"

# Limpar arquivo temporário
Remove-Item fix_django.sh -Force -ErrorAction SilentlyContinue

Write-Host "✅ Script de correção executado!" -ForegroundColor Green
Write-Host "🌐 Teste o website: http://44.205.204.166" -ForegroundColor Cyan
Write-Host "👤 Admin: http://44.205.204.166/admin/" -ForegroundColor Cyan
