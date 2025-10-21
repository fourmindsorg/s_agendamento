# 🚀 Guia de Deploy - Sistema de Agendamento

## 📋 **Pré-requisitos**

### **1. Configuração Inicial**
```powershell
# Execute o script de configuração
.\scripts\setup-ci-cd.ps1
```

### **2. Verificar Secrets do GitHub**
```powershell
# Verificar secrets configurados
.\scripts\check-github-secrets.sh
```

### **3. Testar Pipeline Localmente**
```powershell
# Teste sem fazer deploy
.\scripts\test-pipeline.ps1 -DryRun

# Teste completo com deploy
.\scripts\test-pipeline.ps1
```

## 🔧 **Configuração Necessária**

### **AWS Credentials**
```bash
# Configure suas credenciais AWS
aws configure

# Teste a conectividade
aws sts get-caller-identity
```

### **GitHub Secrets**
Configure os seguintes secrets no GitHub:
```bash
# AWS Credentials
gh secret set AWS_ACCESS_KEY_ID --body 'sua_access_key'
gh secret set AWS_SECRET_ACCESS_KEY --body 'sua_secret_key'

# EC2 Configuration
gh secret set EC2_HOST --body 'IP_PUBLICO_DA_EC2'
gh secret set EC2_USERNAME --body 'ubuntu'
gh secret set EC2_SSH_KEY --body 'CONTEUDO_DA_CHAVE_PRIVADA'

# Cloudflare (opcional)
gh secret set CLOUDFLARE_API_TOKEN --body 'seu_token'
```

### **Terraform Configuration**
```bash
# Configure o arquivo terraform.tfvars
cp aws-infrastructure/terraform.tfvars.example aws-infrastructure/terraform.tfvars
# Edite com suas configurações
```

## 🚀 **Processo de Deploy**

### **1. Deploy Automático (Recomendado)**
```bash
# Faça commit das mudanças
git add .
git commit -m "Deploy automático"
git push origin main

# O pipeline será executado automaticamente
```

### **2. Deploy Manual**
```bash
# Execute workflows específicos no GitHub Actions
# 1. Complete Setup (DNS + SSL)
# 2. Deploy to Production
```

## 📊 **Monitoramento**

### **GitHub Actions**
- Acesse: `https://github.com/SEU_REPOSITORIO/actions`
- Monitore os workflows em tempo real
- Verifique logs em caso de falha

### **Servidor EC2**
```bash
# Conectar no servidor
ssh -i ~/.ssh/id_rsa ubuntu@IP_DA_EC2

# Verificar status dos serviços
sudo systemctl status gunicorn
sudo systemctl status nginx

# Verificar logs
sudo journalctl -u gunicorn -f
sudo journalctl -u nginx -f
```

## 🔍 **Troubleshooting**

### **Problemas Comuns**

#### **1. Deploy Falha - AWS Credentials**
```bash
# Verificar credenciais
aws sts get-caller-identity

# Reconfigurar se necessário
aws configure
```

#### **2. Deploy Falha - GitHub Secrets**
```bash
# Verificar secrets
gh secret list

# Reconfigurar se necessário
gh secret set SECRET_NAME --body 'novo_valor'
```

#### **3. Deploy Falha - EC2 SSH**
```bash
# Verificar chave SSH
ssh -i ~/.ssh/id_rsa ubuntu@IP_DA_EC2

# Verificar se a chave está no GitHub Secret
gh secret get EC2_SSH_KEY
```

#### **4. Aplicação Não Funciona**
```bash
# Verificar logs no servidor
sudo journalctl -u gunicorn -f

# Verificar configuração Django
python manage.py check --deploy

# Verificar variáveis de ambiente
cat .env
```

### **Logs Importantes**
- **GitHub Actions**: Logs dos workflows
- **EC2**: `sudo journalctl -u gunicorn -f`
- **Nginx**: `sudo journalctl -u nginx -f`
- **Django**: `python manage.py check --deploy`

## ✅ **Checklist de Deploy**

### **Antes do Deploy**
- [ ] AWS CLI configurado
- [ ] GitHub Secrets configurados
- [ ] Terraform configurado
- [ ] Testes locais passando
- [ ] Código commitado

### **Durante o Deploy**
- [ ] Workflow CI executando
- [ ] Testes passando
- [ ] Deploy para EC2
- [ ] Serviços reiniciando
- [ ] Health check passando

### **Após o Deploy**
- [ ] Site acessível via HTTP
- [ ] Site acessível via HTTPS
- [ ] Admin funcionando
- [ ] Logs sem erros
- [ ] Performance adequada

## 🆘 **Suporte**

### **Documentação**
- `CI_CD_ANALYSIS.md` - Análise detalhada
- `CONFIGURACAO.md` - Configuração do sistema
- `SECURITY.md` - Políticas de segurança

### **Scripts de Ajuda**
- `scripts/setup-ci-cd.ps1` - Configuração inicial
- `scripts/check-github-secrets.sh` - Verificar secrets
- `scripts/test-pipeline.ps1` - Testar pipeline

### **Comandos Úteis**
```bash
# Verificar status do Git
git status

# Verificar workflows
gh workflow list

# Verificar secrets
gh secret list

# Verificar AWS
aws sts get-caller-identity

# Testar Django
python manage.py check --deploy
```

## 🎉 **Deploy Bem-sucedido**

Quando tudo estiver funcionando, você verá:
- ✅ Site acessível em `https://fourmindstech.com.br`
- ✅ Admin funcionando em `https://fourmindstech.com.br/admin`
- ✅ Workflows GitHub passando
- ✅ Logs sem erros
- ✅ Performance adequada

**Parabéns! Seu sistema está em produção! 🚀**
