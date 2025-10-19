# Script para criar RDS PostgreSQL com todas as configurações necessárias

Write-Host "=== Criando RDS PostgreSQL ===" -ForegroundColor Cyan

# 1. Obter VPC ID
Write-Host "1. Obtendo VPC ID..." -ForegroundColor Yellow
$vpcId = aws ec2 describe-vpcs --query "Vpcs[0].VpcId" --output text
Write-Host "VPC ID: $vpcId" -ForegroundColor Green

# 2. Obter zonas de disponibilidade
Write-Host "2. Obtendo zonas de disponibilidade..." -ForegroundColor Yellow
$azs = aws ec2 describe-availability-zones --query "AvailabilityZones[0:2].ZoneName" --output text
$azArray = $azs -split "`t"
Write-Host "Zonas: $azs" -ForegroundColor Green

# 3. Criar subnets privadas
Write-Host "3. Criando subnets privadas..." -ForegroundColor Yellow
$subnet1 = aws ec2 create-subnet --vpc-id $vpcId --cidr-block "10.0.4.0/24" --availability-zone "us-east-1a" --query "Subnet.SubnetId" --output text
$subnet2 = aws ec2 create-subnet --vpc-id $vpcId --cidr-block "10.0.5.0/24" --availability-zone "us-east-1b" --query "Subnet.SubnetId" --output text
Write-Host "Subnet 1: $subnet1" -ForegroundColor Green
Write-Host "Subnet 2: $subnet2" -ForegroundColor Green

# 4. Criar security group para RDS
Write-Host "4. Criando security group para RDS..." -ForegroundColor Yellow
$sgId = aws ec2 create-security-group --group-name agendamento-4minds-rds-sg --description "Security group for RDS PostgreSQL" --vpc-id $vpcId --query "GroupId" --output text
Write-Host "Security Group ID: $sgId" -ForegroundColor Green

# 5. Adicionar regra de entrada para PostgreSQL
Write-Host "5. Configurando regras de segurança..." -ForegroundColor Yellow
aws ec2 authorize-security-group-ingress --group-id $sgId --protocol tcp --port 5432 --cidr 10.0.0.0/16
Write-Host "Regra de segurança adicionada" -ForegroundColor Green

# 6. Criar subnet group para RDS
Write-Host "6. Criando subnet group para RDS..." -ForegroundColor Yellow
aws rds create-db-subnet-group --db-subnet-group-name agendamento-4minds-db-subnet-group --db-subnet-group-description "Subnet group for agendamento-4minds RDS" --subnet-ids $subnet1 $subnet2
Write-Host "Subnet group criado" -ForegroundColor Green

# 7. Criar instância RDS
Write-Host "7. Criando instância RDS PostgreSQL..." -ForegroundColor Yellow
aws rds create-db-instance --db-instance-identifier agendamento-4minds-postgres --engine postgres --engine-version 14 --db-instance-class db.t4g.micro --allocated-storage 20 --master-username postgres --master-user-password "4MindsAgendamento2025!SecureDB#Pass" --db-name agendamentos_db --vpc-security-group-ids $sgId --db-subnet-group-name agendamento-4minds-db-subnet-group --no-publicly-accessible --backup-retention-period 7 --no-multi-az --storage-type gp2 --tags Key=Name,Value=agendamento-4minds-postgres Key=Environment,Value=prod Key=FreeTier,Value=true

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n==================================" -ForegroundColor Green
    Write-Host "RDS PostgreSQL criado com sucesso!" -ForegroundColor Green
    Write-Host "==================================" -ForegroundColor Green
    Write-Host "`nRecursos criados:" -ForegroundColor Cyan
    Write-Host "- VPC ID: $vpcId" -ForegroundColor White
    Write-Host "- Subnet 1: $subnet1" -ForegroundColor White
    Write-Host "- Subnet 2: $subnet2" -ForegroundColor White
    Write-Host "- Security Group: $sgId" -ForegroundColor White
    Write-Host "- RDS Instance: agendamento-4minds-postgres" -ForegroundColor White
} else {
    Write-Host "`nErro ao criar RDS PostgreSQL" -ForegroundColor Red
}
