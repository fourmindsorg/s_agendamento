# 🎯 Guia Completo AWS Free Tier - Sistema de Agendamento

## 📋 Índice
1. [Visão Geral](#visão-geral)
2. [Recursos Configurados](#recursos-configurados)
3. [Limites do Free Tier](#limites-do-free-tier)
4. [Custos Esperados](#custos-esperados)
5. [Monitoramento de Uso](#monitoramento-de-uso)
6. [Boas Práticas](#boas-práticas)
7. [Troubleshooting](#troubleshooting)

---

## 🎯 Visão Geral

Este projeto foi **100% otimizado** para operar dentro do **AWS Free Tier**, permitindo que você execute um sistema completo de agendamento **sem custos** por 12 meses.

### ✅ O que está incluído (GRATUITO)

- **Aplicação Web Django** em EC2
- **Banco de Dados PostgreSQL** em RDS
- **Armazenamento de arquivos** em S3
- **Monitoramento e alertas** com CloudWatch
- **Notificações por email** com SNS
- **Domínio personalizado** (fourmindstech.com.br)

---

## 🔧 Recursos Configurados

### 1. **EC2 - Servidor Web** ✅ FREE TIER

```hcl
Tipo: t2.micro
CPU: 1 vCPU
RAM: 1 GB
Storage: 30 GB SSD (gp2)
Sistema: Ubuntu 22.04 LTS
```

**Limite Free Tier:** 750 horas/mês (≈ 31 dias)

**O que roda nele:**
- Nginx (servidor web)
- Gunicorn (servidor de aplicação Python)
- Django (framework web)
- Certbot/Let's Encrypt (SSL gratuito)

---

### 2. **RDS - Banco de Dados PostgreSQL** ✅ FREE TIER

```hcl
Tipo: db.t2.micro
CPU: 1 vCPU
RAM: 1 GB
Storage: 20 GB SSD (gp2)
Versão: PostgreSQL 15.4
```

**Limite Free Tier:**
- 750 horas/mês
- 20 GB de armazenamento
- 20 GB de backup (7 dias de retenção)

**Características:**
- Single-AZ (uma zona de disponibilidade)
- Sem criptografia (para evitar custos extras)
- Backups automáticos diários
- Manutenção automática de versões

---

### 3. **S3 - Armazenamento de Arquivos** ✅ FREE TIER

```hcl
Tipo: Standard Storage
Versionamento: Desabilitado (para economizar)
```

**Limite Free Tier:**
- 5 GB de armazenamento
- 20,000 requisições GET
- 2,000 requisições PUT

**Uso no projeto:**
- Arquivos estáticos CSS/JS
- Imagens do sistema
- Uploads de usuários

---

### 4. **CloudWatch - Monitoramento** ✅ FREE TIER

```hcl
Log Retention: 7 dias
Alarmes: 5 configurados
```

**Limite Free Tier:**
- 10 alarmes
- 5 GB de logs (ingestão + armazenamento)
- 1,000,000 API requests

**Alarmes configurados:**
1. CPU alta EC2 (>80%)
2. CPU alta RDS (>80%)
3. Storage baixo RDS (<2GB)

---

### 5. **SNS - Notificações** ✅ FREE TIER

```hcl
Tipo: Email
```

**Limite Free Tier:**
- 1,000 notificações de email/mês

**Quando você receberá emails:**
- CPU da EC2 alta
- CPU do RDS alta
- Espaço em disco baixo
- Problemas na aplicação

---

### 6. **VPC - Rede** ✅ SEMPRE GRATUITO

```hcl
CIDR: 10.0.0.0/16
Subnets:
  - Pública: 10.0.1.0/24 (EC2)
  - Privada 1: 10.0.2.0/24 (RDS)
  - Privada 2: 10.0.3.0/24 (RDS backup)
```

**Recursos gratuitos:**
- VPC
- Subnets
- Internet Gateway
- Route Tables
- Security Groups
- NACLs

---

## 📊 Limites do Free Tier

### ⏰ Período de Validade

O **AWS Free Tier** é válido por **12 meses** a partir da data de criação da sua conta AWS.

### 📈 Limites Mensais

| Serviço | Recurso | Limite Gratuito | Configurado |
|---------|---------|-----------------|-------------|
| **EC2** | Instância | 750h/mês | t2.micro |
| **EC2** | Storage | 30 GB | 30 GB |
| **RDS** | Instância | 750h/mês | db.t2.micro |
| **RDS** | Storage | 20 GB | 20 GB |
| **RDS** | Backup | 20 GB | 7 dias |
| **S3** | Storage | 5 GB | ~1 GB estimado |
| **S3** | GET | 20,000 req | ~5,000 estimado |
| **S3** | PUT | 2,000 req | ~500 estimado |
| **CloudWatch** | Logs | 5 GB | ~1 GB estimado |
| **CloudWatch** | Alarmes | 10 | 5 configurados |
| **SNS** | Emails | 1,000 | ~50 estimado |
| **Data Transfer** | OUT | 15 GB/mês | ~5 GB estimado |

---

## 💰 Custos Esperados

### 🎉 Primeiros 12 Meses: $0,00

Se você permanecer dentro dos limites do Free Tier e executar apenas UMA instância de cada serviço, o custo será **ZERO**.

### 📅 Após 12 Meses (Estimativa)

| Serviço | Custo Mensal (us-east-1) |
|---------|--------------------------|
| EC2 t2.micro | ~$8.50 |
| RDS db.t2.micro | ~$15.00 |
| S3 (5GB) | ~$0.12 |
| Data Transfer (15GB) | ~$1.35 |
| CloudWatch Logs | ~$0.50 |
| **TOTAL** | **~$25.47/mês** |

### 🔔 Alertas de Billing

Configure alertas no AWS Console:

1. Acesse **Billing Dashboard**
2. Clique em **Budgets**
3. Crie um budget com limite de $1.00
4. Configure alertas em 50%, 80% e 100%

---

## 📊 Monitoramento de Uso

### 1. **AWS Cost Explorer**

```
AWS Console → Billing → Cost Explorer
```

- Visualize custos diários
- Filtre por serviço
- Compare com mês anterior
- Identifique tendências

### 2. **Free Tier Usage**

```
AWS Console → Billing → Free Tier
```

- Veja uso atual de cada serviço
- Alertas quando próximo do limite
- Previsão de excedente

### 3. **CloudWatch Dashboard**

```
AWS Console → CloudWatch → Dashboards
```

- Métricas de CPU, memória, disco
- Gráficos de uso de recursos
- Logs da aplicação

### 4. **Comando Terraform**

```bash
cd aws-infrastructure
terraform show
```

---

## ✅ Boas Práticas

### 1. **Mantenha UMA instância de cada**

❌ **NÃO faça:**
```bash
# Criar múltiplas instâncias
terraform apply -var="instance_count=2"
```

✅ **FAÇA:**
```bash
# Manter apenas uma instância
# Esta configuração já está otimizada
```

### 2. **Desligue quando não usar (Desenvolvimento)**

Para **ambiente de desenvolvimento**, você pode desligar as instâncias quando não estiver usando:

```bash
# Desligar EC2 (economia de ~$8.50/mês após free tier)
aws ec2 stop-instances --instance-ids i-xxxxxxxxxxxxx

# Ligar EC2 novamente
aws ec2 start-instances --instance-ids i-xxxxxxxxxxxxx
```

⚠️ **Atenção:** RDS não pode ser "pausado" facilmente no Free Tier.

### 3. **Monitore logs regularmente**

```bash
# Ver logs da aplicação
aws logs tail /aws/ec2/sistema-agendamento/django --follow

# Ver últimos erros
aws logs filter-pattern "ERROR" --log-group-name /aws/ec2/sistema-agendamento/django
```

### 4. **Limpe recursos não utilizados**

```bash
# Listar snapshots (podem gerar custos)
aws ec2 describe-snapshots --owner-ids self

# Deletar snapshots antigos
aws ec2 delete-snapshot --snapshot-id snap-xxxxxxxxx
```

### 5. **Use CloudFront com cautela**

CloudFront tem Free Tier por 12 meses:
- 50 GB de transferência
- 2,000,000 requisições HTTP/HTTPS

Mas após expirar, pode gerar custos significativos. Por isso está **desabilitado** nesta configuração.

---

## 🛠️ Troubleshooting

### Problema: "Cobranças inesperadas"

**Causas comuns:**

1. **Múltiplas instâncias rodando**
   ```bash
   # Verificar instâncias EC2
   aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name,InstanceType]' --output table
   
   # Verificar instâncias RDS
   aws rds describe-db-instances --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus,DBInstanceClass]' --output table
   ```

2. **Snapshots antigos**
   ```bash
   aws ec2 describe-snapshots --owner-ids self
   ```

3. **Elastic IPs não associados**
   ```bash
   # IPs não associados custam $0.005/hora
   aws ec2 describe-addresses --query 'Addresses[?AssociationId==null]'
   ```

4. **Data Transfer excedido**
   - Verifique no Cost Explorer
   - Otimize imagens (compressão)
   - Use cache (CloudFlare gratuito)

### Problema: "Excedeu 750 horas"

**Causa:** Múltiplas instâncias ou instâncias rodando em múltiplas regiões.

**Solução:**
```bash
# Listar TODAS as regiões
for region in $(aws ec2 describe-regions --query 'Regions[].RegionName' --output text); do
  echo "Região: $region"
  aws ec2 describe-instances --region $region --query 'Reservations[*].Instances[*].[InstanceId,State.Name]' --output table
done
```

### Problema: "RDS sem espaço"

**Solução:**
```bash
# Conectar no RDS
psql -h <rds-endpoint> -U postgres -d agendamentos_db

# Verificar tamanho dos bancos
SELECT pg_size_pretty(pg_database_size('agendamentos_db'));

# Limpar logs antigos (se aplicável)
DELETE FROM logs WHERE created_at < NOW() - INTERVAL '30 days';
```

### Problema: "CloudWatch Logs excedeu 5GB"

**Solução:**
```bash
# Reduzir retenção para 3 dias
aws logs put-retention-policy \
  --log-group-name /aws/ec2/sistema-agendamento/django \
  --retention-in-days 3

# Ou deletar logs antigos manualmente
aws logs delete-log-stream \
  --log-group-name /aws/ec2/sistema-agendamento/django \
  --log-stream-name <stream-name>
```

---

## 📝 Checklist de Implantação

Antes de fazer `terraform apply`, verifique:

- [ ] Conta AWS criada há menos de 12 meses
- [ ] Free Tier ainda disponível (check no console)
- [ ] Região configurada: `us-east-1`
- [ ] Variáveis configuradas no `terraform.tfvars`
- [ ] Senha do banco alterada (não use a padrão!)
- [ ] Email de notificações configurado
- [ ] Domínio `fourmindstech.com.br` pronto
- [ ] DNS apontando para AWS (após deploy)
- [ ] Budget configurado no AWS Console ($1.00)

---

## 🎓 Recursos Adicionais

### Documentação Oficial
- [AWS Free Tier](https://aws.amazon.com/free/)
- [EC2 Pricing](https://aws.amazon.com/ec2/pricing/)
- [RDS Pricing](https://aws.amazon.com/rds/pricing/)
- [S3 Pricing](https://aws.amazon.com/s3/pricing/)

### Calculadoras
- [AWS Pricing Calculator](https://calculator.aws/)
- [AWS Free Tier Usage Dashboard](https://console.aws.amazon.com/billing/home#/freetier)

### Ferramentas de Monitoramento
- [AWS Cost Explorer](https://aws.amazon.com/aws-cost-management/aws-cost-explorer/)
- [AWS Budgets](https://aws.amazon.com/aws-cost-management/aws-budgets/)

---

## 📞 Suporte

Para dúvidas ou problemas:

1. **Verifique os logs:** CloudWatch Logs
2. **Consulte a documentação:** AWS Docs
3. **Entre em contato:** fourmindsorg@gmail.com

---

**Criado por:** 4Minds  
**Domínio:** fourmindstech.com.br  
**Última atualização:** Outubro 2025

---

## ⚠️ Aviso Legal

Este guia é fornecido "como está" sem garantias. Os preços e limites do AWS Free Tier podem mudar sem aviso prévio. Sempre consulte a [página oficial do AWS Free Tier](https://aws.amazon.com/free/) para informações atualizadas.

Monitore seu uso regularmente para evitar cobranças inesperadas.

