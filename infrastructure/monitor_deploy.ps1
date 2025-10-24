# Monitor do Deploy da Aplicação Django
Write-Host "🔍 Monitorando o deploy da aplicação Django..." -ForegroundColor Cyan

$INSTANCE_ID = "i-0bb8edf79961f187a"
$WEBSITE_URL = "http://fourmindstech.com.br"
$IP_URL = "http://44.205.204.166"

Write-Host "`n📊 Verificando status da instância EC2..." -ForegroundColor Yellow

# Verificar status da instância
$instance_status = aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[0].Instances[0].State.Name" --output text
$public_ip = aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[0].Instances[0].PublicIpAddress" --output text

Write-Host "Status da Instância: $instance_status" -ForegroundColor Cyan
Write-Host "IP Público: $public_ip" -ForegroundColor Cyan

if ($instance_status -eq "running") {
    Write-Host "`n✅ Instância EC2 está rodando!" -ForegroundColor Green
    
    Write-Host "`n🌐 Testando acessibilidade do website..." -ForegroundColor Yellow
    
    # Testar acessibilidade via IP
    try {
        $response = Invoke-WebRequest -Uri $IP_URL -TimeoutSec 10 -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            Write-Host "✅ Website acessível via IP: $IP_URL" -ForegroundColor Green
        }
    } catch {
        Write-Host "⏳ Website ainda não está acessível via IP. Aguardando..." -ForegroundColor Yellow
    }
    
    # Testar acessibilidade via domínio
    try {
        $response = Invoke-WebRequest -Uri $WEBSITE_URL -TimeoutSec 10 -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            Write-Host "✅ Website acessível via domínio: $WEBSITE_URL" -ForegroundColor Green
        }
    } catch {
        Write-Host "⏳ Website ainda não está acessível via domínio. Aguardando..." -ForegroundColor Yellow
    }
    
    Write-Host "`n📝 Próximos passos:" -ForegroundColor Cyan
    Write-Host "1. Aguarde 5-10 minutos para o Django ser instalado completamente" -ForegroundColor White
    Write-Host "2. O user_data está executando: instalação de dependências, migrações, etc." -ForegroundColor White
    Write-Host "3. Teste manualmente: $WEBSITE_URL" -ForegroundColor White
    
} else {
    Write-Host "`n⏳ Instância ainda está inicializando..." -ForegroundColor Yellow
    Write-Host "Status atual: $instance_status" -ForegroundColor Cyan
}

Write-Host "`n🔗 Links para testar:" -ForegroundColor Cyan
Write-Host "Website: $WEBSITE_URL" -ForegroundColor White
Write-Host "Admin: $WEBSITE_URL/admin/" -ForegroundColor White
Write-Host "IP Direto: $IP_URL" -ForegroundColor White
Write-Host "`n👤 Credenciais:" -ForegroundColor Cyan
Write-Host "Usuário: admin" -ForegroundColor White
Write-Host "Senha: admin123" -ForegroundColor White
