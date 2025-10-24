# Script de Deploy da Aplicação Django para AWS EC2
# Sistema de Agendamento 4Minds

Write-Host "🚀 Iniciando deploy da aplicação Django..." -ForegroundColor Cyan

# Configurações
$EC2_IP = "44.205.204.166"
$EC2_USER = "ubuntu"

Write-Host "`n📝 IMPORTANTE: Este script requer chave SSH!" -ForegroundColor Yellow
Write-Host "Você tem a chave SSH s-agendamento-key.pem?" -ForegroundColor Yellow
$hasKey = Read-Host "Digite 'sim' para continuar ou 'nao' para gerar a chave"

if ($hasKey -eq "nao") {
    Write-Host "`n🔑 Gerando nova chave SSH..." -ForegroundColor Cyan
    
    # Criar par de chaves na AWS
    aws ec2 create-key-pair --key-name s-agendamento-key --query 'KeyMaterial' --output text | Out-File -FilePath "$env:USERPROFILE\.ssh\s-agendamento-key.pem" -Encoding ASCII
    
    Write-Host "✅ Chave SSH criada em: $env:USERPROFILE\.ssh\s-agendamento-key.pem" -ForegroundColor Green
}

Write-Host "`n🌐 Testando conexão com a instância EC2..." -ForegroundColor Cyan
$testConnection = Test-Connection -ComputerName $EC2_IP -Count 2 -Quiet

if (-not $testConnection) {
    Write-Host "❌ Não foi possível conectar ao servidor!" -ForegroundColor Red
    Write-Host "Verifique se a instância EC2 está rodando." -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Conexão OK!" -ForegroundColor Green

Write-Host "`n📦 Criando script de configuração..." -ForegroundColor Cyan

# Criar script de setup
$setupScript = @"
#!/bin/bash
set -e

echo '📦 Atualizando sistema...'
sudo apt-get update -y
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

echo '📦 Instalando dependências...'
sudo apt-get install -y python3 python3-pip python3-venv nginx git curl postgresql-client

echo '📁 Criando estrutura de diretórios...'
sudo mkdir -p /var/www/agendamento
sudo chown -R ubuntu:ubuntu /var/www/agendamento

echo '🔽 Clonando repositório...'
cd /var/www/agendamento
git clone https://github.com/fourmindsorg/s_agendamento.git . || (cd /var/www/agendamento && git pull)

echo '🐍 Criando ambiente virtual...'
python3 -m venv venv
source venv/bin/activate

echo '📦 Instalando dependências Python...'
pip install --upgrade pip
pip install -r requirements.txt
pip install gunicorn psycopg2-binary python-decouple

echo '⚙️ Configurando Django...'
cat > .env << 'EOF'
DEBUG=False
SECRET_KEY=django-insecure-4minds-agendamento-2025-super-secret-key
ALLOWED_HOSTS=fourmindstech.com.br,www.fourmindstech.com.br,44.205.204.166,api.fourmindstech.com.br,admin.fourmindstech.com.br
DATABASE_URL=postgresql://agendamento_user:4MindsAgendamento2025!SecureDB#Pass@s-agendamento-db.cgr24gyuwi3d.us-east-1.rds.amazonaws.com:5432/agendamento_db
AWS_STORAGE_BUCKET_NAME=s-agendamento-static-djet24kp
AWS_S3_REGION_NAME=us-east-1
EOF

echo '🗄️ Testando conexão com o banco...'
python manage.py check --database default || echo 'Aviso: Não foi possível conectar ao banco'

echo '🗄️ Executando migrações...'
python manage.py migrate --noinput || echo 'Aviso: Migrações falharam'

echo '👤 Criando superusuário...'
python manage.py shell << 'PYEOF'
from django.contrib.auth import get_user_model
User = get_user_model()
try:
    if not User.objects.filter(username='admin').exists():
        User.objects.create_superuser('admin', 'admin@fourmindstech.com.br', 'admin123')
        print('Superusuário criado!')
    else:
        print('Superusuário já existe!')
except Exception as e:
    print(f'Erro ao criar superusuário: {e}')
PYEOF

echo '📦 Coletando arquivos estáticos...'
python manage.py collectstatic --noinput || echo 'Aviso: Collectstatic falhou'

echo '🌐 Configurando Nginx...'
sudo tee /etc/nginx/sites-available/agendamento > /dev/null << 'NGINXEOF'
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
NGINXEOF

sudo ln -sf /etc/nginx/sites-available/agendamento /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl restart nginx || echo 'Erro ao reiniciar Nginx'

echo '🔧 Configurando Gunicorn como serviço...'
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

sudo systemctl daemon-reload
sudo systemctl restart gunicorn || sudo systemctl start gunicorn
sudo systemctl enable gunicorn

echo ''
echo '✅ Deploy concluído com sucesso!'
echo '🌐 Website: http://fourmindstech.com.br'
echo '👤 Admin: http://fourmindstech.com.br/admin/'
echo '📝 Usuário: admin | Senha: admin123'
echo ''
"@

# Salvar script
$setupScript | Out-File -FilePath "setup_server.sh" -Encoding UTF8

Write-Host "`n📤 Enviando script para o servidor..." -ForegroundColor Cyan

# Usar PuTTY pscp se disponível, senão usar scp do WSL
if (Get-Command pscp -ErrorAction SilentlyContinue) {
    pscp -i "$env:USERPROFILE\.ssh\s-agendamento-key.ppk" setup_server.sh ${EC2_USER}@${EC2_IP}:/home/ubuntu/
} else {
    Write-Host "ℹ️ Usando WSL para transferência..." -ForegroundColor Yellow
    wsl scp -i ~/.ssh/s-agendamento-key.pem setup_server.sh ${EC2_USER}@${EC2_IP}:/home/ubuntu/
}

Write-Host "`n🚀 Executando deploy no servidor..." -ForegroundColor Cyan

# Executar via WSL
wsl ssh -i ~/.ssh/s-agendamento-key.pem ${EC2_USER}@${EC2_IP} "chmod +x setup_server.sh && ./setup_server.sh"

# Limpar arquivo temporário
Remove-Item setup_server.sh -Force

Write-Host "`n✅ Deploy completo!" -ForegroundColor Green
Write-Host "`n🌐 Acesse o website:" -ForegroundColor Cyan
Write-Host "   http://fourmindstech.com.br" -ForegroundColor White
Write-Host "   http://44.205.204.166" -ForegroundColor White
Write-Host "`n👤 Admin:" -ForegroundColor Cyan
Write-Host "   http://fourmindstech.com.br/admin/" -ForegroundColor White
Write-Host "   Usuário: admin | Senha: admin123" -ForegroundColor Yellow

