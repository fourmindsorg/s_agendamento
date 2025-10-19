@echo off
echo 🚀 Executando setup completo via AWS CLI...

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

echo 📤 Enviando script de setup para a EC2...
aws ssm send-command --instance-ids %INSTANCE_ID% --document-name "AWS-RunShellScript" --parameters "commands=[\"cd /home/ubuntu\",\"curl -o setup_completo_ec2.sh https://raw.githubusercontent.com/fourmindsorg/s_agendamento/main/setup_completo_ec2.sh\",\"chmod +x setup_completo_ec2.sh\",\"./setup_completo_ec2.sh\"]" --output text --query "Command.CommandId"

echo ⏳ Aguardando execução do setup...
timeout /t 60 /nobreak

echo 🎉 Setup executado!
echo 🌐 Acesse: http://3.80.178.120
echo 🌐 Acesse: http://fourmindstech.com.br (após configurar DNS)
echo 👤 Admin: http://3.80.178.120/admin
echo 👤 Usuário: admin | Senha: admin123

pause
