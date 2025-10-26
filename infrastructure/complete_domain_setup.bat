@echo off
echo === CONFIGURAÇÃO COMPLETA DO DOMÍNIO FOURMINDSTECH.COM.BR ===

REM 1. Verificar status da instância EC2
echo 1. Verificando status da instância EC2...
aws ec2 describe-instances --instance-ids i-000e6aecf9ad53679 --query "Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress]" --output table

REM 2. Iniciar instância se estiver parada
echo.
echo 2. Iniciando instância se necessário...
aws ec2 start-instances --instance-ids i-000e6aecf9ad53679

REM 3. Aguardar instância ficar disponível
echo.
echo 3. Aguardando instância ficar disponível (2 minutos)...
timeout /t 120 /nobreak

REM 4. Verificar IP público
echo.
echo 4. Verificando IP público da instância...
for /f "tokens=3" %%i in ('aws ec2 describe-instances --instance-ids i-000e6aecf9ad53679 --query "Reservations[*].Instances[*].PublicIpAddress" --output text') do set EC2_IP=%%i
echo IP da instância: %EC2_IP%

REM 5. Listar hosted zones
echo.
echo 5. Listando hosted zones do Route53...
aws route53 list-hosted-zones --query "HostedZones[*].[Id,Name]" --output table

REM 6. Criar arquivo de configuração Route53
echo.
echo 6. Criando configuração Route53...
call create_route53_records.bat

echo.
echo === PRÓXIMOS PASSOS ===
echo.
echo 1. Obtenha o ID da hosted zone para fourmindstech.com.br
echo 2. Execute o comando Route53 com o ID correto
echo 3. Conecte via SSH e configure o Nginx e SSL
echo.
echo Comandos para executar no servidor EC2:
echo ssh -i s-agendamento-key.pem ubuntu@%EC2_IP%
echo sudo bash /opt/s-agendamento/configure_nginx_redirect.sh
echo sudo bash /opt/s-agendamento/setup_ssl_certificate.sh
echo.
echo === CONFIGURAÇÃO INICIADA ===
pause
