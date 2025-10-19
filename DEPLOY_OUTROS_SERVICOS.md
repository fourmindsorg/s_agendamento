# Deploy dos Demais Serviços AWS

## Status Atual

✅ **Instância EC2 Criada**
- IP Público: 3.80.178.120
- IP Privado: 10.0.1.110
- Instance ID: i-029805f836fb2f238
- Estado: Running

## Serviços em Deploy

O módulo `aws-infrastructure/other-services/` está sendo executado para criar:

### 1. RDS PostgreSQL
- **Instance Class**: db.t4g.micro (Free Tier)
- **Engine**: PostgreSQL 14
- **Storage**: 20 GB
- **Database**: agendamentos_db
- **Username**: postgres
- **Multi-AZ**: Disabled (Free Tier)

### 2. S3 Bucket
- **Purpose**: Static files storage
- **Versioning**: Disabled
- **Public Access**: Blocked
- **Lifecycle**: Cleanup incomplete uploads after 7 days

### 3. CloudWatch
- **Log Group**: /aws/ec2/agendamento-4minds/django
- **Retention**: 7 days
- **Alarms**:
  - High CPU (EC2): Threshold 80%
  - High CPU (RDS): Threshold 80%
  - Low Storage (RDS): Threshold 2GB

### 4. SNS
- **Topic**: agendamento-4minds-alerts
- **Subscription**: fourmindsorg@gmail.com
- **Purpose**: Alertas de monitoramento

### 5. Subnets Privadas
- **Subnet 1**: 10.0.2.0/24 (AZ 1)
- **Subnet 2**: 10.0.3.0/24 (AZ 2)
- **Purpose**: RDS deployment

## Comandos Executados

```bash
cd aws-infrastructure/other-services
terraform init -upgrade
terraform plan -out=tfplan
terraform apply tfplan
```

## Próximos Passos

Após a criação dos recursos:

1. Conectar à instância EC2 via SSH
2. Configurar variáveis de ambiente com credenciais do RDS
3. Executar migrações do Django
4. Configurar coleta de logs para CloudWatch
5. Testar conectividade com RDS
6. Configurar backup automático

## Configuração do Django

Após deploy, atualizar o arquivo `.env` na instância EC2:

```env
# Database (RDS)
DB_ENGINE=django.db.backends.postgresql
DB_NAME=agendamentos_db
DB_USER=postgres
DB_PASSWORD=4MindsAgendamento2025!SecureDB#Pass
DB_HOST=<RDS_ENDPOINT>
DB_PORT=5432

# AWS S3
AWS_STORAGE_BUCKET_NAME=<S3_BUCKET_NAME>
AWS_S3_REGION_NAME=us-east-1

# Logs
CLOUDWATCH_LOG_GROUP=/aws/ec2/agendamento-4minds/django
```

## Verificação de Status

```bash
# Verificar RDS
aws rds describe-db-instances --db-instance-identifier agendamento-4minds-postgres

# Verificar S3
aws s3 ls | grep agendamento-4minds

# Verificar SNS
aws sns list-topics | grep agendamento-4minds

# Verificar CloudWatch
aws logs describe-log-groups --log-group-name-prefix /aws/ec2/agendamento-4minds
```

