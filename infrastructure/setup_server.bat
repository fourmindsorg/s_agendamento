@echo off
echo Deploy da aplicacao Django na AWS EC2
echo.

set EC2_IP=44.205.204.166
set EC2_USER=ubuntu

echo Verificando chave SSH...
if not exist "%USERPROFILE%\.ssh\s-agendamento-key.pem" (
    echo Criando chave SSH...
    aws ec2 create-key-pair --key-name s-agendamento-key --query "KeyMaterial" --output text > "%USERPROFILE%\.ssh\s-agendamento-key.pem"
    echo Chave criada
)

echo.
echo Testando conexao com o servidor...
ping -n 1 %EC2_IP% >nul
if %errorlevel% neq 0 (
    echo Erro: Nao foi possivel conectar ao servidor
    pause
    exit /b 1
)

echo Conexao OK!
echo.
echo Criando script de configuracao...

echo sudo apt-get update -y > setup.sh
echo sudo apt-get install -y python3 python3-pip python3-venv nginx git >> setup.sh
echo sudo mkdir -p /var/www/agendamento >> setup.sh
echo sudo chown -R ubuntu:ubuntu /var/www/agendamento >> setup.sh
echo cd /var/www/agendamento >> setup.sh
echo git clone https://github.com/fourmindsorg/s_agendamento.git . ^|^| true >> setup.sh
echo python3 -m venv venv >> setup.sh
echo source venv/bin/activate >> setup.sh
echo pip install --upgrade pip >> setup.sh
echo pip install -r requirements.txt gunicorn >> setup.sh
echo echo DEBUG=False ^> .env >> setup.sh
echo echo SECRET_KEY=django-insecure-4minds-agendamento-2025-super-secret-key ^>^> .env >> setup.sh
echo echo ALLOWED_HOSTS=fourmindstech.com.br,www.fourmindstech.com.br,44.205.204.166 ^>^> .env >> setup.sh
echo python manage.py migrate >> setup.sh
echo python manage.py collectstatic --noinput >> setup.sh
echo sudo systemctl restart nginx >> setup.sh
echo echo Deploy concluido! >> setup.sh

echo.
echo Executando deploy no servidor...
wsl scp -i ~/.ssh/s-agendamento-key.pem setup.sh %EC2_USER%@%EC2_IP%:/home/ubuntu/
wsl ssh -i ~/.ssh/s-agendamento-key.pem %EC2_USER%@%EC2_IP% "chmod +x setup.sh && ./setup.sh"

del setup.sh

echo.
echo Deploy completo!
echo Website: http://fourmindstech.com.br
echo Admin: http://fourmindstech.com.br/admin/
echo Usuario: admin ^| Senha: admin123
echo.
pause
