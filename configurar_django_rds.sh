#!/bin/bash

# Script para configurar Django com RDS PostgreSQL
# Execute este script na instância EC2

echo "=== Configurando Django com RDS PostgreSQL ==="

# Variáveis do RDS
RDS_ENDPOINT="agendamento-4minds-postgres.cgr24gyuwi3d.us-east-1.rds.amazonaws.com"
RDS_PORT="5432"
RDS_DB_NAME="agendamentos_db"
RDS_USERNAME="postgres"
RDS_PASSWORD="4MindsAgendamento2025!SecureDB#Pass"

# Variáveis do S3
S3_BUCKET="agendamento-4minds-static-abc123"
S3_REGION="us-east-1"

# Variáveis do SNS
SNS_TOPIC_ARN="arn:aws:sns:us-east-1:295748148791:agendamento-4minds-alerts"

# Variáveis do CloudWatch
CLOUDWATCH_LOG_GROUP="/aws/ec2/agendamento-4minds/django"

echo "1. Navegando para o diretório do projeto..."
cd /home/ubuntu/s_agendamento

echo "2. Criando arquivo .env com credenciais do RDS..."
cat > .env << EOF
# Database (RDS PostgreSQL)
DB_ENGINE=django.db.backends.postgresql
DB_NAME=$RDS_DB_NAME
DB_USER=$RDS_USERNAME
DB_PASSWORD=$RDS_PASSWORD
DB_HOST=$RDS_ENDPOINT
DB_PORT=$RDS_PORT

# AWS S3
AWS_STORAGE_BUCKET_NAME=$S3_BUCKET
AWS_S3_REGION_NAME=$S3_REGION
USE_S3=True

# CloudWatch Logs
CLOUDWATCH_LOG_GROUP=$CLOUDWATCH_LOG_GROUP
AWS_REGION_NAME=$S3_REGION

# SNS Alerts
SNS_TOPIC_ARN=$SNS_TOPIC_ARN

# Django
DEBUG=False
ALLOWED_HOSTS=3.80.178.120,fourmindstech.com.br,localhost,127.0.0.1
SECRET_KEY=4MindsAgendamento2025!SecretKey#Django
EOF

echo "3. Instalando dependências Python..."
pip install -r requirements.txt

echo "4. Instalando psycopg2 para PostgreSQL..."
pip install psycopg2-binary

echo "5. Instalando boto3 para AWS..."
pip install boto3

echo "6. Executando migrações do banco de dados..."
python manage.py migrate

echo "7. Criando superusuário (opcional)..."
echo "from django.contrib.auth import get_user_model; User = get_user_model(); User.objects.create_superuser('admin', 'admin@4minds.com.br', 'admin123')" | python manage.py shell

echo "8. Coletando arquivos estáticos..."
python manage.py collectstatic --noinput

echo "9. Testando conexão com o banco..."
python manage.py check --database default

echo "10. Reiniciando serviços..."
sudo systemctl restart gunicorn
sudo systemctl restart nginx

echo "11. Verificando status dos serviços..."
sudo systemctl status gunicorn --no-pager
sudo systemctl status nginx --no-pager

echo "12. Testando aplicação..."
curl -I http://localhost:8000/

echo "=================================="
echo "✅ Configuração do Django concluída!"
echo "=================================="
echo "Aplicação disponível em: http://3.80.178.120"
echo "Admin: http://3.80.178.120/admin"
echo "Usuário: admin"
echo "Senha: admin123"
