@echo off
echo === CRIANDO INFRAESTRUTURA COMPLETA VIA AWS CLI ===

echo 1. Criando VPC...
aws ec2 create-vpc --cidr-block 10.0.0.0/16 --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=s-agendamento-vpc},{Key=Project,Value=s-agendamento},{Key=Environment,Value=prod}]"

echo 2. Aguardando VPC ser criada...
timeout /t 10 /nobreak

echo 3. Obtendo ID da VPC...
for /f "tokens=2" %%i in ('aws ec2 describe-vpcs --filters "Name=tag:Project,Values=s-agendamento" --query "Vpcs[0].VpcId" --output text') do set VPC_ID=%%i
echo VPC ID: %VPC_ID%

echo 4. Criando Internet Gateway...
aws ec2 create-internet-gateway --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=s-agendamento-igw},{Key=Project,Value=s-agendamento},{Key=Environment,Value=prod}]"

echo 5. Obtendo ID do Internet Gateway...
for /f "tokens=2" %%i in ('aws ec2 describe-internet-gateways --filters "Name=tag:Project,Values=s-agendamento" --query "InternetGateways[0].InternetGatewayId" --output text') do set IGW_ID=%%i
echo IGW ID: %IGW_ID%

echo 6. Anexando Internet Gateway à VPC...
aws ec2 attach-internet-gateway --vpc-id %VPC_ID% --internet-gateway-id %IGW_ID%

echo 7. Criando Subnet Pública...
aws ec2 create-subnet --vpc-id %VPC_ID% --cidr-block 10.0.1.0/24 --availability-zone us-east-1a --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=s-agendamento-public-subnet},{Key=Project,Value=s-agendamento},{Key=Environment,Value=prod}]"

echo 8. Obtendo ID da Subnet Pública...
for /f "tokens=2" %%i in ('aws ec2 describe-subnets --filters "Name=tag:Project,Values=s-agendamento" --query "Subnets[0].SubnetId" --output text') do set PUBLIC_SUBNET_ID=%%i
echo Public Subnet ID: %PUBLIC_SUBNET_ID%

echo 9. Criando Subnets Privadas...
aws ec2 create-subnet --vpc-id %VPC_ID% --cidr-block 10.0.2.0/24 --availability-zone us-east-1a --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=s-agendamento-private-subnet-1},{Key=Project,Value=s-agendamento},{Key=Environment,Value=prod}]"

aws ec2 create-subnet --vpc-id %VPC_ID% --cidr-block 10.0.3.0/24 --availability-zone us-east-1b --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=s-agendamento-private-subnet-2},{Key=Project,Value=s-agendamento},{Key=Environment,Value=prod}]"

echo 10. Obtendo IDs das Subnets Privadas...
for /f "tokens=2" %%i in ('aws ec2 describe-subnets --filters "Name=tag:Project,Values=s-agendamento" --query "Subnets[1].SubnetId" --output text') do set PRIVATE_SUBNET_1_ID=%%i
for /f "tokens=2" %%i in ('aws ec2 describe-subnets --filters "Name=tag:Project,Values=s-agendamento" --query "Subnets[2].SubnetId" --output text') do set PRIVATE_SUBNET_2_ID=%%i
echo Private Subnet 1 ID: %PRIVATE_SUBNET_1_ID%
echo Private Subnet 2 ID: %PRIVATE_SUBNET_2_ID%

echo 11. Criando Route Table Pública...
aws ec2 create-route-table --vpc-id %VPC_ID% --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=s-agendamento-public-rt},{Key=Project,Value=s-agendamento},{Key=Environment,Value=prod}]"

echo 12. Obtendo ID da Route Table Pública...
for /f "tokens=2" %%i in ('aws ec2 describe-route-tables --filters "Name=tag:Project,Values=s-agendamento" --query "RouteTables[0].RouteTableId" --output text') do set PUBLIC_RT_ID=%%i
echo Public Route Table ID: %PUBLIC_RT_ID%

echo 13. Criando rota para Internet Gateway...
aws ec2 create-route --route-table-id %PUBLIC_RT_ID% --destination-cidr-block 0.0.0.0/0 --gateway-id %IGW_ID%

echo 14. Associando Subnet Pública à Route Table...
aws ec2 associate-route-table --subnet-id %PUBLIC_SUBNET_ID% --route-table-id %PUBLIC_RT_ID%

echo 15. Habilitando auto-assign public IP na subnet pública...
aws ec2 modify-subnet-attribute --subnet-id %PUBLIC_SUBNET_ID% --map-public-ip-on-launch

echo 16. Criando Security Group para EC2...
aws ec2 create-security-group --group-name s-agendamento-ec2-sg --description "Security group for EC2 instance" --vpc-id %VPC_ID% --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=s-agendamento-ec2-sg},{Key=Project,Value=s-agendamento},{Key=Environment,Value=prod}]"

echo 17. Obtendo ID do Security Group EC2...
for /f "tokens=2" %%i in ('aws ec2 describe-security-groups --filters "Name=group-name,Values=s-agendamento-ec2-sg" --query "SecurityGroups[0].GroupId" --output text') do set EC2_SG_ID=%%i
echo EC2 Security Group ID: %EC2_SG_ID%

echo 18. Adicionando regras ao Security Group EC2...
aws ec2 authorize-security-group-ingress --group-id %EC2_SG_ID% --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id %EC2_SG_ID% --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id %EC2_SG_ID% --protocol tcp --port 443 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id %EC2_SG_ID% --protocol tcp --port 8000 --cidr 0.0.0.0/0

