# Script para corrigir configuração do Nginx para arquivos estáticos
Write-Host "🔧 Corrigindo configuração do Nginx..." -ForegroundColor Yellow

# 1. Copiar arquivo de configuração corrigido
Write-Host "📁 Copiando configuração do Nginx..." -ForegroundColor Cyan
scp -i $env:USERPROFILE\.ssh\id_rsa_github -o StrictHostKeyChecking=no nginx-django-fixed.conf ubuntu@13.223.47.98:/tmp/nginx-django-fixed.conf

# 2. Aplicar nova configuração
Write-Host "⚙️ Aplicando nova configuração..." -ForegroundColor Cyan
ssh -i $env:USERPROFILE\.ssh\id_rsa_github -o StrictHostKeyChecking=no ubuntu@13.223.47.98 "sudo cp /tmp/nginx-django-fixed.conf /etc/nginx/sites-available/django && sudo ln -sf /etc/nginx/sites-available/django /etc/nginx/sites-enabled/ && sudo nginx -t"

# 3. Criar diretório de arquivos estáticos se não existir
Write-Host "📂 Criando diretório de arquivos estáticos..." -ForegroundColor Cyan
ssh -i $env:USERPROFILE\.ssh\id_rsa_github -o StrictHostKeyChecking=no ubuntu@13.223.47.98 "sudo mkdir -p /home/django/sistema-de-agendamento/staticfiles && sudo chown -R www-data:www-data /home/django/sistema-de-agendamento/staticfiles && sudo chmod -R 755 /home/django/sistema-de-agendamento/staticfiles"

# 4. Coletar arquivos estáticos
Write-Host "📦 Coletando arquivos estáticos..." -ForegroundColor Cyan
ssh -i $env:USERPROFILE\.ssh\id_rsa_github -o StrictHostKeyChecking=no ubuntu@13.223.47.98 "sudo -u django bash -c 'cd /home/django/sistema-de-agendamento && source venv/bin/activate && export DJANGO_SETTINGS_MODULE=core.settings_production && export DB_NAME=agendamentos_db && export DB_USER=postgres && export DB_PASSWORD=senha_segura_postgre && export DB_HOST=sistema-agendamento-4minds-postgres.cgr24gyuwi3d.us-east-1.rds.amazonaws.com && export DB_PORT=5432 && export ALLOWED_HOSTS=* && python manage.py collectstatic --noinput'"

# 5. Reiniciar Nginx
Write-Host "🔄 Reiniciando Nginx..." -ForegroundColor Cyan
ssh -i $env:USERPROFILE\.ssh\id_rsa_github -o StrictHostKeyChecking=no ubuntu@13.223.47.98 "sudo systemctl restart nginx"

# 6. Testar arquivos estáticos
Write-Host "🧪 Testando arquivos estáticos..." -ForegroundColor Cyan
Start-Sleep -Seconds 5
try {
    $response = Invoke-WebRequest -Uri http://13.223.47.98/static/admin/css/base.css -Method Get
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ Arquivos estáticos funcionando!" -ForegroundColor Green
        Write-Host "🎨 CSS do admin deve estar funcionando agora!" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Ainda com problema (Status: $($response.StatusCode))" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Erro: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "🏁 Correção concluída!" -ForegroundColor Green

