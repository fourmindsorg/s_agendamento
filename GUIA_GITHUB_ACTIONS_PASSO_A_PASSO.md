# 🎯 Guia Passo-a-Passo: GitHub Actions Deploy

## 📋 Visão Geral

Este guia mostra **exatamente** o que fazer para configurar o deploy automático via GitHub Actions.

**Tempo total:** ~15-20 minutos  
**Dificuldade:** ⭐⭐☆☆☆ (Fácil)

---

## 🔐 PASSO 1: Obter Credenciais AWS (5 min)

### 1.1 - Acessar IAM Console

```
https://console.aws.amazon.com/iam/home#/users
```

### 1.2 - Criar Usuário para CI/CD (Se não tiver)

1. Clique em **"Add users"**
2. Nome do usuário: `github-actions-deploy`
3. Marque: **"Access key - Programmatic access"**
4. Clique em **"Next: Permissions"**
5. Selecione: **"Attach existing policies directly"**
6. Adicione as políticas:
   - `AmazonEC2FullAccess`
   - `AmazonRDSFullAccess`
   - `AmazonS3FullAccess`
   - `AmazonVPCFullAccess`
   - `CloudWatchFullAccess`
   - `IAMFullAccess` (para criar roles)
7. Clique em **"Next"** até **"Create user"**

### 1.3 - Copiar Credenciais

⚠️ **ATENÇÃO:** As credenciais só aparecem UMA vez!

```
AWS Access Key ID:     AKIAIOSFODNN7EXAMPLE
AWS Secret Access Key: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

**Salve em local seguro!**

---

## 🔑 PASSO 2: Gerar SECRET_KEY do Django (2 min)

### 2.1 - Abrir Terminal

```bash
# Ativar ambiente virtual
source venv/bin/activate  # Linux/Mac
venv\Scripts\activate     # Windows
```

### 2.2 - Gerar Chave

```bash
python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"
```

### 2.3 - Copiar Output

```
Exemplo: django-insecure-9k!x2@4#$%mn_abc123xyz789-secret
```

**Salve esta chave!**

---

## 🔐 PASSO 3: Obter Chave SSH (2 min)

### 3.1 - Verificar se Tem Chave

```bash
# Linux/Mac
ls ~/.ssh/id_rsa

# Windows
dir %USERPROFILE%\.ssh\id_rsa
```

### 3.2 - Gerar Nova Chave (Se não tiver)

```bash
# Linux/Mac
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""

# Windows PowerShell
ssh-keygen -t rsa -b 4096 -f $env:USERPROFILE\.ssh\id_rsa -N '""'
```

### 3.3 - Copiar Chave PRIVADA Completa

```bash
# Linux/Mac
cat ~/.ssh/id_rsa

# Windows PowerShell
cat $env:USERPROFILE\.ssh\id_rsa

# Windows CMD
type %USERPROFILE%\.ssh\id_rsa
```

**Copie TODO o conteúdo:**
```
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAA...
... (múltiplas linhas) ...
-----END OPENSSH PRIVATE KEY-----
```

---

## 🎯 PASSO 4: Configurar GitHub Secrets (5 min)

### 4.1 - Acessar Settings do Repositório

```
https://github.com/fourmindsorg/s_agendamento/settings/secrets/actions
```

### 4.2 - Adicionar Cada Secret

Clique em **"New repository secret"** para cada um:

---

#### Secret #1: AWS_ACCESS_KEY_ID

```
Nome: AWS_ACCESS_KEY_ID
Valor: AKIAIOSFODNN7EXAMPLE
```

Clique **"Add secret"**

---

#### Secret #2: AWS_SECRET_ACCESS_KEY

```
Nome: AWS_SECRET_ACCESS_KEY
Valor: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

Clique **"Add secret"**

---

#### Secret #3: DB_PASSWORD

```
Nome: DB_PASSWORD
Valor: senha_segura_postgre
```

**⚠️ IMPORTANTE:** Use a MESMA senha do `aws-infrastructure/terraform.tfvars`

Clique **"Add secret"**

---

#### Secret #4: DB_NAME

