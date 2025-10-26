@echo off
echo === DESTRUINDO TODA A INFRAESTRUTURA AWS EXISTENTE ===

echo.
echo 1. Parando e removendo instâncias EC2...
for /f "tokens=3" %%i in ('aws ec2 describe-instances --filters "Name=tag:Project,Values=s-agendamento" "Name=instance-state-name,Values=running,stopped" --query "Reservations[*].Instances[*].InstanceId" --output text') do (
    echo Parando instância %%i...
    aws ec2 stop-instances --instance-ids %%i
    timeout /t 30 /nobreak >nul
    echo Terminando instância %%i...
    aws ec2 terminate-instances --instance-ids %%i
)

echo.
echo 2. Removendo instâncias RDS...
aws rds describe-db-instances --query "DBInstances[?contains(DBInstanceIdentifier,'agendamento')].DBInstanceIdentifier" --output text | for /f "tokens=*" %%i in ('more') do (
    echo Removendo RDS %%i...
    aws rds delete-db-instance --db-instance-identifier %%i --skip-final-snapshot
)

echo.
echo 3. Removendo Security Groups...
for /f "tokens=1" %%i in ('aws ec2 describe-security-groups --filters "Name=tag:Project,Values=s-agendamento" --query "SecurityGroups[*].GroupId" --output text') do (
    echo Removendo Security Group %%i...
    aws ec2 delete-security-group --group-id %%i
)

echo.
echo 4. Removendo Subnets...
for /f "tokens=1" %%i in ('aws ec2 describe-subnets --filters "Name=tag:Project,Values=s-agendamento" --query "Subnets[*].SubnetId" --output text') do (
    echo Removendo Subnet %%i...
    aws ec2 delete-subnet --subnet-id %%i
)

echo.
echo 5. Removendo Route Tables...
for /f "tokens=1" %%i in ('aws ec2 describe-route-tables --filters "Name=tag:Project,Values=s-agendamento" --query "RouteTables[*].RouteTableId" --output text') do (
    echo Removendo Route Table %%i...
    aws ec2 delete-route-table --route-table-id %%i
)

echo.
echo 6. Removendo Internet Gateways...
for /f "tokens=1" %%i in ('aws ec2 describe-internet-gateways --filters "Name=tag:Project,Values=s-agendamento" --query "InternetGateways[*].InternetGatewayId" --output text') do (
    echo Desanexando e removendo Internet Gateway %%i...
    aws ec2 detach-internet-gateway --internet-gateway-id %%i
    aws ec2 delete-internet-gateway --internet-gateway-id %%i
)

echo.
echo 7. Removendo VPCs...
for /f "tokens=1" %%i in ('aws ec2 describe-vpcs --filters "Name=tag:Project,Values=s-agendamento" --query "Vpcs[*].VpcId" --output text') do (
    echo Removendo VPC %%i...
    aws ec2 delete-vpc --vpc-id %%i
)

echo.
echo 8. Removendo S3 Buckets...
for /f "tokens=*" %%i in ('aws s3api list-buckets --query "Buckets[?contains(Name,'agendamento')].Name" --output text') do (
    echo Removendo S3 Bucket %%i...
    aws s3 rb s3://%%i --force
)

echo.
echo 9. Removendo Elastic IPs...
for /f "tokens=1" %%i in ('aws ec2 describe-addresses --filters "Name=tag:Project,Values=s-agendamento" --query "Addresses[*].AllocationId" --output text') do (
    echo Removendo Elastic IP %%i...
    aws ec2 release-address --allocation-id %%i
)

echo.
echo === DESTRUIÇÃO CONCLUÍDA ===
echo Aguarde alguns minutos para que todos os recursos sejam removidos completamente.
pause

