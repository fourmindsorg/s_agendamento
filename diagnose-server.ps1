# Script para diagnosticar problemas no servidor
Write-Host "🔍 Diagnosticando servidor..." -ForegroundColor Yellow

# 1. Testar conectividade básica
Write-Host "1. Testando conectividade..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri http://fourmindstech.com.br/agendamento/ -Method Get
    Write-Host "✅ Servidor respondendo (Status: $($response.StatusCode))" -ForegroundColor Green
} catch {
    Write-Host "❌ Servidor não responde: $($_.Exception.Message)" -ForegroundColor Red
}

# 2. Testar admin
Write-Host "2. Testando admin..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri http://fourmindstech.com.br/agendamento/admin/ -Method Get
    Write-Host "✅ Admin acessível (Status: $($response.StatusCode))" -ForegroundColor Green
} catch {
    Write-Host "❌ Admin não acessível: $($_.Exception.Message)" -ForegroundColor Red
}

# 3. Testar arquivos estáticos
Write-Host "3. Testando arquivos estáticos..." -ForegroundColor Cyan
$staticFiles = @(
    "/agendamento/static/admin/css/base.css",
    "/agendamento/static/admin/css/login.css",
    "/agendamento/static/css/style.css"
)

foreach ($file in $staticFiles) {
    try {
        $response = Invoke-WebRequest -Uri "http://fourmindstech.com.br$file" -Method Get
        Write-Host "✅ $file (Status: $($response.StatusCode))" -ForegroundColor Green
    } catch {
        Write-Host "❌ $file (Erro: $($_.Exception.Message))" -ForegroundColor Red
    }
}

# 4. Verificar se é problema de cache
Write-Host "4. Testando com cache bypass..." -ForegroundColor Cyan
try {
    $headers = @{
        'Cache-Control' = 'no-cache'
        'Pragma' = 'no-cache'
    }
    $response = Invoke-WebRequest -Uri http://fourmindstech.com.br/agendamento/static/admin/css/base.css -Method Get -Headers $headers
    Write-Host "✅ Arquivo estático com cache bypass (Status: $($response.StatusCode))" -ForegroundColor Green
} catch {
    Write-Host "❌ Arquivo estático ainda com problema: $($_.Exception.Message)" -ForegroundColor Red
}

# 5. Verificar se o problema é no Nginx ou Django
Write-Host "5. Testando se Django está servindo arquivos..." -ForegroundColor Cyan
try {
    # Tentar acessar via porta 8000 (Django direto)
    $response = Invoke-WebRequest -Uri http://fourmindstech.com.br:8000/agendamento/static/admin/css/base.css -Method Get
    Write-Host "✅ Django servindo arquivos estáticos (Status: $($response.StatusCode))" -ForegroundColor Green
} catch {
    Write-Host "❌ Django não está servindo arquivos estáticos: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "🏁 Diagnóstico concluído!" -ForegroundColor Green

