# Script de Deploy Simples para Django na AWS EC2
Write-Host "🚀 Iniciando deploy da aplicação Django..." -ForegroundColor Cyan

# Configurações
$EC2_IP = "44.205.204.166"
$EC2_USER = "ubuntu"

Write-Host "`n📝 Verificando se a chave SSH existe..." -ForegroundColor Yellow
$sshKeyPath = "$env:USERPROFILE\.ssh\s-agendamento-key.pem"

if (-not (Test-Path $sshKeyPath)) {
    Write-Host "❌ Chave SSH não encontrada!" -ForegroundColor Red
    Write-Host "Criando nova chave SSH..." -ForegroundColor Yellow
    
    # Criar par de chaves na AWS
    aws ec2 create-key-pair --key-name s-agendamento-key --query 'KeyMaterial' --output text | Out-File -FilePath $sshKeyPath -Encoding ASCII
    
    Write-Host "✅ Chave SSH criada em: $sshKeyPath" -ForegroundColor Green
}

Write-Host "`n🌐 Testando conexão com a instância EC2..." -ForegroundColor Cyan
$testConnection = Test-Connection -ComputerName $EC2_IP -Count 1 -Quiet

if (-not $testConnection) {
    Write-Host "❌ Não foi possível conectar ao servidor!" -ForegroundColor Red
    Write-Host "Verifique se a instância EC2 está rodando." -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Conexão OK!" -ForegroundColor Green

Write-Host "`n📦 Criando script de configuração para o servidor..." -ForegroundColor Cyan

# Criar arquivo de script bash
$bashScript = @'
#!/bin/bash
set -e

echo "📦 Atualizando sistema..."
sudo apt-get update -y

echo "📦 Instalando dependências..."
sudo apt-get install -y python3 python3-pip python3-venv nginx git curl

echo "📁 Criando diretório da aplicação..."
sudo mkdir -p /var/www/agendamento
sudo chown -R ubuntu:ubuntu /var/www/agendamento

echo "🔽 Baixando código da aplicação..."
cd /var/www/agendamento
if [ ! -d ".git" ]; then
    git clone https://github.com/fourmindsorg/s_agendamento.git .
else
    git pull
fi

echo "🐍 Criando ambiente virtual Python..."
python3 -m venv venv
source venv/bin/activate

echo "📦 Instalando dependências Python..."
pip install --upgrade pip
pip install -r requirements.txt
pip install gunicorn

echo "⚙️ Configurando variáveis de ambiente..."
cat > .env << 'EOF'
DEBUG=False
SECRET_KEY=django-insecure-4minds-agendamento-2025-super-secret-key
ALLOWED_HOSTS=fourmindstech.com.br,www.fourmindstech.com.br,44.205.204.166
DATABASE_URL=postgresql://agendamento_user:4MindsAgendamento2025!SecureDB#Pass@s-agendamento-db.cgr24gyuwi3d.us-east-1.rds.amazonaws.com:5432/agendamento_db
EOF

echo "🗄️ Executando migrações do banco..."
python manage.py migrate

echo "👤 Criando usuário administrador..."
python manage.py shell -c "
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser('admin', 'admin@fourmindstech.com.br', 'admin123')
    print('Superusuário criado!')
else:
    print('Superusuário já existe!')
"

echo "📦 Coletando arquivos estáticos..."
python manage.py collectstatic --noinput

echo "🌐 Configurando Nginx..."
sudo tee /etc/nginx/sites-available/agendamento > /dev/null << 'NGINXEOF'
server {
    listen 80;
    server_name fourmindstech.com.br www.fourmindstech.com.br 44.205.204.166;
    
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
}
NGINXEOF

sudo ln -sf /etc/nginx/sites-available/agendamento /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx

echo "🔧 Configurando Gunicorn como serviço..."
sudo tee /etc/systemd/system/gunicorn.service > /dev/null << 'GUNICORNEOF'
[Unit]
Description=Gunicorn daemon for Django
After=network.target

[Service]
User=ubuntu
Group=www-data
WorkingDirectory=/var/www/agendamento
Environment="PATH=/var/www/agendamento/venv/bin"
ExecStart=/var/www/agendamento/venv/bin/gunicorn --workers 3 --bind 127.0.0.1:8000 core.wsgi:application

[Install]
WantedBy=multi-user.target
GUNICORNEOF

sudo systemctl daemon-reload
sudo systemctl start gunicorn
sudo systemctl enable gunicorn

echo ""
echo "✅ Deploy concluído com sucesso!"
echo "🌐 Website: http://fourmindstech.com.br"
echo "👤 Admin: http://fourmindstech.com.br/admin/"
echo "📝 Usuário: admin | Senha: admin123"
'@

# Salvar script bash
$bashScript | Out-File -FilePath "setup.sh" -Encoding UTF8

Write-Host "`n📤 Enviando script para o servidor..." -ForegroundColor Cyan

# Usar WSL para transferir arquivo
wsl scp -i ~/.ssh/s-agendamento-key.pem setup.sh ${EC2_USER}@${EC2_IP}:/home/ubuntu/

Write-Host "`n🚀 Executando deploy no servidor..." -ForegroundColor Cyan

# Executar via WSL
wsl ssh -i ~/.ssh/s-agendamento-key.pem ${EC2_USER}@${EC2_IP} "chmod +x setup.sh && ./setup.sh"

# Limpar arquivo temporário
Remove-Item setup.sh -Force -ErrorAction SilentlyContinue

Write-Host "`n✅ Deploy completo!" -ForegroundColor Green
Write-Host "`n🌐 Acesse o website:" -ForegroundColor Cyan
Write-Host "   http://fourmindstech.com.br" -ForegroundColor White
Write-Host "   http://44.205.204.166" -ForegroundColor White
Write-Host "`n👤 Admin:" -ForegroundColor Cyan
Write-Host "   http://fourmindstech.com.br/admin/" -ForegroundColor White
Write-Host "   Usuário: admin | Senha: admin123" -ForegroundColor Yellow
