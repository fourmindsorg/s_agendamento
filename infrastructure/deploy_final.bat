@echo off
echo Deploy da aplicacao Django na AWS EC2
echo.

set EC2_IP=44.205.204.166
set EC2_USER=ubuntu

echo Verificando instancia EC2...
aws ec2 describe-instances --filters "Name=tag:Name,Values=s-agendamento-server" --query "Reservations[0].Instances[0].[InstanceId,State.Name,PublicIpAddress]" --output text

echo.
echo Criando script de deploy...
echo sudo apt-get update -y > deploy.sh
echo sudo apt-get install -y python3 python3-pip python3-venv nginx git >> deploy.sh
echo sudo mkdir -p /var/www/agendamento >> deploy.sh
echo sudo chown -R ubuntu:ubuntu /var/www/agendamento >> deploy.sh
echo cd /var/www/agendamento >> deploy.sh
echo git clone https://github.com/fourmindsorg/s_agendamento.git . ^|^| true >> deploy.sh
echo python3 -m venv venv >> deploy.sh
echo source venv/bin/activate >> deploy.sh
echo pip install --upgrade pip >> deploy.sh
echo pip install -r requirements.txt gunicorn >> deploy.sh
echo echo DEBUG=False ^> .env >> deploy.sh
echo echo SECRET_KEY=django-insecure-4minds-agendamento-2025-super-secret-key ^>^> .env >> deploy.sh
echo echo ALLOWED_HOSTS=fourmindstech.com.br,www.fourmindstech.com.br,44.205.204.166 ^>^> .env >> deploy.sh
echo python manage.py migrate >> deploy.sh
echo python manage.py collectstatic --noinput >> deploy.sh
echo sudo systemctl restart nginx >> deploy.sh
echo echo Deploy concluido! >> deploy.sh

echo.
echo Executando deploy...
wsl scp -i ~/.ssh/s-agendamento-key.pem deploy.sh %EC2_USER%@%EC2_IP%:/home/ubuntu/
wsl ssh -i ~/.ssh/s-agendamento-key.pem %EC2_USER%@%EC2_IP% "chmod +x deploy.sh && ./deploy.sh"

del emplace.sh

echo.
echo Deploy completo!
echo Website: http://fourmindstech.com.br
echo Admin: http://fourmindstech.com.br/admin/
echo Usuario: admin ^| Senha: admin123
echo.
pause
