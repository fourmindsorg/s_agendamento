# 🔑 CONFIGURAÇÃO SSH PARA GITHUB ACTIONS

## ❌ **Problema Atual**
```
ssh: handshake failed: ssh: unable to authenticate, attempted methods [none publickey], no supported methods remain
```

## 🔧 **Solução: Configurar Chave SSH no GitHub**

### 1. **Usar Chave Existente**
- **Arquivo**: `s_agendametnos_key_pairs_AWS.pem`
- **Localização**: Raiz do projeto

### 2. **Configurar GitHub Secrets**

#### **Passo 1: Acessar GitHub**
1. Vá para: https://github.com/fourmindsorg/s_agendamento
2. Clique em **Settings** (Configurações)
3. No menu lateral, clique em **Secrets and variables** → **Actions**

#### **Passo 2: Adicionar Secret**
1. Clique em **New repository secret**
2. **Name**: `EC2_SSH_KEY`
3. **Secret**: Cole o conteúdo do arquivo `s_agendametnos_key_pairs_AWS.pem`

#### **Passo 3: Conteúdo da Chave**
```bash
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA... (conteúdo completo do arquivo .pem)
-----END RSA PRIVATE KEY-----
```

---

## 🛠️ **Configuração Alternativa: Usar AWS CLI**

### **Opção 1: Modificar Workflow para usar AWS CLI**
```yaml
- name: Deploy to EC2 via AWS CLI
  run: |
    aws ssm send-command \
      --instance-ids i-1234567890abcdef0 \
      --document-name "AWS-RunShellScript" \
      --parameters 'commands=["cd /home/ubuntu/s_agendamento && git pull origin main && pip install -r requirements.txt && python manage.py migrate && python manage.py collectstatic --noinput && sudo systemctl restart gunicorn && sudo systemctl restart nginx"]'
```

### **Opção 2: Usar AWS Systems Manager**
```yaml
- name: Deploy via SSM
  uses: aws-actions/configure-aws-credentials@v2
  with:
    aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
    aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    aws-region: us-east-1

- name: Deploy to EC2
  run: |
    aws ssm send-command \
      --instance-ids $(aws ec2 describe-instances --filters "Name=tag:Name,Values=agendamento-4minds-web-server" --query "Reservations[*].Instances[*].InstanceId" --output text) \
      --document-name "AWS-RunShellScript" \
      --parameters 'commands=["cd /home/ubuntu/s_agendamento && git pull origin main && pip install -r requirements.txt && python manage.py migrate && python manage.py collectstatic --noinput && sudo systemctl restart gunicorn && sudo systemctl restart nginx"]'
```

---

## 🔍 **Verificar Configuração Atual**

### **1. Verificar Secrets do GitHub**
- Acesse: https://github.com/fourmindsorg/s_agendamento/settings/secrets/actions
- Verifique se `EC2_SSH_KEY` existe

### **2. Verificar Chave na EC2**
```bash
# Conectar na EC2 via Console AWS
# Verificar se a chave está configurada
ls -la ~/.ssh/
cat ~/.ssh/authorized_keys
```

### **3. Testar Conexão SSH**
```bash
# Testar conexão local
ssh -i s_agendametnos_key_pairs_AWS.pem ubuntu@3.80.178.120
```

---

## 🚀 **Solução Rápida: Deploy Manual**

### **1. Conectar na EC2 via Console AWS**
1. Acesse: https://console.aws.amazon.com/ec2/
2. Vá para **Instances**
3. Selecione a instância `agendamento-4minds-web-server`
4. Clique em **Connect** → **EC2 Instance Connect**

### **2. Executar Deploy**
```bash
cd /home/ubuntu/s_agendamento
git pull origin main
pip install -r requirements.txt
python manage.py migrate
python manage.py collectstatic --noinput
sudo systemctl restart gunicorn
sudo systemctl restart nginx
```

### **3. Verificar Status**
```bash
sudo systemctl status gunicorn
sudo systemctl status nginx
curl -I http://localhost:8000
```

---

## 🔧 **Configuração Completa SSH**

### **1. Adicionar Chave Pública na EC2**
```bash
# Na EC2, adicionar chave pública
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQ..." >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
chmod 700 ~/.ssh
```

### **2. Configurar GitHub Secrets**
1. **Name**: `EC2_SSH_KEY`
2. **Value**: Conteúdo completo do arquivo `.pem`

### **3. Testar Workflow**
- Faça um commit para triggerar o workflow
- Verifique os logs do GitHub Actions

---

## ✅ **Checklist de Configuração**

- [ ] Chave SSH adicionada no GitHub Secrets (`EC2_SSH_KEY`)
- [ ] Chave pública adicionada na EC2 (`~/.ssh/authorized_keys`)
- [ ] Permissões corretas na EC2 (600 para authorized_keys, 700 para .ssh)
- [ ] Teste de conexão SSH realizado
- [ ] Workflow GitHub Actions testado
- [ ] Deploy manual realizado (backup)

---

## 🚨 **Troubleshooting**

### **Problema: Chave SSH inválida**
- **Solução**: Verificar se o conteúdo do arquivo `.pem` está correto
- **Verificação**: `ssh-keygen -l -f s_agendametnos_key_pairs_AWS.pem`

### **Problema: Permissões incorretas**
- **Solução**: `chmod 600 ~/.ssh/authorized_keys`
- **Verificação**: `ls -la ~/.ssh/`

### **Problema: EC2 não aceita conexão**
- **Solução**: Verificar Security Group (porta 22)
- **Verificação**: `telnet 3.80.178.120 22`

---

## 🎯 **Próximos Passos**

1. **Configurar GitHub Secret** com chave SSH
2. **Testar conexão SSH** localmente
3. **Executar deploy manual** na EC2
4. **Verificar aplicação** funcionando
5. **Configurar DNS** para domínio personalizado

**Configuração SSH concluída!** 🔑
