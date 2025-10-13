# 🚀 GUIA DE DEPLOY MANUAL - AWS Infrastructure

## ✅ PRÉ-REQUISITOS

Antes de começar, verifique:
- [ ] AWS CLI configurado (`aws sts get-caller-identity`)
- [ ] Terraform instalado (`terraform --version`)
- [ ] No diretório: `aws-infrastructure/`
- [ ] Arquivo `terraform.tfvars` configurado

---

## 📋 PASSO A PASSO

### PASSO 1: Inicializar Terraform ⏱️ ~2-3 minutos

```bash
terraform init
```

**O que faz:**
- Baixa providers AWS (~200MB)
- Baixa provider Random
- Inicializa backend local

**Output esperado:**
```
Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure.
```

✅ **Sucesso?** Prossiga para Passo 2  
❌ **Erro?** Verifique:
- Conexão com internet
- Espaço em disco (~500MB livre)
- Firewall/Antivírus bloqueando

---

### PASSO 2: Validar Configuração ⏱️ ~10 segundos

```bash
terraform validate
```

**O que faz:**
- Valida sintaxe dos arquivos .tf
- Verifica referências entre recursos
- Confirma que variáveis existem

**Output esperado:**
```
Success! The configuration is valid.
```

✅ **Sucesso?** Prossiga para Passo 3  
❌ **Erro?** Corrija o arquivo .tf indicado

---

### PASSO 3: Visualizar Plano ⏱️ ~30 segundos

```bash
terraform plan
```

**O que faz:**
- Mostra TODOS os recursos que serão criados
- Calcula mudanças necessárias
- **NÃO CRIA NADA** - apenas mostra o plano

**Output esperado:**
```
Plan: 15 to add, 0 to change, 0 to destroy.
```

**Recursos que serão criados (~15):**
1. VPC
2. Internet Gateway
3. Subnet Pública
4. 2 Subnets Privadas
5. Route Table + Association
6. 2 Security Groups (EC2 e RDS)
7. DB Subnet Group
8. RDS PostgreSQL (db.t2.micro)
9. EC2 Instance (t2.micro)
10. Key Pair
11. S3 Bucket
12. CloudWatch Log Group
13. SNS Topic + Subscription
14. 3 CloudWatch Alarms
15. Random String (para bucket)

**Revisar:**
- [ ] Instance types corretos (t2.micro, db.t2.micro)
- [ ] Região correta (us-east-1)
- [ ] Storage correto (20GB RDS, 30GB EC2)

✅ **Tudo OK?** Prossiga para Passo 4  
⚠️ **Dúvidas?** Revise o output antes de prosseguir

---

### PASSO 4: Aplicar Infraestrutura ⏱️ ~15-20 minutos

```bash
terraform apply
```

**O que faz:**
- Mostra o plano novamente
- Pede confirmação
- Cria TODOS os recursos na AWS
- Executa user_data.sh na EC2

**Confirmação:**
```
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: 
```

👉 **Digite:** `yes` (e pressione Enter)

**Timeline de criação:**

| Tempo | Recurso | Status |
|-------|---------|--------|
| 0:00 | Início | ⏳ |
| 0:30 | VPC + Subnets | ✅ |
| 1:00 | Security Groups | ✅ |
| 2:00 | S3 Bucket | ✅ |
| 3:00 | EC2 iniciando | ⏳ |
| 5:00 | EC2 rodando | ✅ |
| 5:30 | RDS iniciando | ⏳ |
| 15:00 | RDS disponível | ✅ |
| 16:00 | user_data.sh executando | ⏳ |
| 20:00 | Tudo concluído | ✅ |

**Aguarde pacientemente!** ☕ RDS demora ~8-12 minutos para ficar disponível.

**Output final esperado:**
```
Apply complete! Resources: 15 added, 0 changed, 0 destroyed.

Outputs:

application_url = "http://54.123.45.67"
ec2_public_ip = "54.123.45.67"
rds_endpoint = "sistema-agendamento-postgres.xxxxx.us-east-1.rds.amazonaws.com:5432"
s3_bucket_name = "sistema-agendamento-static-files-abc123"
ssh_command = "ssh -i ~/.ssh/id_rsa ubuntu@54.123.45.67"
```

