@echo off
echo 🚀 Iniciando deploy via AWS CLI...

echo 🔍 Verificando configuração AWS CLI...
aws sts get-caller-identity
if %errorlevel% neq 0 (
    echo ❌ AWS CLI não configurado. Configure primeiro com 'aws configure'
    pause
    exit /b 1
)

echo ✅ AWS CLI configurado

echo 🔍 Procurando instância EC2...
for /f "tokens=*" %%i in ('aws ec2 describe-instances --filters "Name=ip-address,Values=3.80.178.120" --query "Reservations[*].Instances[*].InstanceId" --output text') do set INSTANCE_ID=%%i

if "%INSTANCE_ID%"=="" (
    echo ❌ Instância não encontrada com IP 3.80.178.120
    echo 🔍 Tentando buscar por nome...
    for /f "tokens=*" %%i in ('aws ec2 describe-instances --filters "Name=tag:Name,Values=agendamento-4minds-web-server" --query "Reservations[*].Instances[*].InstanceId" --output text') do set INSTANCE_ID=%%i
)

if "%INSTANCE_ID%"=="" (
    echo ❌ Instância não encontrada. Verifique se a instância está rodando.
    pause
    exit /b 1
)

echo ✅ Instância encontrada: %INSTANCE_ID%

echo 🚀 Executando deploy...
aws ssm send-command --instance-ids %INSTANCE_ID% --document-name "AWS-RunShellScript" --parameters "commands=[\"cd /home/ubuntu/s_agendamento\",\"git pull origin main\",\"pip install -r requirements.txt\",\"python manage.py migrate\",\"python manage.py collectstatic --noinput\",\"sudo systemctl restart gunicorn\",\"sudo systemctl restart nginx\",\"echo 'Deploy concluído!'\",\"echo 'Acesse: http://3.80.178.120'\"]" --output text --query "Command.CommandId"

echo ⏳ Aguardando execução...
timeout /t 30 /nobreak

echo 🎉 Deploy executado!
echo 🌐 Acesse: http://3.80.178.120
echo 🌐 Acesse: http://fourmindstech.com.br (após configurar DNS)

pause
