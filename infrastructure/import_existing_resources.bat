@echo off
echo === IMPORTANDO RECURSOS EXISTENTES PARA O TERRAFORM ===

echo.
echo Importando VPC...
terraform import aws_vpc.main vpc-09c09a77c5b469d74

echo.
echo Importando Internet Gateway...
terraform import "aws_internet_gateway.main[0]" igw-0d63a324c526af54b

echo.
echo Importando Subnet Pública...
terraform import "aws_subnet.public[0]" subnet-057f3e09e8bd039a0

echo.
echo Importando Subnet Privada 1...
terraform import "aws_subnet.private[0]" subnet-0972122bf799ba7a8

echo.
echo Importando Subnet Privada 2...
terraform import "aws_subnet.private[1]" subnet-0720252601122ce9d

echo.
echo Importando Security Groups (se existirem)...
terraform import "aws_security_group.ec2" sg-0f190fd7242ac791a
terraform import "aws_security_group.rds" sg-081a78e17a516d1c9

echo.
echo Importando S3 Buckets...
terraform import "aws_s3_bucket.static" s-agendamento-static-exxyawpx
terraform import "aws_s3_bucket.media" s-agendamento-media-exxyawpx

echo.
echo === IMPORTAÇÃO CONCLUÍDA ===
echo Agora você pode executar: terraform plan -var-file="terraform.tfvars"
pause

