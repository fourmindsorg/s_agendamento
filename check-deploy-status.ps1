# Script para verificar status do deploy
Write-Host "🔍 Verificando status do deploy..." -ForegroundColor Yellow
Write-Host ""

# Verificar se Terraform está rodando
$terraformProcess = Get-Process terraform -ErrorAction SilentlyContinue
if ($terraformProcess) {
    Write-Host "✅ Terraform está executando (PID: $($terraformProcess.Id))" -ForegroundColor Green
    Write-Host "⏱️  Tempo de execução: $([math]::Round(($terraformProcess.CPU), 2)) segundos" -ForegroundColor Cyan
} else {
    Write-Host "⚠️  Terraform não está executando" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "📊 Verificando recursos na AWS..." -ForegroundColor Yellow
Write-Host ""

# Verificar VPC
Write-Host "1. VPC:" -ForegroundColor Cyan
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=sistema-agendamento-4minds-vpc" --query "Vpcs[0].VpcId" --output text 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✅ VPC criada" -ForegroundColor Green
} else {
    Write-Host "   ⏳ VPC ainda não criada" -ForegroundColor Yellow
}

# Verificar EC2
Write-Host "2. EC2:" -ForegroundColor Cyan
$ec2Id = aws ec2 describe-instances --filters "Name=tag:Name,Values=sistema-agendamento-4minds-web-server" "Name=instance-state-name,Values=pending,running" --query "Reservations[0].Instances[0].InstanceId" --output text 2>$null
if ($ec2Id -and $ec2Id -ne "None") {
    Write-Host "   ✅ EC2 criada: $ec2Id" -ForegroundColor Green
    
    # Ver estado da instância
    $state = aws ec2 describe-instances --instance-ids $ec2Id --query "Reservations[0].Instances[0].State.Name" --output text 2>$null
    Write-Host "   📊 Estado: $state" -ForegroundColor Cyan
    
    # Ver IP público
    $publicIp = aws ec2 describe-instances --instance-ids $ec2Id --query "Reservations[0].Instances[0].PublicIpAddress" --output text 2>$null
    if ($publicIp -and $publicIp -ne "None") {
        Write-Host "   🌐 IP Público: $publicIp" -ForegroundColor Green
    }
} else {
    Write-Host "   ⏳ EC2 ainda não criada" -ForegroundColor Yellow
}

# Verificar RDS
Write-Host "3. RDS:" -ForegroundColor Cyan
$rdsId = aws rds describe-db-instances --db-instance-identifier sistema-agendamento-4minds-postgres --query "DBInstances[0].DBInstanceStatus" --output text 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✅ RDS criado" -ForegroundColor Green
    Write-Host "   📊 Status: $rdsId" -ForegroundColor Cyan
} else {
    Write-Host "   ⏳ RDS ainda não criado" -ForegroundColor Yellow
}

# Verificar S3
Write-Host "4. S3 Bucket:" -ForegroundColor Cyan
$s3Bucket = aws s3 ls | Select-String "sistema-agendamento-4minds-static" 2>$null
if ($s3Bucket) {
    Write-Host "   ✅ S3 Bucket criado" -ForegroundColor Green
} else {
    Write-Host "   ⏳ S3 Bucket ainda não criado" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🏁 Verificação concluída!" -ForegroundColor Green
Write-Host ""
Write-Host "💡 Execute novamente este script para ver o progresso" -ForegroundColor Cyan
Write-Host "   .\check-deploy-status.ps1" -ForegroundColor White