✅ **Sucesso?** COPIE E SALVE ESSES OUTPUTS!  
❌ **Erro?** Veja seção de Troubleshooting abaixo

---

### PASSO 5: Salvar Outputs ⏱️ ~1 minuto

```bash
# Salvar todos os outputs em arquivo
terraform output > ../TERRAFORM_OUTPUTS.txt

# Ver output específico
terraform output ec2_public_ip
terraform output rds_endpoint
```

**IMPORTANTE:** Salve principalmente:
- `ec2_public_ip` - Para SSH e DNS
- `rds_endpoint` - Para configurar .env.production
- `s3_bucket_name` - Para configurar Django

---

## 🔍 VERIFICAÇÃO PÓS-DEPLOY

### 1. Verificar EC2

```bash
# SSH na instância
ssh -i ~/.ssh/id_rsa ubuntu@$(terraform output -raw ec2_public_ip)

# Ver logs do user_data
sudo tail -f /var/log/user-data.log

# Ver status dos serviços
app-status
```

### 2. Verificar RDS

```bash
# Testar conexão
aws rds describe-db-instances \
  --db-instance-identifier sistema-agendamento-postgres \
  --query 'DBInstances[0].DBInstanceStatus'
```

Deve retornar: `"available"`

### 3. Verificar S3

```bash
# Listar buckets
aws s3 ls | grep sistema-agendamento
```

### 4. Verificar CloudWatch

```bash
# Listar alarmes
aws cloudwatch describe-alarms --query 'MetricAlarms[*].AlarmName'
```

---

## 🌐 CONFIGURAR DNS

Após deploy bem-sucedido:

### 1. Obter IP da EC2

```bash
terraform output ec2_public_ip
```

Exemplo: `54.123.45.67`

### 2. Configurar no Provedor de Domínio

**Registro.br / GoDaddy / Cloudflare:**

```
Tipo: A
Nome: @
Valor: 54.123.45.67
TTL: 300

Tipo: A
Nome: www
Valor: 54.123.45.67
TTL: 300
```

### 3. Aguardar Propagação

```bash
# Verificar DNS (repita até funcionar)
nslookup fourmindstech.com.br

# Esperado:
# Name:    fourmindstech.com.br
# Address: 54.123.45.67
```

Tempo: **5-30 minutos**

### 4. Testar HTTP

```bash
curl http://fourmindstech.com.br/health/
```

Esperado: `{"status":"ok","service":"sistema-agendamento","version":"1.0.0"}`

### 5. Aguardar SSL

O Let's Encrypt será configurado automaticamente pelo user_data.sh após DNS propagar.

Aguarde mais ~2-5 minutos, depois teste:

```bash
curl https://fourmindstech.com.br/
```

---

## ⚙️ CONFIGURAÇÃO FINAL NO SERVIDOR

### 1. SSH na Instância

```bash
EC2_IP=$(terraform output -raw ec2_public_ip)
ssh -i ~/.ssh/id_rsa ubuntu@$EC2_IP
```

### 2. Gerar SECRET_KEY

```bash
python3 -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"
```

Copie a chave gerada.

### 3. Editar .env.production

```bash
sudo nano /home/django/app/.env.production
```

Atualizar:
```bash
SECRET_KEY=COLA_A_CHAVE_GERADA_ACIMA
EMAIL_HOST_PASSWORD=SEU_APP_PASSWORD_DO_GMAIL
```

### 4. Reiniciar Serviços

```bash
sudo supervisorctl restart gunicorn
sudo systemctl restart nginx
```

### 5. Verificar Status

```bash
app-status
```

---

## ✅ VALIDAÇÃO FINAL

### Checklist de Produção:

- [ ] **Infraestrutura**
  - [ ] `terraform apply` concluído sem erros
  - [ ] 15 recursos criados
  - [ ] Outputs salvos

- [ ] **Servidor EC2**
  - [ ] SSH funcionando
  - [ ] Nginx rodando (`sudo systemctl status nginx`)
  - [ ] Gunicorn rodando (`sudo supervisorctl status`)
  - [ ] user_data.sh completou (`cat /var/log/user-data.log`)

