# 🎯 SOLUÇÃO: Como Fazer Deploy do Terraform

## ⚠️ PROBLEMA IDENTIFICADO

O terminal atual está com um problema (comandos sendo prefixados com 'q').

**SOLUÇÃO:** Abra um **NOVO terminal limpo** e execute os comandos.

---

## ✅ STATUS ATUAL DA INFRAESTRUTURA AWS

### Recursos JÁ EXISTEM (17):

```
✅ VPC: vpc-089a1fa558a5426de
✅ Subnets: 3 (pública + 2 privadas)
✅ Internet Gateway: igw-030c5d0d1540f9245
✅ Route Tables
✅ Security Groups: 2 (EC2 + RDS)
✅ RDS PostgreSQL: sistema-agendamento-4minds-postgres.cgr24gyuwi3d.us-east-1.rds.amazonaws.com
✅ S3 Bucket: sistema-agendamento-4minds-static-files-a9fycn51
✅ CloudWatch Log Group
✅ SNS Topic
✅ DB Subnet Group
✅ S3 Versioning
✅ S3 Public Access Block
```

### Recursos FALTANDO (4):

```
❌ EC2 Instance t2.micro (servidor web)
❌ SSH Key Pair
❌ CloudWatch Alarm (CPU)
❌ CloudWatch Alarm (Memory)
```

---

## 🚀 SOLUÇÃO: Execute em Novo Terminal

### PASSO 1: Abra um NOVO PowerShell

- Clique no **Iniciar** do Windows
- Digite: **PowerShell**
- Clique em **Windows PowerShell**

### PASSO 2: Cole e Execute ESTE Comando Único

```powershell
cd C:\PROJETOS\TRABALHOS\STARTUP\4Minds\Sistemas\s_agendamento\aws-infrastructure; terraform apply -auto-approve
```

### PASSO 3: Aguarde

⏱️ **Tempo:** ~5-10 minutos

O Terraform irá criar:
1. SSH Key Pair (10s)
2. EC2 Instance (2-3 min)
3. CloudWatch Alarms (30s)
4. EC2 Bootstrap - user_data.sh (3-5 min)

### PASSO 4: Quando Terminar, Ver Outputs

```powershell
terraform output
```

Você verá:
```
ec2_public_ip = "54.xxx.xxx.xxx"
```

**Anote este IP!**

---

## ✅ APÓS DEPLOY COMPLETAR

### 1. Aguardar Bootstrap (5 min)

A EC2 está executando o script `user_data.sh` que:
- Instala Python, Nginx, PostgreSQL client
- Clona o repositório do GitHub
- Configura Django
- Executa migrações
- Inicia serviços

### 2. Testar Aplicação

```
Abra navegador: http://<EC2_IP>/agendamento/
```

### 3. Testar Admin

```
http://<EC2_IP>/agendamento/admin/
Usuário: admin
Senha: admin123
```

---

## 🌐 CONFIGURAR DNS (Depois)

No seu provedor de domínio:

```
Tipo: A
Nome: @
Valor: <EC2_IP>

Tipo: A
Nome: www  
Valor: <EC2_IP>
```

Depois acesse: `http://fourmindstech.com.br/agendamento/`

---

## 🔐 CONFIGURAR SSL (Após DNS)

```bash
ssh -i ~/.ssh/id_rsa ubuntu@fourmindstech.com.br
sudo certbot --nginx -d fourmindstech.com.br -d www.fourmindstech.com.br
```

---

## 🆘 SE DER ERRO NO TERRAFORM

### Erro: "execution halted"

**Causa:** Terminal com problema

**Solução:** Abra um NOVO terminal limpo e tente novamente

### Erro: "AWS credentials"

**Solução:**
```powershell
aws configure
```

### Erro: "resource already exists"

**Solução:**
```powershell
terraform destroy -auto-approve
terraform apply -auto-approve
```

---

## 📊 INFORMAÇÕES ÚTEIS

**RDS Endpoint (já existe):**
```
sistema-agendamento-4minds-postgres.cgr24gyuwi3d.us-east-1.rds.amazonaws.com
```

**S3 Bucket (já existe):**
```
sistema-agendamento-4minds-static-files-a9fycn51
```

**VPC (já existe):**
```
vpc-089a1fa558a5426de
```

---

## ✅ RESUMO SIMPLES

```
1. Abra NOVO PowerShell
2. Cole: cd C:\...\aws-infrastructure; terraform apply -auto-approve
3. Aguarde 10 minutos
4. Anote o EC2_IP
5. Teste: http://<EC2_IP>/agendamento/
6. Configure DNS
7. Configure SSL
8. ✅ Pronto!
```

---

**Documentação completa:** Ver `00_COMECE_AQUI.md`

**Suporte:** fourmindsorg@gmail.com

---

*Problema com terminal identificado. Use novo terminal limpo.* 🚀

