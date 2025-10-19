# EC2 Instance - Sistema de Agendamento

Este módulo cria apenas a instância EC2 com configuração básica.

## Recursos Criados

- VPC com Internet Gateway
- Subnet pública
- Security Group para EC2
- Key Pair para SSH
- Instância EC2 t2.micro (Free Tier)

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

- `ec2_public_ip`: IP público da instância
- `ec2_private_ip`: IP privado da instância
- `ec2_instance_id`: ID da instância
- `ssh_command`: Comando SSH para conectar
- `application_url`: URL da aplicação

## Próximos passos

Após criar a EC2, execute o módulo `other-services` para criar RDS, S3, etc.
