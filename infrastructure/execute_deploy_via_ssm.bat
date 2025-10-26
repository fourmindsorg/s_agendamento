@echo off
echo === EXECUTANDO DEPLOY VIA AWS SSM ===

echo 1. Enviando script para o servidor...
aws ssm send-command --instance-ids "i-000e6aecf9ad53679" --document-name "AWS-RunShellScript" --parameters 'commands=["curl -o /tmp/deploy_django_complete.sh https://raw.githubusercontent.com/your-repo/deploy_django_complete.sh"]'

echo.
echo 2. Aguardando 30 segundos...
timeout /t 30 /nobreak

echo.
echo 3. Executando script de deploy...
aws ssm send-command --instance-ids "i-000e6aecf9ad53679" --document-name "AWS-RunShellScript" --parameters 'commands=["chmod +x /tmp/deploy_django_complete.sh", "sudo bash /tmp/deploy_django_complete.sh"]'

echo.
echo 4. Verificando status do comando...
aws ssm list-command-invocations --instance-id "i-000e6aecf9ad53679" --query "CommandInvocations[*].[CommandId,Status,StatusDetails]" --output table

echo.
echo === DEPLOY INICIADO VIA SSM ===
echo.
echo Para verificar o progresso:
echo aws ssm get-command-invocation --command-id [COMMAND_ID] --instance-id i-000e6aecf9ad53679
echo.
pause