```
Nome: DB_NAME
Valor: agendamentos_db
```

Clique **"Add secret"**

---

#### Secret #5: DB_USER

```
Nome: DB_USER
Valor: postgres
```

Clique **"Add secret"**

---

#### Secret #6: DB_HOST

```
Nome: DB_HOST
Valor: (deixe vazio por enquanto)
```

**Nota:** Será preenchido após primeiro deploy do Terraform

Clique **"Add secret"**

---

#### Secret #7: DB_PORT

```
Nome: DB_PORT
Valor: 5432
```

Clique **"Add secret"**

---

#### Secret #8: SECRET_KEY

```
Nome: SECRET_KEY
Valor: django-insecure-9k!x2@4#$%mn_abc123xyz789-secret
```

**Use a chave gerada no PASSO 2**

Clique **"Add secret"**

---

#### Secret #9: SSH_PRIVATE_KEY

```
Nome: SSH_PRIVATE_KEY
Valor: 
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAA...
... (cole TODA a chave) ...
-----END OPENSSH PRIVATE KEY-----
```

**Use a chave do PASSO 3 - COMPLETA**

Clique **"Add secret"**

---

#### Secret #10: NOTIFICATION_EMAIL

```
Nome: NOTIFICATION_EMAIL
Valor: fourmindsorg@gmail.com
```

Clique **"Add secret"**

---

### 4.3 - Verificar Todos os Secrets

Você deve ver **10 secrets** listados:

```
✅ AWS_ACCESS_KEY_ID
✅ AWS_SECRET_ACCESS_KEY  
✅ DB_PASSWORD
✅ DB_NAME
✅ DB_USER
✅ DB_HOST
✅ DB_PORT
✅ SECRET_KEY
✅ SSH_PRIVATE_KEY
✅ NOTIFICATION_EMAIL
```

---

## 🚀 PASSO 5: Disparar o Deploy (2 min)

### Opção A: Deploy Automático (Recomendado)

```bash
# Qualquer alteração no código
git add .
git commit -m "Trigger deploy"
git push origin main

# Deploy inicia automaticamente!
```

### Opção B: Deploy Manual

1. **Acesse:**
   ```
   https://github.com/fourmindsorg/s_agendamento/actions/workflows/deploy.yml
   ```

2. **Clique em:** `Run workflow`

3. **Selecione:** Branch `main`

4. **Clique em:** `Run workflow` (verde)

---

## 👀 PASSO 6: Acompanhar o Deploy (25-30 min)

### 6.1 - Ver Actions em Tempo Real

```
https://github.com/fourmindsorg/s_agendamento/actions
```

### 6.2 - Timeline do Deploy

```
✅ Job 1: Validate & Test (3-5 min)
   ├── Checkout código
   ├── Setup Python 3.11
   ├── Install dependencies
   ├── Linting (flake8, black)
   ├── Django check
   └── Unit tests

🏗️ Job 2: Terraform Deploy (15-20 min)
   ├── Setup Terraform
   ├── Configure AWS
   ├── Terraform init
   ├── Terraform validate
   ├── Terraform plan
   ├── Terraform apply
   │   ├── Create VPC, Subnets
   │   ├── Create RDS (8-12 min) ⏰
   │   ├── Create EC2 (2-3 min)
   │   └── Create S3, CloudWatch
   └── Get EC2 IP

🚀 Job 3: App Deploy (3-5 min)
   ├── Setup SSH
   ├── Connect to EC2
   ├── Git pull latest code
   ├── Install dependencies
   ├── Run migrations
   ├── Collect static files
   └── Restart services

🧪 Job 4: Production Tests (1 min)
   ├── Health check
   ├── Homepage test
   ├── Admin test
   └── Static files test

📧 Job 5: Notify (30 sec)
   └── Success notification
```

### 6.3 - Ver Logs Detalhados

Clique no workflow em execução → Clique em cada job para ver logs

---

## ✅ PASSO 7: Após Deploy Completar

### 7.1 - Obter Informações

No final do workflow, você verá:

