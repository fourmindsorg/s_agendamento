# Serviços AWS Criados

## ✅ Instância EC2
- **Instance ID**: i-029805f836fb2f238
- **IP Público**: 3.80.178.120
- **IP Privado**: 10.0.1.110
- **Estado**: Running
- **Tipo**: t2.micro (Free Tier)

## ✅ S3 Bucket
- **Nome**: agendamento-4minds-static-abc123
- **Região**: us-east-1
- **Propósito**: Armazenamento de arquivos estáticos
- **Status**: Criado com sucesso

## ✅ SNS Topic
- **Nome**: agendamento-4minds-alerts
- **ARN**: arn:aws:sns:us-east-1:295748148791:agendamento-4minds-alerts
- **Propósito**: Alertas e notificações
- **Status**: Criado com sucesso

## ✅ CloudWatch Log Group
- **Nome**: /aws/ec2/agendamento-4minds/django
- **Propósito**: Logs da aplicação Django
- **Status**: Criado com sucesso

## ⚠️ RDS PostgreSQL
- **Status**: Não foi possível criar via AWS CLI
- **Motivo**: Requer configuração de VPC, subnets e security groups
- **Próximos Passos**: 
  - Criar via Console AWS ou
  - Usar banco local temporariamente

## Configuração Necessária no Django

Adicionar ao arquivo `.env` na instância EC2:

```env
# AWS S3
AWS_STORAGE_BUCKET_NAME=agendamento-4minds-static-abc123
AWS_S3_REGION_NAME=us-east-1
USE_S3=True

# CloudWatch Logs
CLOUDWATCH_LOG_GROUP=/aws/ec2/agendamento-4minds/django
AWS_REGION_NAME=us-east-1

# SNS Alerts
SNS_TOPIC_ARN=arn:aws:sns:us-east-1:295748148791:agendamento-4minds-alerts
```

## Comandos para Conectar na Instância

```bash
# SSH
ssh -i ~/.ssh/id_rsa ubuntu@3.80.178.120

# Verificar serviços
curl http://3.80.178.120/health/

# Ver logs
tail -f /var/log/nginx/error.log
tail -f /var/log/gunicorn/error.log
```

## Próximas Etapas

1. ✅ Instância EC2 criada e rodando
2. ✅ S3 Bucket criado
3. ✅ SNS Topic criado
4. ✅ CloudWatch Logs criado
5. ⚠️ RDS PostgreSQL (opcional - pode usar SQLite ou criar manualmente)
6. 🔲 Configurar Django para usar S3
7. 🔲 Configurar CloudWatch Logs
8. 🔲 Testar aplicação

## Custos Estimados (Free Tier)

- **EC2 t2.micro**: Incluído no Free Tier (750 horas/mês)
- **S3**: Incluído no Free Tier (5GB armazenamento, 20k GET, 2k PUT)
- **CloudWatch Logs**: Incluído no Free Tier (5GB ingestão, 5GB armazenamento)
- **SNS**: Incluído no Free Tier (1000 notificações email/mês)
- **Total Estimado**: $0/mês (dentro do Free Tier)

