# Deploy da aplicação Django via AWS CLI
Write-Host "🚀 Deploy da aplicação Django na AWS EC2" -ForegroundColor Cyan

$EC2_IP = "44.205.204.166"
$EC2_USER = "ubuntu"

Write-Host "`n📝 Verificando chave SSH..." -ForegroundColor Yellow
$sshKeyPath = "$env:USERPROFILE\.ssh\s-agendamento-key.pem"

if (-not (Test-Path $sshKeyPath)) {
    Write-Host "Criando chave SSH..." -ForegroundColor Yellow
    aws ec2 create-key-pair --key-name s-agendamento-key --query 'KeyMaterial' --output text | Out-File -FilePath $sshKeyPath -Encoding ASCII
    Write-Host "✅ Chave criada" -ForegroundColor Green
}

Write-Host "`n📤 Enviando comandos para o servidor..." -ForegroundColor Cyan

# Criar script bash simples
$bashCommands = @"
sudo apt-get update -y
sudo apt-get install -y python3 python3-pip python3-venv nginx git
sudo mkdir -p /var/www/agendamento
sudo chown -R ubuntu:ubuntu /var/www/agendamento
cd /var/www/agendamento
git clone https://github.com/fourmindsorg/s_agendamento.git . || true
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt gunicorn
echo 'DEBUG=False' > .env
echo 'SECRET_KEY=django-insecure-4minds-agendamento-2025-super-secret-key' >> .env
echo 'ALLOWED_HOSTS=fourmindstech.com.br,www.fourmindstech.com.br,44.205.204.166' >> .env
python manage.py migrate
python manage.py shell -c "from django.contrib.auth import get_user_model; User = get_user_model(); User.objects.create_superuser('admin', 'admin@fourmindstech.com.br', 'admin123') if not User.objects.filter(username='admin').exists() else None"
python manage.py collectstatic --noinput
sudo tee /etc/nginx/sites-available/agendamento > /dev/null << 'EOF'
server {
    listen 80;
    server_name fourmindstech.com.br www.fourmindstech.com.br 44.205.204.166;
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
    location /static/ {
        alias /var/www/agendamento/staticfiles/;
    }
}
EOF
sudo ln -sf /etc/nginx/sites-available/agendamento /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx
sudo tee /etc/systemd/system/gunicorn.service > /dev/null << 'EOF'
[Unit]
Description=Gunicorn daemon
After=network.target
[Service]
User=ubuntu
Group=www-data
WorkingDirectory=/var/www/agendamento
Environment="PATH=/var/www/agendamento/venv/bin"
ExecStart=/var/www/agendamento/venv/bin/gunicorn --workers 3 --bind 127.0.0.1:8000 core.wsgi:application
[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl start gunicorn
sudo systemctl enable gunicorn
echo "✅ Deploy concluído!"
"@

# Salvar script
$bashCommands | Out-File -FilePath "deploy.sh" -Encoding UTF8

Write-Host "`n🚀 Executando deploy..." -ForegroundColor Cyan

# Executar via WSL
wsl bash -c "scp -i ~/.ssh/s-agendamento-key.pem deploy.sh ${EC2_USER}@${EC2_IP}:/home/ubuntu/ && ssh -i ~/.ssh/s-agendamento-key.pem ${EC2_USER}@${EC2_IP} 'chmod +x deploy.sh && ./deploy.sh'"

# Limpar
Remove-Item deploy.sh -Force -ErrorAction SilentlyContinue

Write-Host "`n✅ Deploy completo!" -ForegroundColor Green
Write-Host "🌐 Website: http://fourmindstech.com.br" -ForegroundColor Cyan
Write-Host "👤 Admin: http://fourmindstech.com.br/admin/" -ForegroundColor Cyan
Write-Host "📝 Usuário: admin | Senha: admin123" -ForegroundColor Yellow
