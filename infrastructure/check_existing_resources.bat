@echo off
echo === VERIFICANDO RECURSOS EXISTENTES ===

echo.
echo 1. VPC:
aws ec2 describe-vpcs --filters "Name=tag:Project,Values=s-agendamento" --query "Vpcs[*].[VpcId,CidrBlock,Tags[?Key=='Name'].Value|[0]]" --output text

echo.
echo 2. Internet Gateways:
aws ec2 describe-internet-gateways --query "InternetGateways[*].[InternetGatewayId,Attachments[0].VpcId,Tags[?Key=='Name'].Value|[0]]" --output text

echo.
echo 3. Subnets:
aws ec2 describe-subnets --filters "Name=tag:Project,Values=s-agendamento" --query "Subnets[*].[SubnetId,CidrBlock,AvailabilityZone,Tags[?Key=='Name'].Value|[0]]" --output text

echo.
echo 4. Security Groups:
aws ec2 describe-security-groups --filters "Name=tag:Project,Values=s-agendamento" --query "SecurityGroups[*].[GroupId,GroupName,VpcId]" --output text

echo.
echo 5. EC2 Instances:
aws ec2 describe-instances --filters "Name=tag:Project,Values=s-agendamento" "Name=instance-state-name,Values=running,stopped" --query "Reservations[*].Instances[*].[InstanceId,State.Name,Tags[?Key=='Name'].Value|[0]]" --output text

echo.
echo 6. RDS Instances:
aws rds describe-db-instances --query "DBInstances[?contains(DBInstanceIdentifier,'agendamento')].[DBInstanceIdentifier,DBInstanceStatus]" --output text

echo.
echo 7. S3 Buckets:
aws s3api list-buckets --query "Buckets[?contains(Name,'agendamento')].Name" --output text

echo.
echo 8. Elastic IPs:
aws ec2 describe-addresses --filters "Name=tag:Project,Values=s-agendamento" --query "Addresses[*].[AllocationId,PublicIp,Tags[?Key=='Name'].Value|[0]]" --output text

echo.
echo === VERIFICAÇÃO CONCLUÍDA ===
pause

