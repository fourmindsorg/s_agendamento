@echo off
echo === CONFIGURANDO ROUTE53 PARA FOURMINDSTECH.COM.BR ===

REM Verificar se a instância EC2 está rodando
echo 1. Verificando status da instância EC2...
aws ec2 describe-instances --instance-ids i-000e6aecf9ad53679 --query "Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress]" --output table

REM Aguardar se a instância estiver iniciando
echo.
echo 2. Aguardando instância ficar disponível...
timeout /t 60 /nobreak

REM Obter IP público da instância
echo.
echo 3. Obtendo IP público da instância...
for /f "tokens=3" %%i in ('aws ec2 describe-instances --instance-ids i-000e6aecf9ad53679 --query "Reservations[*].Instances[*].PublicIpAddress" --output text') do set EC2_IP=%%i

echo IP da instância EC2: %EC2_IP%

REM Listar hosted zones
echo.
echo 4. Listando hosted zones...
aws route53 list-hosted-zones --query "HostedZones[*].[Id,Name]" --output table

echo.
echo 5. Para configurar o Route53, você precisa:
echo    - ID da hosted zone para fourmindstech.com.br
echo    - Criar registro A apontando para %EC2_IP%
echo    - Configurar redirecionamento no Nginx

echo.
echo === CONFIGURAÇÃO ROUTE53 CONCLUÍDA ===
pause
