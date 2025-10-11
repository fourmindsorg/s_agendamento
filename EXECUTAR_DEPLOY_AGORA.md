# ⚡ EXECUTAR DEPLOY AGORA - Instruções Simples

## 🎯 Execute ESTES comandos no seu terminal

### Abra PowerShell e execute:

```powershell
# 1. Ir para o diretório da infraestrutura
cd C:\PROJETOS\TRABALHOS\STARTUP\4Minds\Sistemas\s_agendamento\aws-infrastructure

# 2. Inicializar Terraform (se ainda não fez)
terraform init

# 3. Aplicar infraestrutura
terraform apply

# 4. Quando perguntar, digite: yes

# 5. AGUARDE ~15-20 minutos ☕
```

---

## ⏱️ O Que Vai Acontecer

```
00:00 - Você executa: terraform apply
00:01 - Mostra o que será criado (21 recursos)
00:02 - Pergunta: "Enter a value:" → Digite: yes
00:03 - Começa a criar recursos
        ├── VPC (30s)
        ├── Subnets (1 min)
        ├── Security Groups (1 min)
        ├── S3 Bucket (1 min)
        ├── RDS PostgreSQL (8-12 min) ⏰
        ├── EC2 Instance (2-3 min)
        └── CloudWatch (1 min)
00:20 - ✅ DEPLOY COMPLETO!
        Terraform mostra os outputs
```

---

## ✅ Após Completar

### 1. Ver Informações:

```powershell
terraform output
```

Você verá:
```
ec2_public_ip = "54.123.45.67"
rds_endpoint = "sistema-agendamento-4minds-postgres.xxx.us-east-1.rds.amazonaws.com"
s3_bucket_name = "sistema-agendamento-4minds-static-files-xxx"
```

### 2. Testar Aplicação:

```powershell
# Abrir no navegador
start http://54.123.45.67/agendamento/
```

### 3. Anotar IP para DNS:

```
IP da EC2: 54.123.45.67
```

---

## 🌐 Configurar DNS Depois

No seu provedor de domínio:

```
Tipo: A
Nome: @
Valor: <EC2_IP>

Tipo: A  
Nome: www
Valor: <EC2_IP>
```

---

## 🔐 Configurar SSL Depois (Após DNS)

```bash
ssh ubuntu@fourmindstech.com.br
sudo certbot --nginx -d fourmindstech.com.br -d www.fourmindstech.com.br
```

---

## 🆘 Se Der Erro

### "Error: credential configuration"
```powershell
# Configurar AWS
aws configure
```

### "Error: resource already exists"
```powershell
# Limpar e tentar novamente
terraform destroy
terraform apply
```

### "Permission denied"
```powershell
# Verificar credenciais AWS
aws sts get-caller-identity
```

---

## ✅ É ISSO!

**EXECUTE ESTES 4 COMANDOS:**

```powershell
cd C:\PROJETOS\TRABALHOS\STARTUP\4Minds\Sistemas\s_agendamento\aws-infrastructure
terraform init
terraform apply
# Digite: yes

# Aguarde ~20 minutos
# Depois: terraform output
```

**Pronto! 🚀**

