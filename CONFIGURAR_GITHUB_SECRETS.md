# 🔐 CONFIGURAR GITHUB SECRETS COM CHAVES SSH

## 🎯 **PASSO A PASSO COMPLETO:**

### **PASSO 1: Executar Script na EC2 para Gerar Chaves SSH**

#### **Opção A: Via Console EC2 (RECOMENDADO)**
1. Acesse: https://console.aws.amazon.com/ec2/
2. Vá para **Instances** → `i-029805f836fb2f238`
3. Clique em **Connect** → **EC2 Instance Connect**
4. Execute:
```bash
curl -s https://raw.githubusercontent.com/fourmindsorg/s_agendamento/main/corrigir_ssh_e_deploy.sh | bash
```

#### **Opção B: Via AWS CLI (Se funcionar)**
```bash
aws ssm send-command --instance-ids i-029805f836fb2f238 --document-name "AWS-RunShellScript" --parameters "commands=[\"curl -s https://raw.githubusercontent.com/fourmindsorg/s_agendamento/main/corrigir_ssh_e_deploy.sh | bash\"]"
```

### **PASSO 2: Obter as Chaves SSH**

Após executar o script, você verá algo assim:
```
🔑 CHAVE PÚBLICA PARA GITHUB SECRETS:
=====================================
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC... github-actions-deploy

🔑 CHAVE PRIVADA PARA GITHUB SECRETS:
=====================================
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAABlwAAAAdzc2gtcn
...
-----END OPENSSH PRIVATE KEY-----
```

### **PASSO 3: Configurar GitHub Secrets**

#### **3.1 Acessar GitHub Secrets**
1. Acesse: https://github.com/fourmindsorg/s_agendamento
2. Clique em **Settings** (configurações)
3. No menu lateral, clique em **Secrets and variables** → **Actions**

#### **3.2 Adicionar/Atualizar Secrets**
Clique em **New repository secret** para cada um:

##### **Secret 1: EC2_SSH_KEY**
- **Name**: `EC2_SSH_KEY`
- **Secret**: Cole a **CHAVE PRIVADA** completa (incluindo `-----BEGIN OPENSSH PRIVATE KEY-----` e `-----END OPENSSH PRIVATE KEY-----`)

##### **Secret 2: EC2_HOST**
- **Name**: `EC2_HOST`
- **Secret**: `3.80.178.120`

##### **Secret 3: EC2_USERNAME**
- **Name**: `EC2_USERNAME`
- **Secret**: `ubuntu`

##### **Secret 4: EC2_PORT**
- **Name**: `EC2_PORT`
- **Secret**: `22`

### **PASSO 4: Atualizar Workflow GitHub Actions**

#### **4.1 Acessar Workflow**
1. Vá para: https://github.com/fourmindsorg/s_agendamento/.github/workflows/deploy.yml
2. Clique em **Edit** (lápis)

#### **4.2 Atualizar Configuração SSH**
```yaml
- name: Deploy to EC2
  uses: appleboy/ssh-action@v1.0.0
  with:
    host: ${{ secrets.EC2_HOST }}
    username: ${{ secrets.EC2_USERNAME }}
    key: ${{ secrets.EC2_SSH_KEY }}
    port: ${{ secrets.EC2_PORT }}
    script: |
      cd /home/ubuntu/s_agendamento
      git pull origin main
      source .venv/bin/activate
      pip install -r requirements.txt
      python manage.py migrate
      python manage.py collectstatic --noinput
      sudo systemctl restart gunicorn
      sudo systemctl restart nginx
```

#### **4.3 Salvar e Commit**
1. Clique em **Commit changes**
2. Adicione mensagem: `fix: Update SSH configuration for GitHub Actions`
3. Clique em **Commit changes**

### **PASSO 5: Testar GitHub Actions**

#### **5.1 Executar Workflow**
1. Vá para: https://github.com/fourmindsorg/s_agendamento/actions
2. Clique em **Deploy to EC2**
3. Clique em **Run workflow**
4. Selecione branch **main**
5. Clique em **Run workflow**

#### **5.2 Verificar Logs**
1. Clique no workflow em execução
2. Clique em **Deploy to EC2**
3. Verifique se não há erros de SSH

---

## 🔧 **ALTERNATIVA: Gerar Chaves SSH Localmente**

Se não conseguir executar o script na EC2:

### **1. Gerar Chaves no Windows**
```bash
# No PowerShell ou CMD
ssh-keygen -t rsa -b 4096 -C "github-actions-deploy" -f C:\Users\%USERNAME%\.ssh\github_actions_key
```

### **2. Adicionar Chave Pública na EC2**
```bash
# Usar AWS CLI para adicionar chave
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

## ✅ **VERIFICAÇÃO FINAL**

### **1. Testar SSH Localmente**
```bash
# Testar conexão SSH
ssh -i C:\Users\%USERNAME%\.ssh\github_actions_key ubuntu@3.80.178.120
```

### **2. Testar GitHub Actions**
1. Execute o workflow
2. Verifique se não há erros de SSH
3. Confirme se o deploy foi executado

### **3. Testar Aplicação**
```bash
# Testar aplicação
curl -I http://3.80.178.120/
```

---

## 🚨 **TROUBLESHOOTING**

### **Problema: SSH ainda falha**
- Verifique se as chaves foram copiadas corretamente
- Confirme se não há espaços extras nas chaves
- Teste SSH localmente primeiro

### **Problema: GitHub Actions não executa**
- Verifique se todos os secrets estão configurados
- Confirme se o workflow está no branch correto
- Verifique os logs do GitHub Actions

### **Problema: Deploy falha**
- Verifique se a EC2 está rodando
- Confirme se os serviços estão ativos
- Verifique os logs da aplicação

---

## 🎯 **RESUMO RÁPIDO:**

1. **Execute o script** na EC2 para gerar chaves
2. **Copie as chaves** mostradas no terminal
3. **Configure GitHub Secrets** com as chaves
4. **Atualize o workflow** se necessário
5. **Teste o GitHub Actions**

**Siga estes passos e o SSH funcionará perfeitamente!** 🚀
