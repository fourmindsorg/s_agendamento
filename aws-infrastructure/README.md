# 🚀 AWS Infrastructure - Sistema de Agendamento

## 📋 Visão Geral

Infraestrutura completa em Terraform para o **Sistema de Agendamento 4Minds**, otimizada para operar **100% no AWS Free Tier** por 12 meses.

### ✨ Características

- ✅ **Zero custos** nos primeiros 12 meses (Free Tier)
- ✅ **Infraestrutura como Código** (Terraform)
- ✅ **Alta disponibilidade** com VPC dedicada
- ✅ **Monitoramento completo** com CloudWatch
- ✅ **Notificações automáticas** via SNS/Email
- ✅ **Domínio personalizado** (fourmindstech.com.br)
- ✅ **SSL/HTTPS gratuito** via Let's Encrypt

---

## 🏗️ Arquitetura

```
┌─────────────────────────────────────────────────────────────┐
│                         Internet                              │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
            ┌─────────────────┐
            │ fourmindstech.  │
            │   com.br        │
            │   (DNS)         │
            └────────┬────────┘
                     │
                     ▼
┌────────────────────────────────────────────────────────────┐
│                         AWS VPC                             │
│                     (10.0.0.0/16)                          │
│                                                            │
│  ┌─────────────────────────────────────────────────┐     │
│  │         Public Subnet (10.0.1.0/24)             │     │
│  │                                                  │     │
│  │  ┌──────────────────────────────────────┐      │     │
│  │  │         EC2 t2.micro                 │      │     │
│  │  │  - Ubuntu 22.04 LTS                  │      │     │
│  │  │  - Nginx                             │      │     │
│  │  │  - Gunicorn + Django                 │      │     │
│  │  │  - 30GB EBS SSD                      │      │     │
│  │  │  - FREE TIER: 750h/mês               │      │     │
│  │  └──────────────────────────────────────┘      │     │
│  │                                                  │     │
│  └────────────┬─────────────────────────────────────┘     │
│               │                                            │
│               │ Private Network (10.0.0.0/16)             │
│               │                                            │
│  ┌────────────▼─────────────────────────────────────┐     │
│  │  Private Subnets (10.0.2.0/24, 10.0.3.0/24)     │     │
│  │                                                  │     │
│  │  ┌──────────────────────────────────────┐      │     │
│  │  │    RDS PostgreSQL db.t2.micro        │      │     │
│  │  │  - PostgreSQL 15.4                   │      │     │
│  │  │  - 20GB SSD (gp2)                    │      │     │
│  │  │  - FREE TIER: 750h/mês               │      │     │
│  │  └──────────────────────────────────────┘      │     │
│  │                                                  │     │
│  └──────────────────────────────────────────────────┘     │
│                                                            │
└────────────────────────────────────────────────────────────┘

External Services:
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│  S3 Bucket   │  │  CloudWatch  │  │     SNS      │
│  - Static    │  │  - Logs      │  │  - Alerts    │
│  - 5GB       │  │  - Alarms    │  │  - Email     │
│  - FREE TIER │  │  - FREE TIER │  │  - FREE TIER │
└──────────────┘  └──────────────┘  └──────────────┘
```

---

## 📦 Recursos Criados

### Rede (VPC)
- **VPC** dedicada (10.0.0.0/16)
- **1 Subnet Pública** (10.0.1.0/24) - para EC2
- **2 Subnets Privadas** (10.0.2.0/24, 10.0.3.0/24) - para RDS
- **Internet Gateway**
- **Route Tables**
- **Security Groups** (EC2 e RDS)

### Computação
- **EC2 t2.micro** (Ubuntu 22.04 LTS)
  - 1 vCPU, 1GB RAM
  - 30GB EBS SSD (gp2)
  - Nginx + Gunicorn + Django
  - FREE TIER: 750 horas/mês

### Banco de Dados
- **RDS PostgreSQL db.t2.micro**
  - PostgreSQL 15.4
  - 1 vCPU, 1GB RAM
  - 20GB SSD (gp2)
  - Backups automáticos (7 dias)
  - FREE TIER: 750 horas/mês

### Armazenamento
- **S3 Bucket** para arquivos estáticos
  - FREE TIER: 5GB storage
  - FREE TIER: 20,000 GET requests
  - FREE TIER: 2,000 PUT requests

### Monitoramento
- **CloudWatch Logs**
  - Retenção: 7 dias
  - FREE TIER: 5GB logs
- **5 CloudWatch Alarms**
  - EC2 CPU alta
  - RDS CPU alta
  - RDS storage baixo
  - FREE TIER: 10 alarmes

### Notificações
- **SNS Topic** para alertas
- **Email subscription** automático
- FREE TIER: 1,000 emails/mês

---

## 🚀 Quick Start

### Pré-requisitos

1. **Conta AWS** (com Free Tier ativo)
2. **Terraform** >= 1.0 instalado
3. **AWS CLI** configurado
4. **Chave SSH** gerada

### Instalação

