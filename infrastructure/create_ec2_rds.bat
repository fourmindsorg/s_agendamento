@echo off
echo === CRIANDO EC2 E RDS VIA AWS CLI ===

echo.
echo 1. Criando DB Subnet Group...
aws rds create-db-subnet-group ^
  --db-subnet-group-name s-agendamento-db-subnet-group ^
  --db-subnet-group-description "Subnet group for s-agendamento" ^
  --subnet-ids subnet-03be9e650a5a1caab subnet-0f358a9434409154f ^
  --tags Key=Name,Value=s-agendamento-db-subnet-group Key=Project,Value=s-agendamento

echo.
echo 2. Criando instância RDS PostgreSQL...
aws rds create-db-instance ^
  --db-instance-identifier s-agendamento-db ^
  --db-instance-class db.t3.micro ^
  --engine postgres ^
  --engine-version 13.14 ^
  --master-username agendamento_user ^
  --master-user-password "4MindsAgendamento2025!SecureDB#Pass" ^
  --allocated-storage 20 ^
  --max-allocated-storage 100 ^
  --storage-type gp2 ^
  --storage-encrypted ^
  --vpc-security-group-ids sg-0685d5c6df7362bc5 ^
  --db-subnet-group-name s-agendamento-db-subnet-group ^
  --backup-retention-period 7 ^
  --preferred-backup-window 03:00-04:00 ^
  --preferred-maintenance-window sun:04:00-sun:05:00 ^
  --no-publicly-accessible ^
  --db-name agendamento_db ^
  --tags Key=Name,Value=s-agendamento-db Key=Project,Value=s-agendamento Key=Environment,Value=prod

echo.
echo 3. Aguardando 60 segundos antes de criar EC2...
timeout /t 60 /nobreak

echo.
echo 4. Criando instância EC2...
aws ec2 run-instances ^
  --image-id ami-0c398cb65a93047f2 ^
  --instance-type t2.micro ^
  --key-name s-agendamento-key ^
  --subnet-id subnet-064e58474ee010662 ^
  --security-group-ids sg-0c66bf0346b9729ca ^
  --associate-public-ip-address ^
  --block-device-mappings "[{\"DeviceName\":\"/dev/sda1\",\"Ebs\":{\"VolumeSize\":20,\"VolumeType\":\"gp3\",\"Encrypted\":true,\"DeleteOnTermination\":true}}]" ^
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=s-agendamento-django-server},{Key=Project,Value=s-agendamento},{Key=Environment,Value=prod}]" ^
  --user-data file://user_data_simple.sh ^
  --query "Instances[0].InstanceId" ^
  --output text > instance_id.txt

set /p INSTANCE_ID=<instance_id.txt
echo Instância EC2 criada: %INSTANCE_ID%

echo.
echo 5. Associando Elastic IP...
aws ec2 associate-address ^
  --instance-id %INSTANCE_ID% ^
  --allocation-id eipalloc-0038060bb69916e6a

echo.
echo === CRIAÇÃO CONCLUÍDA ===
echo.
echo Aguarde alguns minutos para que os recursos sejam provisionados.
echo Você pode verificar o status com: aws ec2 describe-instances --instance-ids %INSTANCE_ID%
pause