```
================================
✅ DEPLOY CONCLUÍDO COM SUCESSO
================================

🌐 URL da Aplicação:
   http://54.123.45.67/agendamento/

👤 Admin:
   http://54.123.45.67/agendamento/admin/

🔗 Com Domínio (após DNS):
   http://fourmindstech.com.br/agendamento/

📊 IP do Servidor:
   54.123.45.67

================================
```

### 7.2 - Testar Aplicação

```bash
# Substituir pelo IP real
curl -I http://54.123.45.67/agendamento/

# Abrir no navegador
http://54.123.45.67/agendamento/
```

### 7.3 - Atualizar DB_HOST Secret

1. **Obter RDS Endpoint:**
   - Ver nos logs do workflow
   - Ou: `terraform output rds_endpoint`

2. **Atualizar Secret:**
   ```
   https://github.com/fourmindsorg/s_agendamento/settings/secrets/actions
   ```
   
3. **Editar DB_HOST:**
   ```
   Valor: sistema-agendamento-4minds-postgres.xxx.us-east-1.rds.amazonaws.com
   ```

---

## 🌐 PASSO 8: Configurar DNS (5 min)

### 8.1 - Anotar IP da EC2

```
IP: 54.123.45.67 (exemplo - use o IP real)
```

### 8.2 - Configurar no Provedor DNS

No seu provedor de domínio (Registro.br, Hostinger, etc):

```
Tipo: A
Nome: @
Valor: 54.123.45.67
TTL: 300 (5 minutos)

Tipo: A
Nome: www
Valor: 54.123.45.67
TTL: 300
```

### 8.3 - Aguardar Propagação

```bash
# Verificar propagação (repita até funcionar)
nslookup fourmindstech.com.br

# Teste via navegador
http://fourmindstech.com.br/agendamento/
```

**Tempo de propagação:** 15 min a 48 horas (geralmente < 2 horas)

---

## 🔐 PASSO 9: Configurar SSL (5 min - Após DNS)

### 9.1 - Conectar na EC2

```bash
# Obter IP do workflow
ssh -i ~/.ssh/id_rsa ubuntu@54.123.45.67

# Ou após DNS:
ssh ubuntu@fourmindstech.com.br
```

### 9.2 - Instalar Certificado

```bash
# Executar Certbot
sudo certbot --nginx -d fourmindstech.com.br -d www.fourmindstech.com.br

# Seguir instruções:
# 1. Digite seu email
# 2. Aceite os termos (Y)
# 3. Escolha: 2 (Redirect HTTP to HTTPS)
```

### 9.3 - Verificar SSL

```bash
# Testar HTTPS
curl -I https://fourmindstech.com.br/agendamento/

# Verificar grade SSL
# https://www.ssllabs.com/ssltest/analyze.html?d=fourmindstech.com.br
```

---

## ✅ PASSO 10: Verificação Final

### Checklist Completo:

```
□ GitHub Secrets configurados (10)
□ Deploy executado com sucesso
□ EC2 IP obtido
□ Aplicação acessível por IP
□ DNS configurado
□ Aplicação acessível por domínio
□ SSL configurado
□ HTTPS funcionando
□ Testes de produção OK
```

### Testes Finais:

```bash
# 1. Homepage
curl -I https://fourmindstech.com.br/agendamento/

# 2. Admin
curl -I https://fourmindstech.com.br/agendamento/admin/

# 3. Static files
curl -I https://fourmindstech.com.br/agendamento/static/admin/css/base.css

# 4. Health check
curl https://fourmindstech.com.br/agendamento/health/
# Deve retornar: healthy
```

---

## 🔄 Uso Diário Após Configurado

### Deploy Automático:

```bash
# Fazer alterações no código
git add .
git commit -m "Nova funcionalidade"
git push origin main

# ✅ Deploy automático inicia!
# Ver em: https://github.com/fourmindsorg/s_agendamento/actions
```

### Workflow Completo:

```
1. Criar branch
   git checkout -b feature/nova-funcionalidade

2. Desenvolver e testar localmente
   python manage.py test
   
3. Commit e push
   git push origin feature/nova-funcionalidade
   
4. Criar Pull Request no GitHub
   → Testes automáticos executam
   
5. Code Review e Merge
   → Deploy automático para produção!
   
6. Verificar em produção
   https://fourmindstech.com.br/agendamento/
```

