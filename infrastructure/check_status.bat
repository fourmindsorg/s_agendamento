@echo off
echo Verificando status da instancia EC2...
echo.

aws ec2 describe-instances --filters "Name=tag:Name,Values=s-agendamento-server" --query "Reservations[0].Instances[0].[InstanceId,State.Name,PublicIpAddress]" --output table

echo.
echo Verificando se a instancia esta rodando...
aws ec2 describe-instances --filters "Name=tag:Name,Values=s-agendamento-server" --query "Reservations[0].Instances[0].State.Name" --output text

echo.
echo Verificando IP publico...
aws ec2 describe-instances --filters "Name=tag:Name,Values=s-agendamento-server" --query "Reservations[0].Instances[0].PublicIpAddress" --output text

echo.
echo Verificando ID da instancia...
aws ec2 describe-instances --filters "Name=tag:Name,Values=s-agendamento-server" --query "Reservations[0].Instances[0].InstanceId" --output text

echo.
echo Verificando se o Elastic IP esta associado...
aws ec2 describe-addresses --filters "Name=instance-id,Values=[INSTANCE_ID]" --output table

echo.
pause
