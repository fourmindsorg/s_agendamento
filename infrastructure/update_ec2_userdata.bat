@echo off
echo === ATUALIZANDO USER-DATA DA INSTÂNCIA EC2 ===

echo 1. Parando instância para atualizar user-data...
aws ec2 stop-instances --instance-ids i-000e6aecf9ad53679

echo.
echo 2. Aguardando instância parar...
timeout /t 60 /nobreak

echo.
echo 3. Atualizando user-data com script de deploy...
aws ec2 modify-instance-attribute --instance-id i-000e6aecf9ad53679 --user-data file://user_data_deploy.sh

echo.
echo 4. Iniciando instância...
aws ec2 start-instances --instance-ids i-000e6aecf9ad53679

echo.
echo 5. Aguardando instância iniciar (3 minutos)...
timeout /t 180 /nobreak

echo.
echo 6. Verificando status...
aws ec2 describe-instances --instance-ids i-000e6aecf9ad53679 --query "Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress]" --output table

echo.
echo === USER-DATA ATUALIZADO ===
echo.
echo A instância foi reiniciada com o script de deploy.
echo Aguarde alguns minutos e teste:
echo - http://34.202.149.24
echo - http://34.202.149.24/admin
echo.
pause
