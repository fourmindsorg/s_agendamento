# Script de Deploy via AWS CLI
# Execute este script no Windows PowerShell

Write-Host "🚀 Iniciando deploy via AWS CLI..." -ForegroundColor Green

# Verificar se AWS CLI está configurado
Write-Host "🔍 Verificando configuração AWS CLI..." -ForegroundColor Yellow
try {
    $identity = aws sts get-caller-identity
    Write-Host "✅ AWS CLI configurado: $identity" -ForegroundColor Green
} catch {
    Write-Host "❌ AWS CLI não configurado. Configure primeiro com 'aws configure'" -ForegroundColor Red
    exit 1
}

# Encontrar instância EC2 pelo IP
Write-Host "🔍 Procurando instância EC2 com IP 3.80.178.120..." -ForegroundColor Yellow
$instanceId = aws ec2 describe-instances --filters "Name=ip-address,Values=3.80.178.120" --query "Reservations[*].Instances[*].InstanceId" --output text

if ($instanceId -eq "" -or $instanceId -eq $null) {
    Write-Host "❌ Instância não encontrada. Tentando buscar por nome..." -ForegroundColor Red
    
    # Tentar buscar por nome
    $instanceId = aws ec2 describe-instances --filters "Name=tag:Name,Values=agendamento-4minds-web-server" --query "Reservations[*].Instances[*].InstanceId" --output text
    
    if ($instanceId -eq "" -or $instanceId -eq $null) {
        Write-Host "❌ Instância não encontrada. Verifique se a instância está rodando." -ForegroundColor Red
        exit 1
    }
}

Write-Host "✅ Instância encontrada: $instanceId" -ForegroundColor Green

# Verificar se a instância está rodando
Write-Host "🔍 Verificando status da instância..." -ForegroundColor Yellow
$state = aws ec2 describe-instances --instance-ids $instanceId --query "Reservations[*].Instances[*].State.Name" --output text

if ($state -ne "running") {
    Write-Host "❌ Instância não está rodando. Status: $state" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Instância está rodando" -ForegroundColor Green

# Executar deploy via SSM
Write-Host "🚀 Executando deploy via AWS Systems Manager..." -ForegroundColor Yellow

$commandId = aws ssm send-command `
    --instance-ids $instanceId `
    --document-name "AWS-RunShellScript" `
    --parameters "commands=[`"cd /home/ubuntu/s_agendamento`",`"echo '📁 Diretório atual: $(pwd)'`",`"echo '📥 Fazendo pull do repositório...'`",`"git pull origin main`",`"echo '📦 Instalando dependências...'`",`"pip install -r requirements.txt`",`"echo '🗄️ Executando migrações...'`",`"python manage.py migrate`",`"echo '📁 Coletando arquivos estáticos...'`",`"python manage.py collectstatic --noinput`",`"echo '🔄 Reiniciando serviços...'`",`"sudo systemctl restart gunicorn`",`"sudo systemctl restart nginx`",`"echo '✅ Verificando status dos serviços...'`",`"sudo systemctl status gunicorn --no-pager`",`"sudo systemctl status nginx --no-pager`",`"echo '🌐 Testando aplicação...'`",`"curl -I http://localhost:8000/ || echo '❌ Aplicação não está respondendo'`",`"curl -I http://3.80.178.120/ || echo '❌ Aplicação não está acessível externamente'`",`"echo '🎉 Deploy concluído!'`",`"echo '🌐 Acesse: http://3.80.178.120'`",`"echo '🌐 Acesse: http://fourmindstech.com.br (após configurar DNS)'`"]" `
    --output text --query "Command.CommandId"

Write-Host "✅ Comando enviado. ID: $commandId" -ForegroundColor Green

# Aguardar execução
Write-Host "⏳ Aguardando execução do comando..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Verificar status do comando
Write-Host "🔍 Verificando status do comando..." -ForegroundColor Yellow
$status = aws ssm get-command-invocation --command-id $commandId --instance-id $instanceId --query "Status" --output text

Write-Host "📊 Status do comando: $status" -ForegroundColor Cyan

if ($status -eq "Success") {
    Write-Host "🎉 Deploy executado com sucesso!" -ForegroundColor Green
    Write-Host "🌐 Acesse: http://3.80.178.120" -ForegroundColor Cyan
    Write-Host "🌐 Acesse: http://fourmindstech.com.br (após configurar DNS)" -ForegroundColor Cyan
} else {
    Write-Host "❌ Deploy falhou. Status: $status" -ForegroundColor Red
    Write-Host "🔍 Verifique os logs para mais detalhes" -ForegroundColor Yellow
}

# Mostrar output do comando
Write-Host "📋 Output do comando:" -ForegroundColor Yellow
aws ssm get-command-invocation --command-id $commandId --instance-id $instanceId --query "StandardOutputContent" --output text

Write-Host "🚀 Deploy via AWS CLI concluído!" -ForegroundColor Green