- [ ] **Banco RDS**
  - [ ] Status: available
  - [ ] Acessível da EC2

- [ ] **DNS**
  - [ ] DNS propagado (`nslookup fourmindstech.com.br`)
  - [ ] HTTP funcionando (`curl http://fourmindstech.com.br/health/`)
  - [ ] HTTPS funcionando (`curl https://fourmindstech.com.br/`)

- [ ] **Aplicação**
  - [ ] Health check OK: `/health/`
  - [ ] Admin acessível: `/admin/`
  - [ ] CSS carregando corretamente
  - [ ] Login funcionando

- [ ] **Monitoramento**
  - [ ] Email SNS confirmado
  - [ ] Alarmes ativos no CloudWatch
  - [ ] Logs aparecendo no CloudWatch

---

## 🐛 TROUBLESHOOTING

### Erro: "No valid credential sources found"

**Problema:** AWS CLI não configurado

**Solução:**
```bash
aws configure
# Forneça:
# - AWS Access Key ID
# - AWS Secret Access Key
# - Region: us-east-1
# - Output format: json
```

---

### Erro: "Error creating DB Instance: InvalidParameterValue"

**Problema:** db.t3.micro não está no Free Tier

**Solução:** Já corrigido no terraform.tfvars para `db.t2.micro`

Verifique:
```bash
grep db_instance_class terraform.tfvars
# Deve mostrar: db_instance_class = "db.t2.micro"
```

---

### Erro: "Error launching source instance: InsufficientInstanceCapacity"

**Problema:** AWS sem capacidade temporária na zona

**Solução:**
```bash
# Tentar novamente em alguns minutos
terraform apply

# Ou mudar availability zone em main.tf
```

---

### RDS demora muito (>20 min)

**Normal:** RDS pode demorar 10-15 minutos

**Verificar status:**
```bash
aws rds describe-db-instances \
  --db-instance-identifier sistema-agendamento-postgres \
  --query 'DBInstances[0].[DBInstanceStatus,Engine,EngineVersion]'
```

---

### SSH não conecta

**Verificar:**
```bash
# 1. Security Group permite SSH?
aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=sistema-agendamento-ec2*" \
  --query 'SecurityGroups[0].IpPermissions[?FromPort==`22`]'

# 2. EC2 está rodando?
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=sistema-agendamento-web-server" \
  --query 'Reservations[0].Instances[0].State.Name'

# Deve retornar: "running"
```

---

### Health check retorna 502/503

**Causa:** Gunicorn ainda não iniciou ou crashou

**Verificar:**
```bash
ssh ubuntu@EC2_IP
sudo supervisorctl status
sudo tail -100 /var/log/gunicorn/gunicorn.log
```

**Reiniciar se necessário:**
```bash
sudo supervisorctl restart gunicorn
```

---

## 💰 CUSTOS

### Primeiros 12 Meses: $0/mês

**Free Tier cobre:**
- ✅ EC2 t2.micro: 750h/mês
- ✅ RDS db.t2.micro: 750h/mês
- ✅ EBS: 30GB
- ✅ S3: 5GB
- ✅ Data Transfer: 15GB/mês
- ✅ CloudWatch: 10 alarmes

### Após 12 Meses: ~$25/mês

| Serviço | Custo |
|---------|-------|
| EC2 t2.micro | ~$8.50 |
| RDS db.t2.micro | ~$15.00 |
| EBS 30GB | ~$3.00 |
| S3 + Transfer | ~$1.50 |
| **TOTAL** | **~$28/mês** |

---

## 📞 SUPORTE

Dúvidas? Consulte:
- `../RESUMO_COMPLETO_FINAL.md`
- `README.md`
- `FREE_TIER_GUIDE.md`

---

## 🎯 PRÓXIMOS PASSOS

Após deploy bem-sucedido:

1. ✅ Configurar DNS
2. ✅ Configurar SECRET_KEY no servidor
3. ✅ Configurar EMAIL_HOST_PASSWORD
4. ✅ Validar aplicação
5. ✅ Configurar backup adicional
6. ✅ Monitorar uso do Free Tier

---

**Criado:** Outubro 2025  
**Status:** Pronto para uso  
**Tempo estimado total:** ~30-40 minutos