```bash
# 1. Clonar o repositório
git clone <repository-url>
cd aws-infrastructure

# 2. Configurar credenciais AWS
aws configure

# 3. Copiar arquivo de configuração
cp terraform.tfvars.example terraform.tfvars

# 4. Editar variáveis (IMPORTANTE: alterar senha!)
nano terraform.tfvars
# Altere:
# - db_password (use senha forte!)
# - notification_email (seu email)
# - domain_name (seu domínio)

# 5. Inicializar Terraform
terraform init

# 6. Validar configuração
terraform validate

# 7. Ver plano de execução
terraform plan

# 8. Aplicar infraestrutura
terraform apply
# Digite 'yes' quando solicitado

# 9. Aguardar conclusão (~10-15 minutos)
# Terraform criará todos os recursos

# 10. Obter informações
terraform output
```

### Outputs Importantes

Após `terraform apply`, você receberá:

```bash
ec2_public_ip       = "3.80.178.120"
application_url     = "http://fourmindstech.com.br"
rds_endpoint        = "sistema-agendamento-postgres.xxxxx.us-east-1.rds.amazonaws.com"
ssh_command         = "ssh -i ~/.ssh/id_rsa ubuntu@3.80.178.120"
s3_bucket_name      = "sistema-agendamento-static-files-abc123"
```

---

## 🌐 Configuração do Domínio

### 1. Obter IP Público da EC2

```bash
terraform output ec2_public_ip
# Resultado: 3.80.178.120
```

### 2. Configurar DNS

No seu provedor de domínio (ex: Registro.br, GoDaddy, Cloudflare):

```
Tipo: A
Nome: @
Valor: 3.80.178.120
TTL: 300

Tipo: A
Nome: www
Valor: 3.80.178.120
TTL: 300
```

### 3. Verificar DNS

```bash
# Aguardar propagação (5-30 minutos)
nslookup fourmindstech.com.br

# Testar acesso
curl http://fourmindstech.com.br
```

### 4. Configurar SSL (Automático)

O servidor instalará automaticamente certificado SSL via Let's Encrypt:

```bash
# SSH na instância
ssh -i ~/.ssh/id_rsa ubuntu@$(terraform output -raw ec2_public_ip)

# Verificar status do Certbot
sudo certbot certificates

# Testar HTTPS
curl https://fourmindstech.com.br
```

---

## 📊 Monitoramento

### CloudWatch Dashboard

Acesse o AWS Console:
```
Services → CloudWatch → Dashboards
```

### Ver Logs da Aplicação

```bash
# Via AWS CLI
aws logs tail /aws/ec2/sistema-agendamento/django --follow

# Via SSH
ssh ubuntu@$(terraform output -raw ec2_public_ip)
sudo journalctl -u gunicorn -f
```

### Verificar Alarmes

```bash
aws cloudwatch describe-alarms
```

### Receber Notificações

1. Confirme o email enviado pela AWS (após apply)
2. Você receberá alertas quando:
   - CPU EC2 > 80%
   - CPU RDS > 80%
   - Storage RDS < 2GB

---

## 💰 Custos e Free Tier

### Durante os Primeiros 12 Meses

**Custo Total: $0/mês** ✅

Todos os recursos estão dentro do AWS Free Tier:
- EC2 t2.micro: 750h/mês (≈ 31 dias) ✅
- RDS db.t2.micro: 750h/mês ✅
- EBS: 30GB SSD ✅
- S3: 5GB storage ✅
- Data Transfer: 15GB/mês ✅

### Após 12 Meses

**Custo Estimado: ~$25/mês**

| Serviço | Custo Mensal |
|---------|--------------|
| EC2 t2.micro | ~$8.50 |
| RDS db.t2.micro | ~$15.00 |
| EBS 30GB | ~$3.00 |
| S3 + Transfer | ~$1.50 |
| **TOTAL** | **~$28.00** |

### Monitorar Custos

```bash
# Configurar alerta de billing
aws budgets create-budget \
  --account-id $(aws sts get-caller-identity --query Account --output text) \
  --budget file://budget.json \
  --notifications-with-subscribers file://notifications.json
```

---

## 🔒 Segurança

### Security Groups

**EC2 Security Group:**
- SSH (22): 0.0.0.0/0 ⚠️ (altere para seu IP)
- HTTP (80): 0.0.0.0/0 ✅
- HTTPS (443): 0.0.0.0/0 ✅
- Gunicorn (8000): 10.0.0.0/16 ✅

**RDS Security Group:**
- PostgreSQL (5432): Apenas da EC2 ✅

### Recomendações

1. **Restringir SSH:**
   ```hcl
   # terraform.tfvars
   allowed_cidr_blocks = ["SEU_IP/32"]
   ```

2. **Rotacionar Senhas:**
   ```bash
   # Alterar senha do RDS
   aws rds modify-db-instance \
     --db-instance-identifier sistema-agendamento-postgres \
     --master-user-password "NOVA_SENHA_FORTE"
   ```

3. **Habilitar MFA:**
   ```bash
   # No AWS Console
   IAM → Users → Security credentials → MFA
   ```

4. **Backup Manual:**
   ```bash
   # Criar snapshot do RDS
   aws rds create-db-snapshot \
     --db-instance-identifier sistema-agendamento-postgres \
     --db-snapshot-identifier manual-backup-$(date +%Y%m%d)
   ```

