# Script de Deploy via SCP
# Copia arquivos locais para o servidor

Write-Host "🚀 Iniciando Deploy via SCP..." -ForegroundColor Green

# 1. Parar serviços
Write-Host "⏹️ Parando serviços..." -ForegroundColor Yellow
ssh -i $env:USERPROFILE\.ssh\id_rsa_github -o StrictHostKeyChecking=no ubuntu@13.223.47.98 "sudo pkill -f gunicorn"

# 2. Copiar arquivo settings_production.py corrigido
Write-Host "📁 Copiando arquivos..." -ForegroundColor Yellow
scp -i $env:USERPROFILE\.ssh\id_rsa_github -o StrictHostKeyChecking=no core/settings_production.py ubuntu@13.223.47.98:/tmp/settings_production.py

# 3. Mover arquivo para o local correto
Write-Host "📝 Instalando arquivo..." -ForegroundColor Yellow
ssh -i $env:USERPROFILE\.ssh\id_rsa_github -o StrictHostKeyChecking=no ubuntu@13.223.47.98 "sudo mv /tmp/settings_production.py /home/django/sistema-de-agendamento/core/settings_production.py && sudo chown django:django /home/django/sistema-de-agendamento/core/settings_production.py"

# 4. Executar migrações
Write-Host "🗄️ Executando migrações..." -ForegroundColor Yellow
ssh -i $env:USERPROFILE\.ssh\id_rsa_github -o StrictHostKeyChecking=no ubuntu@13.223.47.98 "sudo -u django bash -c 'cd /home/django/sistema-de-agendamento && source venv/bin/activate && export DJANGO_SETTINGS_MODULE=core.settings_production && export DB_NAME=agendamentos_db && export DB_USER=postgres && export DB_PASSWORD=MinhaSenhaSegura123 && export DB_HOST=sistema-agendamento-4minds-postgres.cgr24gyuwi3d.us-east-1.rds.amazonaws.com && export DB_PORT=5432 && export ALLOWED_HOSTS=* && python manage.py migrate --settings=core.settings_production'"

# 5. Iniciar Gunicorn
Write-Host "🚀 Iniciando Gunicorn..." -ForegroundColor Yellow
ssh -i $env:USERPROFILE\.ssh\id_rsa_github -o StrictHostKeyChecking=no ubuntu@13.223.47.98 "sudo -u django bash -c 'cd /home/django/sistema-de-agendamento && source venv/bin/activate && export DJANGO_SETTINGS_MODULE=core.settings_production && export DB_NAME=agendamentos_db && export DB_USER=postgres && export DB_PASSWORD=MinhaSenhaSegura123 && export DB_HOST=sistema-agendamento-4minds-postgres.cgr24gyuwi3d.us-east-1.rds.amazonaws.com && export DB_PORT=5432 && export ALLOWED_HOSTS=* && gunicorn --bind 127.0.0.1:8000 core.wsgi:application --daemon'"

# 6. Testar aplicação
Write-Host "🧪 Testando aplicação..." -ForegroundColor Yellow
Start-Sleep -Seconds 5
try {
    $response = Invoke-WebRequest -Uri http://13.223.47.98 -Method Get -TimeoutSec 10
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ Deploy realizado com sucesso!" -ForegroundColor Green
        Write-Host "🌐 Aplicação disponível em: http://13.223.47.98" -ForegroundColor Cyan
    } else {
        Write-Host "⚠️ Aplicação retornou status: $($response.StatusCode)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Erro ao testar aplicação: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "🏁 Deploy concluído!" -ForegroundColor Green
