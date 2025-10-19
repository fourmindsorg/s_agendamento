# 🔧 RESOLVER ERRO "missing server host" NO GITHUB ACTIONS

## ❌ **Problema Identificado:**
```
Error: missing server host
```

**Causa**: O GitHub Secret `EC2_HOST` não está configurado ou está vazio.

---

## 🎯 **SOLUÇÃO COMPLETA:**

### **PASSO 1: Configurar GitHub Secrets**

#### **1.1 Acessar GitHub Secrets**
1. Acesse: https://github.com/fourmindsorg/s_agendamento/settings/secrets/actions
2. Clique em **"New repository secret"** para cada um:

#### **1.2 Adicionar Secrets Obrigatórios**

##### **Secret 1: EC2_HOST**
- **Name**: `EC2_HOST`
- **Secret**: `3.80.178.120`

##### **Secret 2: EC2_USERNAME**
- **Name**: `EC2_USERNAME`
- **Secret**: `ubuntu`

##### **Secret 3: EC2_PORT**
- **Name**: `EC2_PORT`
- **Secret**: `22`

##### **Secret 4: EC2_SSH_KEY**
- **Name**: `EC2_SSH_KEY`
- **Secret**: Cole a chave privada SSH (veja PASSO 2)

### **PASSO 2: Gerar Chaves SSH na EC2**

#### **2.1 Acessar Console EC2**
1. Acesse: https://console.aws.amazon.com/ec2/
2. Vá para **Instances** → `i-029805f836fb2f238`
3. Clique em **Connect** → **EC2 Instance Connect**

#### **2.2 Executar Script de Geração de Chaves**
```bash
curl -s https://raw.githubusercontent.com/fourmindsorg/s_agendamento/main/gerar_chaves_ssh.sh | bash
```

#### **2.3 Copiar Chave Privada**
Após executar o script, você verá:
```
🔑 CHAVE PRIVADA PARA GITHUB SECRETS:
=====================================
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAABlwAAAAdzc2gtcn
...
-----END OPENSSH PRIVATE KEY-----
```

**Copie toda a chave privada** (incluindo as linhas `-----BEGIN OPENSSH PRIVATE KEY-----` e `-----END OPENSSH PRIVATE KEY-----`)

### **PASSO 3: Executar Deploy Manual na EC2**

Antes de testar o GitHub Actions, execute o deploy manual:

```bash
curl -s https://raw.githubusercontent.com/fourmindsorg/s_agendamento/main/corrigir_ssh_e_deploy.sh | bash
```

### **PASSO 4: Testar GitHub Actions**

#### **4.1 Executar Workflow**
1. Vá para: https://github.com/fourmindsorg/s_agendamento/actions
2. Clique em **"Deploy to EC2"**
3. Clique em **"Run workflow"**
4. Selecione branch **"main"**
5. Clique em **"Run workflow"**

#### **4.2 Verificar Logs**
1. Clique no workflow em execução
2. Clique em **"Deploy to EC2"**
3. Verifique se não há erros

---

## 🔧 **ALTERNATIVA: Gerar Chaves Localmente**

Se não conseguir executar na EC2:

### **1. Gerar Chaves no Windows**
```bash
# No PowerShell
ssh-keygen -t rsa -b 4096 -C "github-actions-deploy" -f C:\Users\%USERNAME%\.ssh\github_actions_key
```

### **2. Adicionar Chave Pública na EC2**
```bash
# Usar AWS CLI
aws ec2-instance-connect send-ssh-public-key \
  --instance-id i-029805f836fb2f238 \
  --availability-zone us-east-1a \
  --instance-os-user ubuntu \
  --ssh-public-key file://C:\Users\%USERNAME%\.ssh\github_actions_key.pub
```

### **3. Configurar GitHub Secrets**
- **EC2_SSH_KEY**: Conteúdo de `C:\Users\%USERNAME%\.ssh\github_actions_key`
- **EC2_HOST**: `3.80.178.120`
- **EC2_USERNAME**: `ubuntu`
- **EC2_PORT**: `22`

---

## ✅ **VERIFICAÇÃO:**

### **1. GitHub Secrets Configurados**
- ✅ `EC2_HOST`: `3.80.178.120`
- ✅ `EC2_USERNAME`: `ubuntu`
- ✅ `EC2_PORT`: `22`
- ✅ `EC2_SSH_KEY`: Chave privada SSH

### **2. Workflow Funcionando**
- ✅ Sem erro "missing server host"
- ✅ SSH conecta com sucesso
- ✅ Deploy executa sem erros

### **3. Aplicação Funcionando**
- ✅ http://3.80.178.120 responde
- ✅ Admin: http://3.80.178.120/admin
- ✅ Usuário: admin | Senha: admin123

---

## 🚨 **TROUBLESHOOTING:**

### **Problema: Ainda "missing server host"**
- Verifique se o secret `EC2_HOST` está configurado
- Confirme se o valor é exatamente `3.80.178.120`
- Verifique se não há espaços extras

### **Problema: SSH authentication failed**
- Execute o script de geração de chaves
- Verifique se a chave privada foi copiada corretamente
- Confirme se não há quebras de linha extras

### **Problema: Deploy falha**
- Execute deploy manual primeiro
- Verifique se a EC2 está rodando
- Confirme se os serviços estão ativos

---

## 🎯 **RESUMO RÁPIDO:**

1. **Configure GitHub Secrets** (EC2_HOST, EC2_USERNAME, EC2_PORT, EC2_SSH_KEY)
2. **Gere chaves SSH** na EC2
3. **Execute deploy manual** na EC2
4. **Teste GitHub Actions**

**Execute estes passos e o erro será resolvido!** 🚀
