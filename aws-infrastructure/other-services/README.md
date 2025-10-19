# Other Services - Sistema de Agendamento

Este módulo cria os demais serviços AWS (RDS, S3, CloudWatch, SNS, etc.).

## Pré-requisitos

- Instância EC2 deve estar criada (módulo `ec2-only`)
- VPC e subnets devem existir

## Recursos Criados

- RDS PostgreSQL (db.t4g.micro)
- S3 Bucket para arquivos estáticos
- CloudWatch Logs e Alarmes
- SNS Topic para alertas
- Security Groups adicionais

## Como usar

```bash
# Inicializar Terraform
terraform init

# Ver o plano
terraform plan

# Aplicar as mudanças
terraform apply

# Ver outputs
terraform output
```

## Outputs

- `rds_endpoint`: Endpoint do banco de dados
- `rds_port`: Porta do banco de dados
- `rds_database_name`: Nome do banco
- `s3_bucket_name`: Nome do bucket S3
- `database_connection_string`: String de conexão completa

## Configuração

Edite `terraform.tfvars` para personalizar as configurações.
