# ⚡ INSTRUÇÕES PARA EXECUTAR O TERRAFORM

## 🎯 SITUAÇÃO ATUAL

✅ **TODO o código está configurado**  
✅ **TODO o Terraform está pronto**  
✅ **Alguns recursos AWS já existem** (VPC, RDS, S3, CloudWatch)  
❌ **Faltam criar:** EC2 Instance, SSH Key Pair, CloudWatch Alarms

---

## 🚀 EXECUTE ESTES COMANDOS (COPIE E COLE)

### Opção 1: Abra um NOVO CMD/PowerShell

**1. Abra o Windows PowerShell** (Botão Iniciar → Digite "PowerShell")

**2. Cole ESTE comando:**

```powershell
cd C:\PROJETOS\TRABALHOS\STARTUP\4Minds\Sistemas\s_agendamento\aws-infrastructure; terraform apply -auto-approve; terraform output
```

**3. Pressione ENTER**

**4. Aguarde ~10-15 minutos**

---

### Opção 2: Comando por Comando

Abra PowerShell e execute um por vez:

```powershell
# Comando 1: Ir para o diretório
cd C:\PROJETOS\TRABALHOS\STARTUP\4Minds\Sistemas\s_agendamento\aws-infrastructure

# Comando 2: Aplicar infraestrutura
terraform apply -auto-approve

# Comando 3: Ver resultados
terraform output
```

---

### Opção 3: Usar GitHub Actions (Não Precisa Terminal)

**1. Configure secrets:** 
```
https://github.com/fourmindsorg/s_agendamento/settings/secrets/actions
```

Adicione:
- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY
- DB_PASSWORD
- Outros 7 secrets (ver GITHUB_SECRETS_GUIA.md)

**2. Dispare workflow:**
```
https://github.com/fourmindsorg/s_agendamento/actions/workflows/deploy.yml
```
Clique "Run workflow"

---

## 📊 O QUE SERÁ CRIADO

```
Já Existem (17 recursos):
✅ VPC, Subnets, Security Groups
✅ RDS PostgreSQL
✅ S3 Bucket
✅ CloudWatch Logs
✅ SNS Topic

Serão Criados (4 recursos):
🔄 EC2 Instance t2.micro
🔄 SSH Key Pair
🔄 CloudWatch Alarm (CPU)
🔄 CloudWatch Alarm (Memory)

Tempo: ~5-10 minutos (rápido pois RDS já existe)
```

---

## ✅ APÓS EXECUTAR

Você verá algo assim:

```
Apply complete! Resources: 4 added, 0 changed, 0 destroyed.

Outputs:

ec2_public_ip = "54.123.45.67"
rds_endpoint = "sistema-agendamento-4minds-postgres...rds.amazonaws.com:5432"
application_url = "https://fourmindstech.com.br"
ssh_command = "ssh -i ~/.ssh/id_rsa ubuntu@54.123.45.67"
```

**Anote o EC2_IP!**

---

## 🧪 TESTAR APLICAÇÃO

```
Aguarde 5 minutos após terraform apply

Depois teste no navegador:
http://54.123.45.67/agendamento/
```

---

## 📞 Problemas?

**Email:** fourmindsorg@gmail.com  
**Docs:** Ver `00_COMECE_AQUI.md`

---

**Execute os comandos acima em um NOVO terminal!** 🚀