---

## 🛠️ Troubleshooting

### Erro: "AWS credentials not configured"

**Solução:**
- Verificar `AWS_ACCESS_KEY_ID` e `AWS_SECRET_ACCESS_KEY`
- Garantir que o usuário IAM tem as permissões corretas

### Erro: "Permission denied (publickey)"

**Solução:**
- Verificar `SSH_PRIVATE_KEY`
- Deve ser a chave COMPLETA com `-----BEGIN` e `-----END`
- Incluir todas as quebras de linha

### Erro: "Database connection failed"

**Solução:**
- Atualizar `DB_HOST` com endpoint RDS correto
- Verificar `DB_PASSWORD` está correto
- Aguardar RDS estar "available" (pode levar 10-15 min)

### Erro: "Terraform apply failed"

**Solução:**
- Ver logs detalhados no GitHub Actions
- Verificar se não há recursos duplicados na AWS
- Verificar limites da conta AWS (Free Tier)

---

## 📊 Monitoramento Pós-Deploy

### CloudWatch Logs

```
https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#logsV2:log-groups
```

Procure por:
- `/aws/ec2/sistema-agendamento-4minds/django`
- `/aws/ec2/sistema-agendamento-4minds/nginx-access`
- `/aws/ec2/sistema-agendamento-4minds/nginx-error`

### CloudWatch Alarms

```
https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#alarmsV2:
```

Você verá:
- `sistema-agendamento-4minds-high-cpu`
- `sistema-agendamento-4minds-high-memory`

### Verificar Saúde da Aplicação

```bash
# Health check
curl http://fourmindstech.com.br/agendamento/health/

# Status dos serviços (via SSH)
ssh ubuntu@fourmindstech.com.br
sudo systemctl status django nginx
```

---

## 🎯 Próximos Passos Recomendados

### Curto Prazo:

```
□ Alterar senha padrão do admin (admin/admin123)
□ Gerar nova SECRET_KEY forte para produção
□ Configurar email SMTP real (Gmail/SendGrid)
□ Fazer backup manual e testar restore
□ Documentar credenciais em local seguro
```

### Médio Prazo:

```
□ Configurar staging environment
□ Adicionar mais testes automatizados
□ Implementar monitoramento avançado (Grafana)
□ Configurar alertas via Slack/Discord
□ Implementar cache com Redis
```

### Longo Prazo:

```
□ CDN com CloudFront
□ Load Balancer + Auto Scaling
□ Blue-Green Deployment
□ WAF para segurança adicional
□ Disaster Recovery cross-region
```

---

## ✅ Checklist Final

```
CONFIGURAÇÃO
  ✅ AWS credentials obtidas
  ✅ Django SECRET_KEY gerada
  ✅ SSH key obtida
  ✅ 10 GitHub Secrets configurados
  
DEPLOY
  ✅ Workflow executado
  ✅ Infraestrutura criada
  ✅ Aplicação deployada
  ✅ Testes passaram
  
PÓS-DEPLOY
  □ DNS configurado
  □ DNS propagado
  □ SSL configurado
  □ HTTPS funcionando
  □ Senhas padrão alteradas
```

---

## 📞 Suporte

**Email:** fourmindsorg@gmail.com  
**GitHub:** https://github.com/fourmindsorg  
**Website:** http://fourmindstech.com.br/agendamento/

**Precisa de ajuda?**
1. Verifique os logs do GitHub Actions
2. Consulte `GITHUB_CICD_SETUP.md`
3. Entre em contato

---

## 🎉 Conclusão

Seguindo este guia passo-a-passo, você terá:

✅ Deploy automático via GitHub Actions  
✅ Infraestrutura AWS completa  
✅ Aplicação em produção  
✅ Monitoramento configurado  
✅ Processo profissional de CI/CD  

**Boa sorte com o deploy! 🚀**

---

*Guia Passo-a-Passo GitHub Actions - Versão 1.0*  
*Data: 11 de Outubro de 2025*  
*Organização: fourmindsorg*

