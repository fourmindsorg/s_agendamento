# 🔐 RESOLVER SSH AUTHENTICATION FAILED

## ❌ **Problema:**
```
SSH Authentication Failed: ssh: handshake failed: ssh: unable to authenticate, attempted methods [none publickey], no supported methods remain
```

## 🎯 **SOLUÇÕES (Escolha uma):**

---

## **SOLUÇÃO 1: Deploy Manual via Console EC2 (RECOMENDADO)**

### **Passo 1: Acessar Console EC2**
1. Acesse: https://console.aws.amazon.com/ec2/
2. Vá para **Instances**
3. Selecione a instância `i-029805f836fb2f238`
4. Clique em **Connect** → **EC2 Instance Connect**

### **Passo 2: Executar Deploy Completo**
```bash
# Baixar e executar script de deploy
curl -s https://raw.githubusercontent.com/fourmindsorg/s_agendamento/main/deploy_manual_github_actions.sh | bash
```

### **Passo 3: Verificar Resultado**
```bash
# Testar aplicação
curl -I http://3.80.178.120/
```

---

## **SOLUÇÃO 2: Corrigir SSH e Usar GitHub Actions**

### **Passo 1: Gerar Nova Chave SSH**
```bash
# No seu computador Windows
ssh-keygen -t rsa -b 4096 -C "github-actions-deploy" -f C:\Users\%USERNAME%\.ssh\github_actions_key
```

### **Passo 2: Adicionar Chave na EC2**
```bash
# Usar AWS CLI para adicionar chave
aws ec2-instance-connect send-ssh-public-key \
  --instance-id i-029805f836fb2f238 \
  --availability-zone us-east-1a \
  --instance-os-user ubuntu \
  --ssh-public-key file://C:\Users\%USERNAME%\.ssh\github_actions_key.pub
```

### **Passo 3: Testar Conexão SSH**
```bash
# Testar conexão
ssh -i C:\Users\%USERNAME%\.ssh\github_actions_key ubuntu@3.80.178.120
```

### **Passo 4: Configurar GitHub Secrets**
1. Acesse: https://github.com/fourmindsorg/s_agendamento/settings/secrets/actions
2. Adicione/Atualize:
   - `EC2_SSH_KEY`: Conteúdo da chave privada (`C:\Users\%USERNAME%\.ssh\github_actions_key`)
   - `EC2_HOST`: `3.80.178.120`
   - `EC2_USERNAME`: `ubuntu`

---

## **SOLUÇÃO 3: Usar AWS CLI para Deploy**

### **Passo 1: Executar Deploy via AWS CLI**
```bash
# Executar comandos na EC2 via AWS CLI
aws ssm send-command \
  --instance-ids i-029805f836fb2f238 \
  --document-name "AWS-RunShellScript" \
  --parameters 'commands=["cd /home/ubuntu/s_agendamento","git pull origin main","source .venv/bin/activate","pip install -r requirements.txt","python manage.py migrate","python manage.py collectstatic --noinput","sudo systemctl restart gunicorn","sudo systemctl restart nginx"]'
```

### **Passo 2: Verificar Status do Comando**
```bash
# Substitua COMMAND_ID pelo ID retornado
aws ssm get-command-invocation \
  --command-id COMMAND_ID \
  --instance-id i-029805f836fb2f238
```

---

## **SOLUÇÃO 4: Deploy Direto via Console EC2 (Mais Simples)**

### **Passo 1: Acessar Console EC2**
1. Acesse: https://console.aws.amazon.com/ec2/
2. Vá para **Instances**
3. Selecione a instância `i-029805f836fb2f238`
4. Clique em **Connect** → **EC2 Instance Connect**

### **Passo 2: Executar Comandos Individuais**
```bash
# 1. Navegar para o projeto
cd /home/ubuntu/s_agendamento

# 2. Atualizar código
git pull origin main

# 3. Ativar ambiente virtual
source .venv/bin/activate

# 4. Instalar dependências
pip install -r requirements.txt

# 5. Executar migrações
python manage.py migrate

# 6. Coletar arquivos estáticos
python manage.py collectstatic --noinput

# 7. Reiniciar serviços
sudo systemctl restart gunicorn
sudo systemctl restart nginx

# 8. Testar aplicação
curl -I http://3.80.178.120/
```

---

## **SOLUÇÃO 5: Criar Nova Instância EC2 (Última Opção)**

### **Passo 1: Criar Nova Instância**
```bash
# Criar nova instância com chave SSH correta
aws ec2 run-instances \
  --image-id ami-0c02fb55956c7d316 \
  --instance-type t2.micro \
  --key-name s_agendametnos_key_pairs_AWS \
  --security-group-ids sg-12345678 \
  --subnet-id subnet-12345678 \
  --user-data file://user_data.sh
```

### **Passo 2: Configurar Nova Instância**
```bash
# Executar script de configuração
curl -s https://raw.githubusercontent.com/fourmindsorg/s_agendamento/main/deploy_manual_github_actions.sh | bash
```

---

## 🚀 **EXECUÇÃO IMEDIATA (RECOMENDADO):**

### **Opção A: Console EC2 (Mais Fácil)**
1. Acesse: https://console.aws.amazon.com/ec2/
2. Conecte na instância via Console
3. Execute: `curl -s https://raw.githubusercontent.com/fourmindsorg/s_agendamento/main/deploy_manual_github_actions.sh | bash`

### **Opção B: AWS CLI (Se SSM funcionar)**
```bash
aws ssm send-command --instance-ids i-029805f836fb2f238 --document-name "AWS-RunShellScript" --parameters 'commands=["curl -s https://raw.githubusercontent.com/fourmindsorg/s_agendamento/main/deploy_manual_github_actions.sh | bash"]'
```

---

## ✅ **VERIFICAÇÃO:**

Após qualquer solução:
```bash
# Testar aplicação
curl -I http://3.80.178.120/

# Resultado esperado:
# HTTP/1.1 200 OK
```

---

## 🎯 **RECOMENDAÇÃO:**

**Use a Solução 1 (Console EC2)** - É a mais rápida e confiável!

**Execute agora o deploy via Console EC2!** 🚀
