# Script PowerShell para acessar console EC2
Write-Host "🚀 ACESSANDO CONSOLE EC2" -ForegroundColor Green
Write-Host "========================" -ForegroundColor Green

# Procurar instância EC2
Write-Host "🔍 Procurando instância EC2..." -ForegroundColor Yellow

try {
    $instanceId = aws ec2 describe-instances --filters "Name=ip-address,Values=3.80.178.120" --query "Reservations[*].Instances[*].InstanceId" --output text
    
    if ([string]::IsNullOrEmpty($instanceId)) {
        Write-Host "❌ Instância não encontrada com IP 3.80.178.120" -ForegroundColor Red
        Write-Host "🔍 Tentando buscar por nome..." -ForegroundColor Yellow
        $instanceId = aws ec2 describe-instances --filters "Name=tag:Name,Values=agendamento-4minds-web-server" --query "Reservations[*].Instances[*].InstanceId" --output text
    }
    
    if ([string]::IsNullOrEmpty($instanceId)) {
        Write-Host "❌ Instância não encontrada. Listando todas as instâncias..." -ForegroundColor Red
        aws ec2 describe-instances --query "Reservations[*].Instances[?State.Name=='running'].[InstanceId,PublicIpAddress,Tags[?Key=='Name'].Value|[0]]" --output table
        Read-Host "Pressione Enter para continuar"
        exit 1
    }
    
    Write-Host "✅ Instância encontrada: $instanceId" -ForegroundColor Green
    
    # Abrir console AWS EC2
    Write-Host "🌐 Abrindo console AWS EC2 no navegador..." -ForegroundColor Yellow
    Start-Process "https://console.aws.amazon.com/ec2/"
    
    # Aguardar um pouco para o navegador abrir
    Start-Sleep -Seconds 2
    
    # Tentar abrir diretamente a instância (pode não funcionar em todos os navegadores)
    Write-Host "🔗 Tentando abrir instância diretamente..." -ForegroundColor Yellow
    $instanceUrl = "https://console.aws.amazon.com/ec2/home?region=us-east-1#Instances:instanceId=$instanceId"
    Start-Process $instanceUrl
    
    Write-Host ""
    Write-Host "📋 INFORMAÇÕES DA INSTÂNCIA:" -ForegroundColor Cyan
    Write-Host "============================" -ForegroundColor Cyan
    Write-Host "Instance ID: $instanceId" -ForegroundColor White
    Write-Host "IP Público: 3.80.178.120" -ForegroundColor White
    Write-Host ""
    
    Write-Host "🎯 COMO CONECTAR:" -ForegroundColor Cyan
    Write-Host "================" -ForegroundColor Cyan
    Write-Host "1. Acesse: https://console.aws.amazon.com/ec2/" -ForegroundColor White
    Write-Host "2. Vá para 'Instances' no menu lateral" -ForegroundColor White
    Write-Host "3. Selecione a instância: $instanceId" -ForegroundColor White
    Write-Host "4. Clique em 'Connect'" -ForegroundColor White
    Write-Host "5. Escolha 'EC2 Instance Connect'" -ForegroundColor White
    Write-Host "6. Clique em 'Connect'" -ForegroundColor White
    Write-Host ""
    
    Write-Host "🚀 COMANDOS PARA EXECUTAR NO CONSOLE:" -ForegroundColor Cyan
    Write-Host "=====================================" -ForegroundColor Cyan
    Write-Host "curl -s https://raw.githubusercontent.com/fourmindsorg/s_agendamento/main/deploy_completo_console.sh | bash" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "🌐 URLs APÓS DEPLOY:" -ForegroundColor Cyan
    Write-Host "===================" -ForegroundColor Cyan
    Write-Host "IP: http://3.80.178.120" -ForegroundColor White
    Write-Host "Domínio: http://fourmindstech.com.br (após configurar DNS)" -ForegroundColor White
    Write-Host "Admin: http://3.80.178.120/admin" -ForegroundColor White
    Write-Host "Usuário: admin | Senha: admin123" -ForegroundColor White
    Write-Host ""
    
    # Tentar executar comando via AWS CLI (pode não funcionar)
    Write-Host "🔧 Tentando executar comando via AWS CLI..." -ForegroundColor Yellow
    try {
        $commandId = aws ssm send-command --instance-ids $instanceId --document-name "AWS-RunShellScript" --parameters "commands=[\"echo 'Console EC2 acessado via AWS CLI'\",\"pwd\",\"whoami\"]" --output text --query "Command.CommandId"
        if ($commandId) {
            Write-Host "✅ Comando enviado via AWS CLI: $commandId" -ForegroundColor Green
            Write-Host "⏳ Aguardando execução..." -ForegroundColor Yellow
            Start-Sleep -Seconds 5
            Write-Host "📋 Resultado:" -ForegroundColor Cyan
            aws ssm get-command-invocation --command-id $commandId --instance-id $instanceId --query "StandardOutputContent" --output text
        }
    } catch {
        Write-Host "❌ AWS CLI não conseguiu executar comando (normal)" -ForegroundColor Red
    }
    
} catch {
    Write-Host "❌ Erro ao acessar console EC2: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "🎉 Script concluído!" -ForegroundColor Green
Read-Host "Pressione Enter para sair"
