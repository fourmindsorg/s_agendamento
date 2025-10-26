@echo off
echo === CRIANDO INFRAESTRUTURA SIMPLES VIA AWS CLI ===

echo 1. Verificando VPC existente...
aws ec2 describe-vpcs --filters "Name=tag:Project,Values=s-agendamento" --query "Vpcs[0].VpcId" --output text

echo 2. Se não existir VPC, criando...
aws ec2 create-vpc --cidr-block 10.0.0.0/16 --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=s-agendamento-vpc},{Key=Project,Value=s-agendamento}]" 2>nul

echo 3. Aguardando 10 segundos...
timeout /t 10 /nobreak

echo 4. Obtendo VPC ID...
for /f %%i in ('aws ec2 describe-vpcs --filters "Name=tag:Project,Values=s-agendamento" --query "Vpcs[0].VpcId" --output text') do set VPC_ID=%%i
echo VPC ID: %VPC_ID%

echo 5. Criando Internet Gateway...
aws ec2 create-internet-gateway --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=s-agendamento-igw},{Key=Project,Value=s-agendamento}]" 2>nul

echo 6. Obtendo IGW ID...
for /f %%i in ('aws ec2 describe-internet-gateways --filters "Name=tag:Project,Values=s-agendamento" --query "InternetGateways[0].InternetGatewayId" --output text') do set IGW_ID=%%i
echo IGW ID: %IGW_ID%

echo 7. Anexando IGW à VPC...
aws ec2 attach-internet-gateway --vpc-id %VPC_ID% --internet-gateway-id %IGW_ID% 2>nul

echo 8. Criando Subnet Pública...
aws ec2 create-subnet --vpc-id %VPC_ID% --cidr-block 10.0.1.0/24 --availability-zone us-east-1a --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=s-agendamento-public},{Key=Project,Value=s-agendamento}]" 2>nul

echo 9. Aguardando 5 segundos...
timeout /t 5 /nobreak

echo 10. Obtendo Subnet ID...
for /f %%i in ('aws ec2 describe-subnets --filters "Name=tag:Project,Values=s-agendamento" --query "Subnets[0].SubnetId" --output text') do set SUBNET_ID=%%i
echo Subnet ID: %SUBNET_ID%

echo 11. Criando Security Group...
aws ec2 create-security-group --group-name s-agendamento-sg --description "Security group for s-agendamento" --vpc-id %VPC_ID% --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=s-agendamento-sg},{Key=Project,Value=s-agendamento}]" 2>nul

echo 12. Obtendo Security Group ID...
for /f %%i in ('aws ec2 describe-security-groups --filters "Name=group-name,Values=s-agendamento-sg" --query "SecurityGroups[0].GroupId" --output text') do set SG_ID=%%i
echo Security Group ID: %SG_ID%

echo 13. Adicionando regras de segurança...
aws ec2 authorize-security-group-ingress --group-id %SG_ID% --protocol tcp --port 22 --cidr 0.0.0.0/0 2>nul
aws ec2 authorize-security-group-ingress --group-id %SG_ID% --protocol tcp --port 80 --cidr 0.0.0.0/0 2>nul
aws ec2 authorize-security-group-ingress --group-id %SG_ID% --protocol tcp --port 443 --cidr 0.0.0.0/0 2>nul

echo 14. Habilitando auto-assign public IP...
aws ec2 modify-subnet-attribute --subnet-id %SUBNET_ID% --map-public-ip-on-launch 2>nul

echo 15. Criando Route Table...
aws ec2 create-route-table --vpc-id %VPC_ID% --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=s-agendamento-rt},{Key=Project,Value=s-agendamento}]" 2>nul

echo 16. Obtendo Route Table ID...
for /f %%i in ('aws ec2 describe-route-tables --filters "Name=tag:Project,Values=s-agendamento" --query "RouteTables[0].RouteTableId" --output text') do set RT_ID=%%i
echo Route Table ID: %RT_ID%

echo 17. Criando rota para Internet...
aws ec2 create-route --route-table-id %RT_ID% --destination-cidr-block 0.0.0.0/0 --gateway-id %IGW_ID% 2>nul

echo 18. Associando subnet à route table...
aws ec2 associate-route-table --subnet-id %SUBNET_ID% --route-table-id %RT_ID% 2>nul

echo 19. Criando instância EC2...
aws ec2 run-instances --image-id ami-0c398cb65a93047f2 --instance-type t2.micro --key-name s-agendamento-key --subnet-id %SUBNET_ID% --security-group-ids %SG_ID% --associate-public-ip-address --user-data file://simple_user_data.sh --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=s-agendamento-server},{Key=Project,Value=s-agendamento}]"

echo 20. Aguardando instância ser criada (60 segundos)...
timeout /t 60 /nobreak

echo 21. Obtendo IP da instância...
for /f %%i in ('aws ec2 describe-instances --filters "Name=tag:Project,Values=s-agendamento" --query "Reservations[0].Instances[0].PublicIpAddress" --output text') do set EC2_IP=%%i
echo EC2 IP: %EC2_IP%

echo === INFRAESTRUTURA CRIADA! ===
echo.
echo Teste em: http://%EC2_IP%
echo Admin: http://%EC2_IP%/admin (admin/admin123)
echo.
echo Aguarde mais 2-3 minutos para o deploy completar.
pause
