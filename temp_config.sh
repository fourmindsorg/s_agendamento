#!/bin/bash
echo '=== Configurando Django com RDS ==='

# Navegar para o diretÃ³rio
cd /home/ubuntu/s_agendamento

# Criar .env
cat > .env << 'EOF'
# Database (RDS PostgreSQL)
DB_ENGINE=django.db.backends.postgresql
DB_NAME=agendamentos_db
DB_USER=postgres
DB_PASSWORD=4MindsAgendamento2025!SecureDB#Pass
DB_HOST=agendamento-4minds-postgres.cgr24gyuwi3d.us-east-1.rds.amazonaws.com
DB_PORT=5432

# AWS S3
AWS_STORAGE_BUCKET_NAME=agendamento-4minds-static-abc123
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

echo 'Instalando dependÃªncias...'
pip install psycopg2-binary boto3

echo 'Executando migraÃ§Ãµes...'
python manage.py migrate

echo 'Criando superusuÃ¡rio...'
echo "from django.contrib.auth import get_user_model; User = get_user_model(); User.objects.create_superuser('admin', 'admin@4minds.com.br', 'admin123')" | python manage.py shell

echo 'Coletando arquivos estÃ¡ticos...'
python manage.py collectstatic --noinput

echo 'Testando conexÃ£o...'
python manage.py check --database default

echo 'Reiniciando serviÃ§os...'
sudo systemctl restart gunicorn
sudo systemctl restart nginx

echo 'Testando aplicaÃ§Ã£o...'
curl -I http://localhost:8000/

echo 'âœ… Deploy concluÃ­do!'