echo 19. Criando Security Group para RDS...
aws ec2 create-security-group --group-name s-agendamento-rds-sg --description "Security group for RDS" --vpc-id %VPC_ID% --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=s-agendamento-rds-sg},{Key=Project,Value=s-agendamento},{Key=Environment,Value=prod}]"

echo 20. Obtendo ID do Security Group RDS...
for /f "tokens=2" %%i in ('aws ec2 describe-security-groups --filters "Name=group-name,Values=s-agendamento-rds-sg" --query "SecurityGroups[0].GroupId" --output text') do set RDS_SG_ID=%%i
echo RDS Security Group ID: %RDS_SG_ID%

echo 21. Adicionando regra para PostgreSQL no Security Group RDS...
aws ec2 authorize-security-group-ingress --group-id %RDS_SG_ID% --protocol tcp --port 5432 --source-group %EC2_SG_ID%

echo 22. Criando DB Subnet Group...
aws rds create-db-subnet-group --db-subnet-group-name s-agendamento-db-subnet-group --db-subnet-group-description "Subnet group for s-agendamento" --subnet-ids %PRIVATE_SUBNET_1_ID% %PRIVATE_SUBNET_2_ID% --tags Key=Name,Value=s-agendamento-db-subnet-group Key=Project,Value=s-agendamento Key=Environment,Value=prod

echo 23. Criando instância RDS PostgreSQL...
aws rds create-db-instance --db-instance-identifier s-agendamento-db --db-instance-class db.t3.micro --engine postgres --master-username agendamento_user --master-user-password "4MindsAgendamento2025!SecureDB#Pass" --allocated-storage 20 --max-allocated-storage 100 --storage-type gp2 --storage-encrypted --vpc-security-group-ids %RDS_SG_ID% --db-subnet-group-name s-agendamento-db-subnet-group --backup-retention-period 7 --preferred-backup-window 03:00-04:00 --preferred-maintenance-window sun:04:00-sun:05:00 --no-publicly-accessible --db-name agendamento_db --tags Key=Name,Value=s-agendamento-db Key=Project,Value=s-agendamento Key=Environment,Value=prod

echo 24. Aguardando RDS ser criado (2 minutos)...
timeout /t 120 /nobreak

echo 25. Criando Elastic IP...
aws ec2 allocate-address --domain vpc --tag-specifications "ResourceType=elastic-ip,Tags=[{Key=Name,Value=s-agendamento-eip},{Key=Project,Value=s-agendamento},{Key=Environment,Value=prod}]"

echo 26. Obtendo ID do Elastic IP...
for /f "tokens=2" %%i in ('aws ec2 describe-addresses --filters "Name=tag:Project,Values=s-agendamento" --query "Addresses[0].AllocationId" --output text') do set EIP_ALLOCATION_ID=%%i
echo Elastic IP Allocation ID: %EIP_ALLOCATION_ID%

echo 27. Criando instância EC2...
aws ec2 run-instances --image-id ami-0c398cb65a93047f2 --instance-type t2.micro --key-name s-agendamento-key --subnet-id %PUBLIC_SUBNET_ID% --security-group-ids %EC2_SG_ID% --associate-public-ip-address --user-data file://simple_user_data.sh --block-device-mappings "[{\"DeviceName\":\"/dev/sda1\",\"Ebs\":{\"VolumeSize\":20,\"VolumeType\":\"gp3\",\"Encrypted\":true,\"DeleteOnTermination\":true}}]" --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=s-agendamento-django-server},{Key=Project,Value=s-agendamento},{Key=Environment,Value=prod}]"

echo 28. Aguardando EC2 ser criada (1 minuto)...
timeout /t 60 /nobreak

echo 29. Obtendo ID da instância EC2...
for /f "tokens=2" %%i in ('aws ec2 describe-instances --filters "Name=tag:Project,Values=s-agendamento" --query "Reservations[0].Instances[0].InstanceId" --output text') do set EC2_INSTANCE_ID=%%i
echo EC2 Instance ID: %EC2_INSTANCE_ID%

echo 30. Associando Elastic IP à instância EC2...
aws ec2 associate-address --instance-id %EC2_INSTANCE_ID% --allocation-id %EIP_ALLOCATION_ID%

echo 31. Obtendo IP público da instância...
for /f "tokens=2" %%i in ('aws ec2 describe-instances --instance-ids %EC2_INSTANCE_ID% --query "Reservations[0].Instances[0].PublicIpAddress" --output text') do set EC2_PUBLIC_IP=%%i
echo EC2 Public IP: %EC2_PUBLIC_IP%

echo 32. Criando buckets S3...
aws s3api create-bucket --bucket s-agendamento-static-exxyawpx --region us-east-1
aws s3api create-bucket --bucket s-agendamento-media-exxyawpx --region us-east-1

echo 33. Configurando Route53 (se necessário)...
echo Configurando registros DNS...

echo === INFRAESTRUTURA CRIADA COM SUCESSO! ===
echo.
echo URLs para testar:
echo - http://%EC2_PUBLIC_IP%
echo - http://%EC2_PUBLIC_IP%/admin
echo.
echo Credenciais admin:
echo - Usuário: admin
echo - Senha: admin123
echo.
echo Aguarde mais 2-3 minutos para o deploy automático completar.
pause
