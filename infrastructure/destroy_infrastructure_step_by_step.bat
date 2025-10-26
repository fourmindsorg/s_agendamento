@echo off
echo === DESTRUINDO INFRAESTRUTURA PASSO A PASSO ===

echo.
echo 1. Removendo S3 Buckets (um por vez)...
echo Removendo s-agendamento-media-exxyawpx...
aws s3 rb s3://s-agendamento-media-exxyawpx --force
echo Removendo s-agendamento-static-exxyawpx...
aws s3 rb s3://s-agendamento-static-exxyawpx --force

echo.
echo 2. Aguardando 30 segundos...
timeout /t 30 /nobreak >nul

echo.
echo 3. Removendo instâncias RDS...
aws rds describe-db-instances --query "DBInstances[?contains(DBInstanceIdentifier,'agendamento')].DBInstanceIdentifier" --output text | for /f "tokens=*" %%i in ('more') do (
    echo Removendo RDS %%i...
    aws rds delete-db-instance --db-instance-identifier %%i --skip-final-snapshot
)

echo.
echo 4. Aguardando 60 segundos para RDS...
timeout /t 60 /nobreak >nul

echo.
echo 5. Removendo instâncias EC2...
for /f "tokens=3" %%i in ('aws ec2 describe-instances --filters "Name=tag:Project,Values=s-agendamento" "Name=instance-state-name,Values=running,stopped" --query "Reservations[*].Instances[*].InstanceId" --output text') do (
    echo Terminando instância %%i...
    aws ec2 terminate-instances --instance-ids %%i
)

echo.
echo 6. Aguardando 60 segundos para EC2...
timeout /t 60 /nobreak >nul

echo.
echo 7. Removendo Security Groups (tentar novamente)...
for /f "tokens=1" %%i in ('aws ec2 describe-security-groups --filters "Name=tag:Project,Values=s-agendamento" --query "SecurityGroups[*].GroupId" --output text') do (
    echo Removendo Security Group %%i...
    aws ec2 delete-security-group --group-id %%i
)

echo.
echo 8. Removendo Subnets...
for /f "tokens=1" %%i in ('aws ec2 describe-subnets --filters "Name=tag:Project,Values=s-agendamento" --query "Subnets[*].SubnetId" --output text') do (
    echo Removendo Subnet %%i...
    aws ec2 delete-subnet --subnet-id %%i
)

echo.
echo 9. Removendo Route Tables...
for /f "tokens=1" %%i in ('aws ec2 describe-route-tables --filters "Name=tag:Project,Values=s-agendamento" --query "RouteTables[*].RouteTableId" --output text') do (
    echo Removendo Route Table %%i...
    aws ec2 delete-route-table --route-table-id %%i
)

echo.
echo 10. Removendo Internet Gateways...
for /f "tokens=1" %%i in ('aws ec2 describe-internet-gateways --filters "Name=tag:Project,Values=s-agendamento" --query "InternetGateways[*].InternetGatewayId" --output text') do (
    echo Desanexando Internet Gateway %%i...
    aws ec2 detach-internet-gateway --internet-gateway-id %%i --vpc-id vpc-09c09a77c5b469d74
    echo Removendo Internet Gateway %%i...
    aws ec2 delete-internet-gateway --internet-gateway-id %%i
)

echo.
echo 11. Removendo VPC...
aws ec2 delete-vpc --vpc-id vpc-09c09a77c5b469d74

echo.
echo 12. Removendo Elastic IPs...
for /f "tokens=1" %%i in ('aws ec2 describe-addresses --filters "Name=tag:Project,Values=s-agendamento" --query "Addresses[*].AllocationId" --output text') do (
    echo Removendo Elastic IP %%i...
    aws ec2 release-address --allocation-id %%i
)

echo.
echo === DESTRUIÇÃO CONCLUÍDA ===
pause

