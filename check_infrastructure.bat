@echo off
echo === VERIFICANDO STATUS DA INFRAESTRUTURA AWS ===
echo.

echo 1. Verificando VPC...
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=s-agendamento-vpc" --query "Vpcs[*].[VpcId,State,CidrBlock]" --output table

echo.
echo 2. Verificando Internet Gateway...
aws ec2 describe-internet-gateways --filters "Name=tag:Name,Values=s-agendamento-igw" --query "InternetGateways[*].[InternetGatewayId,State]" --output table

echo.
echo 3. Verificando Subnets...
aws ec2 describe-subnets --filters "Name=tag:Project,Values=s-agendamento" --query "Subnets[*].[SubnetId,AvailabilityZone,CidrBlock,Tags[?Key=='Name'].Value|[0]]" --output table

echo.
echo 4. Verificando Security Groups...
aws ec2 describe-security-groups --filters "Name=tag:Project,Values=s-agendamento" --query "SecurityGroups[*].[GroupId,GroupName]" --output table

echo.
echo 5. Verificando Instâncias EC2...
aws ec2 describe-instances --filters "Name=tag:Project,Values=s-agendamento" --query "Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress,PrivateIpAddress,Tags[?Key=='Name'].Value|[0]]" --output table

echo.
echo 6. Verificando RDS...
aws rds describe-db-instances --filters "Name=tag:Project,Values=s-agendamento" --query "DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus,Endpoint.Address,EngineVersion]" --output table

echo.
echo 7. Verificando S3 Buckets...
aws s3api list-buckets --query "Buckets[?contains(Name, 's-agendamento')].[Name,CreationDate]" --output table

echo.
echo 8. Verificando Elastic IP...
aws ec2 describe-addresses --filters "Name=tag:Project,Values=s-agendamento" --query "Addresses[*].[PublicIp,AllocationId,AssociationId,Tags[?Key=='Name'].Value|[0]]" --output table

echo.
echo === VERIFICAÇÃO CONCLUÍDA ===
pause
