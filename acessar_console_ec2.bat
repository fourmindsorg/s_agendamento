@echo off
echo 🚀 ACESSANDO CONSOLE EC2
echo ========================

echo 🔍 Procurando instância EC2...
for /f "tokens=*" %%i in ('aws ec2 describe-instances --filters "Name=ip-address,Values=3.80.178.120" --query "Reservations[*].Instances[*].InstanceId" --output text') do set INSTANCE_ID=%%i

if "%INSTANCE_ID%"=="" (
    echo ❌ Instância não encontrada com IP 3.80.178.120
    echo 🔍 Tentando buscar por nome...
    for /f "tokens=*" %%i in ('aws ec2 describe-instances --filters "Name=tag:Name,Values=agendamento-4minds-web-server" --query "Reservations[*].Instances[*].InstanceId" --output text') do set INSTANCE_ID=%%i
)

if "%INSTANCE_ID%"=="" (
    echo ❌ Instância não encontrada. Listando todas as instâncias...
    aws ec2 describe-instances --query "Reservations[*].Instances[?State.Name=='running'].[InstanceId,PublicIpAddress,Tags[?Key=='Name'].Value|[0]]" --output table
    pause
    exit /b 1
)

echo ✅ Instância encontrada: %INSTANCE_ID%

echo 🌐 Abrindo console AWS EC2 no navegador...
start https://console.aws.amazon.com/ec2/

echo.
echo 📋 INFORMAÇÕES DA INSTÂNCIA:
echo ============================
echo Instance ID: %INSTANCE_ID%
echo IP Público: 3.80.178.120
echo.

echo 🎯 COMO CONECTAR:
echo ================
echo 1. Acesse: https://console.aws.amazon.com/ec2/
echo 2. Vá para "Instances" no menu lateral
echo 3. Selecione a instância: %INSTANCE_ID%
echo 4. Clique em "Connect"
echo 5. Escolha "EC2 Instance Connect"
echo 6. Clique em "Connect"
echo.

echo 🚀 COMANDOS PARA EXECUTAR NO CONSOLE:
echo =====================================
echo curl -s https://raw.githubusercontent.com/fourmindsorg/s_agendamento/main/deploy_completo_console.sh ^| bash
echo.

echo 🌐 URLs APÓS DEPLOY:
echo ====================
echo IP: http://3.80.178.120
echo Domínio: http://fourmindstech.com.br (após configurar DNS)
echo Admin: http://3.80.178.120/admin
echo Usuário: admin ^| Senha: admin123
echo.

pause
