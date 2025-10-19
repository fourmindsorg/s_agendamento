# 🚀 CONFIGURAÇÃO COMPLETA GITHUB ACTIONS + EC2

## ✅ **WORKFLOW CRIADO COM SUCESSO!**

O arquivo `.github/workflows/deploy.yml` foi criado e está disponível em:
**https://github.com/fourmindsorg/s_agendamento/.github/workflows/deploy.yml**

---

## 🎯 **PASSO A PASSO COMPLETO:**

### **PASSO 1: Gerar Chaves SSH na EC2**

#### **Opção A: Via Console EC2 (RECOMENDADO)**
1. Acesse: https://console.aws.amazon.com/ec2/
2. Vá para **Instances** → `i-029805f836fb2f238`
3. Clique em **Connect** → **EC2 Instance Connect**
4. Execute:
```bash
curl -s https://raw.githubusercontent.com/fourmindsorg/s_agendamento/main/gerar_chaves_ssh.sh | bash
```

#### **Opção B: Via AWS CLI**
```bash
aws ssm send-command --instance-ids i-029805f836fb2f238 --document-name "AWS-RunShellScript" --parameters "commands=[\"curl -s https://raw.githubusercontent.com/fourmindsorg/s_agendamento/main/gerar_chaves_ssh.sh | bash\"]"
```

### **PASSO 2: Configurar GitHub Secrets**

1. **Acesse**: https://github.com/fourmindsorg/s_agendamento/settings/secrets/actions
2. **Clique em**: "New repository secret" para cada um:

#### **Secret 1: EC2_SSH_KEY**
- **Name**: `EC2_SSH_KEY`
- **Secret**: Cole a **CHAVE PRIVADA** completa (incluindo `-----BEGIN OPENSSH PRIVATE KEY-----` e `-----END OPENSSH PRIVATE KEY-----`)

#### **Secret 2: EC2_HOST**
- **Name**: `EC2_HOST`
- **Secret**: `3.80.178.120`

#### **Secret 3: EC2_USERNAME**
- **Name**: `EC2_USERNAME`
- **Secret**: `ubuntu`

#### **Secret 4: EC2_PORT**
- **Name**: `EC2_PORT`
- **Secret**: `22`

### **PASSO 3: Executar Deploy na EC2**

Antes de testar o GitHub Actions, execute o deploy manual na EC2:

#### **Via Console EC2:**
```bash
curl -s https://raw.githubusercontent.com/fourmindsorg/s_agendamento/main/corrigir_ssh_e_deploy.sh | bash
```

### **PASSO 4: Testar GitHub Actions**

1. **Vá para**: https://github.com/fourmindsorg/s_agendamento/actions
2. **Clique em**: "Deploy to EC2"
3. **Clique em**: "Run workflow"
4. **Selecione**: branch "main"
5. **Clique em**: "Run workflow"

---

## 🔧 **WORKFLOW CONFIGURADO:**

```yaml
name: Deploy to EC2

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      
    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.11'
        
    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install -r requirements.txt
        
    - name: Run tests
      run: |
        python manage.py check
        python manage.py test
        
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
          
    - name: Health Check
      run: |
        curl -f http://${{ secrets.EC2_HOST }}/ || exit 1
```

---

## ✅ **VERIFICAÇÃO:**

### **1. Workflow Disponível**
- ✅ **URL**: https://github.com/fourmindsorg/s_agendamento/.github/workflows/deploy.yml
- ✅ **Configuração**: SSH com secrets
- ✅ **Deploy**: Automático para EC2

### **2. Próximos Passos**
1. **Execute o script** na EC2 para gerar chaves SSH
2. **Configure GitHub Secrets** com as chaves
3. **Execute deploy manual** na EC2 primeiro
4. **Teste GitHub Actions** para automatizar

### **3. URLs Finais**
- **Aplicação**: http://3.80.178.120
- **Domínio**: http://fourmindstech.com.br (após DNS)
- **Admin**: http://3.80.178.120/admin
- **Usuário**: admin | **Senha**: admin123

---

## 🚨 **TROUBLESHOOTING:**

### **Problema: Workflow não executa**
- Verifique se todos os secrets estão configurados
- Confirme se a EC2 está rodando
- Execute deploy manual primeiro

### **Problema: SSH ainda falha**
- Execute o script de geração de chaves
- Verifique se as chaves foram copiadas corretamente
- Teste SSH localmente

### **Problema: Deploy falha**
- Verifique se os serviços estão rodando na EC2
- Confirme se o ambiente virtual está ativo
- Verifique os logs da aplicação

---

## 🎯 **RESUMO:**

1. ✅ **Workflow criado**: `.github/workflows/deploy.yml`
2. ⏳ **Aguardando**: Configuração de GitHub Secrets
3. ⏳ **Aguardando**: Deploy manual na EC2
4. ⏳ **Aguardando**: Teste do GitHub Actions

**Execute os passos acima e o deploy automático funcionará!** 🚀