---

## 🛠️ Comandos Úteis

### Gerenciamento Terraform

```bash
# Verificar estado
terraform show

# Listar recursos
terraform state list

# Ver output específico
terraform output ec2_public_ip

# Destruir infraestrutura (CUIDADO!)
terraform destroy

# Atualizar um recurso específico
terraform apply -target=aws_instance.web_server

# Importar recurso existente
terraform import aws_instance.web_server i-1234567890abcdef0
```

### Gerenciamento AWS

```bash
# Ver instâncias EC2
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress]' --output table

# Ver instâncias RDS
aws rds describe-db-instances --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus]' --output table

# Ver buckets S3
aws s3 ls

# Ver alarmes CloudWatch
aws cloudwatch describe-alarms --query 'MetricAlarms[*].[AlarmName,StateValue]' --output table
```

### Acesso SSH

```bash
# Conectar via SSH
ssh -i ~/.ssh/id_rsa ubuntu@$(terraform output -raw ec2_public_ip)

# Copiar arquivo para servidor
scp -i ~/.ssh/id_rsa file.txt ubuntu@$(terraform output -raw ec2_public_ip):~/

# Executar comando remoto
ssh -i ~/.ssh/id_rsa ubuntu@$(terraform output -raw ec2_public_ip) "df -h"
```

---

## 🐛 Troubleshooting

### Erro: "Invalid credentials"

```bash
# Verificar credenciais AWS
aws sts get-caller-identity

# Reconfigurar AWS CLI
aws configure
```

### Erro: "Quota exceeded"

```bash
# Verificar limites da conta
aws service-quotas get-service-quota \
  --service-code ec2 \
  --quota-code L-1216C47A

# Solicitar aumento de quota
aws service-quotas request-service-quota-increase \
  --service-code ec2 \
  --quota-code L-1216C47A \
  --desired-value 20
```

### Erro: "Insufficient permissions"

```bash
# Verificar permissões do usuário IAM
aws iam get-user-policy \
  --user-name seu-usuario \
  --policy-name sua-policy

# Necessário: PowerUserAccess ou AdministratorAccess
```

### RDS não inicia

```bash
# Ver logs do RDS
aws rds describe-db-log-files \
  --db-instance-identifier sistema-agendamento-postgres

# Download do log
aws rds download-db-log-file-portion \
  --db-instance-identifier sistema-agendamento-postgres \
  --log-file-name error/postgresql.log
```

### EC2 não responde

```bash
# Ver console output
aws ec2 get-console-output \
  --instance-id $(terraform output -raw ec2_instance_id)

# Reiniciar instância
aws ec2 reboot-instances \
  --instance-ids $(terraform output -raw ec2_instance_id)
```

---

## 📚 Documentação Adicional

### Arquivos de Referência

- [`FREE_TIER_GUIDE.md`](./FREE_TIER_GUIDE.md) - Guia completo do Free Tier
- [`ALTERACOES_FREE_TIER.md`](./ALTERACOES_FREE_TIER.md) - Log de alterações
- [`terraform.tfvars.example`](./terraform.tfvars.example) - Exemplo de configuração

### Documentação AWS

- [AWS Free Tier](https://aws.amazon.com/free/)
- [EC2 User Guide](https://docs.aws.amazon.com/ec2/)
- [RDS User Guide](https://docs.aws.amazon.com/rds/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

---

## 🤝 Contribuindo

1. Fork o projeto
2. Crie uma branch: `git checkout -b feature/nova-funcionalidade`
3. Commit suas mudanças: `git commit -m 'Adiciona nova funcionalidade'`
4. Push para a branch: `git push origin feature/nova-funcionalidade`
5. Abra um Pull Request

---

## 📝 Licença

Este projeto está sob a licença especificada no arquivo [LICENSE](../LICENSE).

---

## 📞 Suporte

### Contato
- **Email:** fourmindsorg@gmail.com
- **Domínio:** fourmindstech.com.br
- **Projeto:** Sistema de Agendamento 4Minds
- **Repositório:** https://github.com/fourmindsorg/s_agendamento

### Links Úteis
- [AWS Support](https://aws.amazon.com/support)
- [Terraform Community](https://discuss.hashicorp.com/c/terraform-core)
- [AWS Free Tier FAQ](https://aws.amazon.com/free/free-tier-faqs/)

---

## 🎯 Checklist de Deploy

Antes de fazer deploy, verifique:

- [ ] Conta AWS criada (Free Tier ativo)
- [ ] AWS CLI configurado
- [ ] Terraform instalado (>= 1.0)
- [ ] Arquivo `terraform.tfvars` configurado
- [ ] Senha do banco alterada (FORTE!)
- [ ] Email de notificações configurado
- [ ] Domínio pronto (fourmindstech.com.br)
- [ ] Budget configurado no AWS Console
- [ ] Backup strategy planejado
- [ ] Documentação lida

---

**Criado por:** 4Minds  
**Última atualização:** Outubro 2025  
**Versão:** 2.0 (Free Tier Optimized)

🚀 **Happy Deploying!**

