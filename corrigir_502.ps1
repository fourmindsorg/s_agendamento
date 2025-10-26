# Script PowerShell para corrigir erro 502

Write-Host "🔧 Enviando comandos para reiniciar serviços..." -ForegroundColor Yellow

# Enviar comando via SSM
$result = aws ssm send-command `
  --instance-ids i-0077873407e4114b1 `
  --document-name "AWS-RunShellScript" `
  --parameters commands=@("cd /opt/s-agendamento", "sudo supervisorctl restart s-agendamento", "sudo systemctl reload nginx") `
  --query 'Command.CommandId' `
  --output text

if ($result) {
    Write-Host "✅ Comando enviado: $result" -ForegroundColor Green
    Write-Host "⏳ Aguardando 30 segundos..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30
    
    Write-Host "📊 Verificando resultado..." -ForegroundColor Cyan
    aws ssm get-command-invocation `
      --command-id $result `
      --instance-id i-0077873407e4114b1 `
      --query 'StandardOutputContent' `
      --output text
    
    Write-Host ""
    Write-Host "✅ Pronto! Teste agora: https://fourmindstech.com.br/s_agendamentos/" -ForegroundColor Green
} else {
    Write-Host "❌ Erro ao enviar comando" -ForegroundColor Red
    Write-Host "💡 Use o console web da AWS: https://console.aws.amazon.com/ec2/" -ForegroundColor Yellow
}

