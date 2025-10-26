@echo off
echo === CRIANDO NOVA INSTÂNCIA COM DEPLOY AUTOMÁTICO ===

echo 1. Parando instância atual...
aws ec2 stop-instances --instance-ids i-000e6aecf9ad53679

echo.
echo 2. Aguardando instância parar...
timeout /t 60 /nobreak

echo.
echo 3. Terminando instância atual...
aws ec2 terminate-instances --instance-ids i-000e6aecf9ad53679

echo.
echo 4. Aguardando 30 segundos...
timeout /t 30 /nobreak

echo.
echo 5. Criando nova instância com user-data de deploy...
aws ec2 run-instances ^
  --image-id ami-0c398cb65a93047f2 ^
  --instance-type t2.micro ^
  --key-name s-agendamento-key ^
  --subnet-id subnet-064e58474ee010662 ^
  --security-group-ids sg-0c66bf0346b9729ca ^
  --associate-public-ip-address ^
  --block-device-mappings "[{\"DeviceName\":\"/dev/sda1\",\"Ebs\":{\"VolumeSize\":20,\"VolumeType\":\"gp3\",\"Encrypted\":true,\"DeleteOnTermination\":true}}]" ^
  --user-data file://user_data_complete_deploy.sh ^
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=s-agendamento-django-server},{Key=Project,Value=s-agendamento},{Key=Environment,Value=prod}]"

echo.
echo 6. Aguardando instância ser criada (2 minutos)...
timeout /t 120 /nobreak

echo.
echo 7. Verificando nova instância...
aws ec2 describe-instances --filters "Name=tag:Project,Values=s-agendamento" --query "Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress,Tags[?Key=='Name'].Value|[0]]" --output table

echo.
echo === NOVA INSTÂNCIA CRIADA ===
echo.
echo A nova instância será criada com Django já configurado.
echo Aguarde alguns minutos e teste:
echo - http://[NOVO_IP]
echo - http://[NOVO_IP]/admin
echo.
pause
