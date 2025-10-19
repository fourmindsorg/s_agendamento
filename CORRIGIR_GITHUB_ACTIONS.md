# 🔧 CORRIGIR GITHUB ACTIONS SSH

## ❌ **Problema Identificado:**
```
ssh: handshake failed: ssh: unable to authenticate, attempted methods [none publickey], no supported methods remain
```

## 🎯 **SOLUÇÕES:**

### **SOLUÇÃO 1: Deploy Manual (Recomendado)**

#### **1. Acessar Console EC2**
1. Acesse: https://console.aws.amazon.com/ec2/
2. Vá para **Instances**
3. Selecione a instância `i-029805f836fb2f238`
4. Clique em **Connect** → **EC2 Instance Connect**

#### **2. Executar Deploy Manual**
```bash
# Baixar e executar script de deploy
curl -s https://raw.githubusercontent.com/fourmindsorg/s_agendamento/main/deploy_manual_github_actions.sh | bash
```

#### **3. Ou executar comandos individuais**
```bash
# Navegar para o projeto
cd /home/ubuntu/s_agendamento

# Atualizar código
git pull origin main

# Ativar ambiente virtual
source .venv/bin/activate

# Instalar dependências
pip install -r requirements.txt

# Executar migrações
python manage.py migrate

# Coletar arquivos estáticos
python manage.py collectstatic --noinput

# Reiniciar serviços
sudo systemctl restart gunicorn
sudo systemctl restart nginx

# Testar aplicação
curl -I http://3.80.178.120/
```

---

### **SOLUÇÃO 2: Corrigir GitHub Actions SSH**

#### **1. Gerar Nova Chave SSH**
```bash
# No seu computador local
ssh-keygen -t rsa -b 4096 -C "github-actions-deploy" -f ~/.ssh/github_actions_key
```

#### **2. Adicionar Chave Pública na EC2**
```bash
# Copiar chave pública para EC2
ssh-copy-id -i ~/.ssh/github_actions_key.pub ubuntu@3.80.178.120
```

#### **3. Configurar GitHub Secrets**
1. Acesse: https://github.com/fourmindsorg/s_agendamento/settings/secrets/actions
2. Adicione/Atualize:
   - `EC2_SSH_KEY`: Conteúdo da chave privada (`~/.ssh/github_actions_key`)
   - `EC2_HOST`: `3.80.178.120`
   - `EC2_USERNAME`: `ubuntu`

#### **4. Atualizar Workflow**
```yaml
# .github/workflows/deploy.yml
- name: Deploy to EC2
  uses: appleboy/ssh-action@v1.0.0
  with:
    host: ${{ secrets.EC2_HOST }}
    username: ${{ secrets.EC2_USERNAME }}
    key: ${{ secrets.EC2_SSH_KEY }}
    port: 22
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

---

### **SOLUÇÃO 3: Usar AWS CLI no GitHub Actions**

#### **1. Configurar GitHub Secrets**
- `AWS_ACCESS_KEY_ID`: Sua chave de acesso AWS
- `AWS_SECRET_ACCESS_KEY`: Sua chave secreta AWS
- `AWS_REGION`: `us-east-1`
- `EC2_INSTANCE_ID`: `i-029805f836fb2f238`

#### **2. Atualizar Workflow**
```yaml
# .github/workflows/deploy.yml
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v2
  with:
    aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
    aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    aws-region: ${{ secrets.AWS_REGION }}

- name: Deploy via AWS CLI
  run: |
    aws ssm send-command \
      --instance-ids ${{ secrets.EC2_INSTANCE_ID }} \
      --document-name "AWS-RunShellScript" \
      --parameters 'commands=["cd /home/ubuntu/s_agendamento","git pull origin main","source .venv/bin/activate","pip install -r requirements.txt","python manage.py migrate","python manage.py collectstatic --noinput","sudo systemctl restart gunicorn","sudo systemctl restart nginx"]'
```

---

## 🚀 **EXECUÇÃO IMEDIATA:**

### **Opção 1: Deploy Manual (Mais Rápido)**
1. Acesse Console EC2
2. Conecte na instância
3. Execute: `curl -s https://raw.githubusercontent.com/fourmindsorg/s_agendamento/main/deploy_manual_github_actions.sh | bash`

### **Opção 2: Corrigir SSH e Re-executar**
1. Gere nova chave SSH
2. Configure GitHub Secrets
3. Re-execute o workflow

### **Opção 3: Usar AWS CLI**
1. Configure AWS Secrets no GitHub
2. Atualize workflow para usar AWS CLI
3. Re-execute o workflow

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

**Use a Solução 1 (Deploy Manual)** para resolver imediatamente, depois configure a Solução 2 ou 3 para automatizar futuros deploys.

**Execute agora o deploy manual!** 🚀
