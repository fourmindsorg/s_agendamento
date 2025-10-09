# Script para corrigir arquivos estáticos
Write-Host "🔧 Corrigindo arquivos estáticos..." -ForegroundColor Yellow

# 1. Parar Gunicorn
Write-Host "⏹️ Parando Gunicorn..." -ForegroundColor Yellow
ssh -i $env:USERPROFILE\.ssh\id_rsa_github -o StrictHostKeyChecking=no ubuntu@13.223.47.98 "sudo pkill -f gunicorn"

# 2. Coletar arquivos estáticos
Write-Host "📦 Coletando arquivos estáticos..." -ForegroundColor Yellow
ssh -i $env:USERPROFILE\.ssh\id_rsa_github -o StrictHostKeyChecking=no ubuntu@13.223.47.98 "sudo -u django bash -c 'cd /home/django/sistema-de-agendamento && source venv/bin/activate && export DJANGO_SETTINGS_MODULE=core.settings_production && export DB_NAME=agendamentos_db && export DB_USER=postgres && export DB_PASSWORD=senha_segura_postgre && export DB_HOST=sistema-agendamento-4minds-postgres.cgr24gyuwi3d.us-east-1.rds.amazonaws.com && export DB_PORT=5432 && export ALLOWED_HOSTS=* && python manage.py collectstatic --noinput --settings=core.settings_production'"

# 3. Verificar se os arquivos foram coletados
Write-Host "🔍 Verificando arquivos estáticos..." -ForegroundColor Yellow
ssh -i $env:USERPROFILE\.ssh\id_rsa_github -o StrictHostKeyChecking=no ubuntu@13.223.47.98 "sudo -u django ls -la /home/django/sistema-de-agendamento/staticfiles/"

# 4. Corrigir permissões
Write-Host "🔐 Corrigindo permissões..." -ForegroundColor Yellow
ssh -i $env:USERPROFILE\.ssh\id_rsa_github -o StrictHostKeyChecking=no ubuntu@13.223.47.98 "sudo chown -R www-data:www-data /home/django/sistema-de-agendamento/staticfiles/ && sudo chmod -R 755 /home/django/sistema-de-agendamento/staticfiles/"

# 5. Verificar configuração do Nginx
Write-Host "🌐 Verificando configuração do Nginx..." -ForegroundColor Yellow
ssh -i $env:USERPROFILE\.ssh\id_rsa_github -o StrictHostKeyChecking=no ubuntu@13.223.47.98 "sudo cat /etc/nginx/sites-enabled/django | grep -A 5 'location /static/'"

# 6. Reiniciar Nginx
Write-Host "🔄 Reiniciando Nginx..." -ForegroundColor Yellow
ssh -i $env:USERPROFILE\.ssh\id_rsa_github -o StrictHostKeyChecking=no ubuntu@13.223.47.98 "sudo systemctl restart nginx"

# 7. Iniciar Gunicorn
Write-Host "🚀 Iniciando Gunicorn..." -ForegroundColor Yellow
ssh -i $env:USERPROFILE\.ssh\id_rsa_github -o StrictHostKeyChecking=no ubuntu@13.223.47.98 "sudo -u django bash -c 'cd /home/django/sistema-de-agendamento && source venv/bin/activate && export DJANGO_SETTINGS_MODULE=core.settings_production && export DB_NAME=agendamentos_db && export DB_USER=postgres && export DB_PASSWORD=senha_segura_postgre && export DB_HOST=sistema-agendamento-4minds-postgres.cgr24gyuwi3d.us-east-1.rds.amazonaws.com && export DB_PORT=5432 && export ALLOWED_HOSTS=* && gunicorn --bind 127.0.0.1:8000 core.wsgi:application --daemon'"

# 8. Testar arquivos estáticos
Write-Host "🧪 Testando arquivos estáticos..." -ForegroundColor Yellow
Start-Sleep -Seconds 5
try {
    $response = Invoke-WebRequest -Uri http://13.223.47.98/static/admin/css/base.css -Method Get
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ Arquivos estáticos funcionando!" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Arquivos estáticos ainda com problema (Status: $($response.StatusCode))" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Erro ao testar arquivos estáticos: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "🏁 Correção concluída!" -ForegroundColor Green

