# Script para fazer deploy do Django na instância EC2
Write-Host "=== Deploy do Django na EC2 ===" -ForegroundColor Cyan

# Variáveis
$instanceId = "i-029805f836fb2f238"
$rdsEndpoint = "agendamento-4minds-postgres.cgr24gyuwi3d.us-east-1.rds.amazonaws.com"
$s3Bucket = "agendamento-4minds-static-abc123"

Write-Host "1. Verificando status da instância EC2..." -ForegroundColor Yellow
aws ec2 describe-instances --instance-ids $instanceId --query "Reservations[0].Instances[0].[InstanceId,State.Name,PublicIpAddress]" --output table

Write-Host "`n2. Verificando status do RDS..." -ForegroundColor Yellow
aws rds describe-db-instances --db-instance-identifier agendamento-4minds-postgres --query "DBInstances[0].[DBInstanceStatus,Endpoint.Address]" --output table

Write-Host "`n3. Criando arquivo de configuração..." -ForegroundColor Yellow
$configScript = @"
#!/bin/bash
echo '=== Configurando Django com RDS ==='

# Navegar para o diretório
cd /home/ubuntu/s_agendamento

# Criar .env
cat > .env << 'EOF'
# Database (RDS PostgreSQL)
DB_ENGINE=django.db.backends.postgresql
DB_NAME=agendamentos_db
DB_USER=postgres
DB_PASSWORD=4MindsAgendamento2025!SecureDB#Pass
DB_HOST=$rdsEndpoint
DB_PORT=5432

# AWS S3
AWS_STORAGE_BUCKET_NAME=$s3Bucket
AWS_S3_REGION_NAME=us-east-1
USE_S3=True

# CloudWatch Logs
CLOUDWATCH_LOG_GROUP=/aws/ec2/agendamento-4minds/django
AWS_REGION_NAME=us-east-1

# SNS Alerts
SNS_TOPIC_ARN=arn:aws:sns:us-east-1:295748148791:agendamento-4minds-alerts

# Django
DEBUG=False
ALLOWED_HOSTS=3.80.178.120,fourmindstech.com.br,localhost,127.0.0.1
SECRET_KEY=4MindsAgendamento2025!SecretKey#Django
EOF

echo 'Instalando dependências...'
pip install psycopg2-binary boto3

echo 'Executando migrações...'
python manage.py migrate

echo 'Criando superusuário...'
echo "from django.contrib.auth import get_user_model; User = get_user_model(); User.objects.create_superuser('admin', 'admin@4minds.com.br', 'admin123')" | python manage.py shell

echo 'Coletando arquivos estáticos...'
python manage.py collectstatic --noinput

echo 'Testando conexão...'
python manage.py check --database default

echo 'Reiniciando serviços...'
sudo systemctl restart gunicorn
sudo systemctl restart nginx

echo 'Testando aplicação...'
curl -I http://localhost:8000/

echo '✅ Deploy concluído!'
"@

# Salvar script temporário
$configScript | Out-File -FilePath "temp_config.sh" -Encoding UTF8

Write-Host "`n4. Enviando script para a instância..." -ForegroundColor Yellow
# Usar AWS Systems Manager para executar o script
aws ssm send-command --instance-ids $instanceId --document-name "AWS-RunShellScript" --parameters 'commands=["bash /home/ubuntu/s_agendamento/temp_config.sh"]'

Write-Host "`n5. Aguardando execução..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

Write-Host "`n6. Verificando logs..." -ForegroundColor Yellow
aws logs describe-log-streams --log-group-name "/aws/ec2/agendamento-4minds/django" --order-by LastEventTime --descending --max-items 1

Write-Host "`n==================================" -ForegroundColor Green
Write-Host "Deploy do Django iniciado!" -ForegroundColor Green
Write-Host "==================================" -ForegroundColor Green
Write-Host "Acesse: http://3.80.178.120" -ForegroundColor Cyan
Write-Host "Admin: http://3.80.178.120/admin" -ForegroundColor Cyan
Write-Host "Usuário: admin | Senha: admin123" -ForegroundColor Cyan

# Limpar arquivo temporário
Remove-Item "temp_config.sh" -ErrorAction SilentlyContinue
