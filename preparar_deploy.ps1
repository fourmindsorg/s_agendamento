# Script para preparar deploy para produção

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "📦 PREPARANDO DEPLOY PARA PRODUÇÃO" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# Verificar se está no diretório correto
if (-not (Test-Path "manage.py")) {
    Write-Host "❌ ERRO: Execute este script na raiz do projeto!" -ForegroundColor Red
    Write-Host "   Caminho esperado: c:\PROJETOS\TRABALHOS\STARTUP\4Minds\Sistemas\s_agendamento" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Diretório correto: $(Get-Location)" -ForegroundColor Green
Write-Host ""

# Verificar mudanças não commitadas
Write-Host "📋 Verificando mudanças locais..." -ForegroundColor Yellow
$uncommitted = git status --porcelain

if ($uncommitted) {
    Write-Host "⚠️  Há mudanças não commitadas:" -ForegroundColor Yellow
    git status --short
    Write-Host ""
    $commit = Read-Host "Deseja fazer commit? (S/N)"
    if ($commit -eq "S") {
        $msg = Read-Host "Digite a mensagem do commit"
        git add .
        git commit -m $msg
        Write-Host "✅ Commit realizado!" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "📦 Criando arquivo ZIP para deploy..." -ForegroundColor Yellow

# Criar arquivo ZIP
$date = Get-Date -Format "yyyyMMdd_HHmmss"
$zipName = "deploy_$date.zip"

$filesToZip = @(
    "agendamentos",
    "authentication", 
    "core",
    "financeiro",
    "info",
    "templates",
    "static",
    "manage.py",
    "requirements.txt",
    "pytest.ini",
    "README.md"
)

# Verificar quais existem
$existingFiles = @()
foreach ($file in $filesToZip) {
    if (Test-Path $file) {
        $existingFiles += $file
    }
}

if ($existingFiles.Count -eq 0) {
    Write-Host "❌ Nenhum arquivo encontrado!" -ForegroundColor Red
    exit 1
}

Compress-Archive -Path $existingFiles -DestinationPath $zipName -Force

Write-Host ""
Write-Host "✅ Arquivo criado: $zipName" -ForegroundColor Green
Write-Host ""

# Calcular tamanho
$fileSize = (Get-Item $zipName).Length / 1MB
Write-Host "📊 Tamanho: $([math]::Round($fileSize, 2)) MB" -ForegroundColor Cyan
Write-Host ""

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "📤 PRÓXIMOS PASSOS:" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1️⃣ Conectar no servidor:" -ForegroundColor Yellow
Write-Host "   https://console.aws.amazon.com/ec2/" -ForegroundColor White
Write-Host "   Instância: i-0077873407e4114b1" -ForegroundColor White
Write-Host "   Connect → EC2 Instance Connect" -ForegroundColor White
Write-Host ""
Write-Host "2️⃣ Fazer upload do arquivo: $zipName" -ForegroundColor Yellow
Write-Host ""
Write-Host "3️⃣ Extrair e aplicar:" -ForegroundColor Yellow
Write-Host "   unzip $zipName -d /tmp/deploy" -ForegroundColor White
Write-Host "   sudo cp -r /tmp/deploy/* /opt/s-agendamento/" -ForegroundColor White
Write-Host ""
Write-Host "4️⃣ Atualizar no servidor:" -ForegroundColor Yellow
Write-Host "   cd /opt/s-agendamento" -ForegroundColor White
Write-Host "   source venv/bin/activate" -ForegroundColor White
Write-Host "   pip install -r requirements.txt --upgrade" -ForegroundColor White
Write-Host "   python manage.py migrate" -ForegroundColor White
Write-Host "   python manage.py collectstatic --noinput" -ForegroundColor White
Write-Host "   sudo supervisorctl restart s-agendamento" -ForegroundColor White
Write-Host "   sudo systemctl reload nginx" -ForegroundColor White
Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan

# Abrir explorador no diretório atual
Start-Process explorer.exe "."

Write-Host ""
Write-Host "✅ Pronto! Arquivo ZIP foi criado." -ForegroundColor Green
Write-Host ""

