# 🚀 Configuração CI/CD com GitHub Actions

## 📋 Visão Geral

Sistema de CI/CD completo configurado para deploy automático na AWS usando GitHub Actions, Terraform e o domínio `fourmindstech.com.br/agendamento`.

---

## 🏗️ Arquitetura do CI/CD

```
┌─────────────────────────────────────────────────────────────────┐
│                         GITHUB ACTIONS                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  1. PUSH para MAIN                                              │
│       ↓                                                          │
│  2. VALIDATE & TEST (Job 1)                                     │
│       • Linting (flake8, black)                                 │
│       • Django check                                            │
│       • Testes automatizados                                    │
│       ↓                                                          │
│  3. TERRAFORM DEPLOY (Job 2)                                    │
│       • Init, Validate, Plan                                    │
│       • Apply (criar/atualizar infraestrutura)                  │
│       • Get EC2 IP                                              │
│       ↓                                                          │
│  4. APP DEPLOY (Job 3)                                          │
│       • Connect via SSH                                         │
│       • Git pull                                                │
│       • Install dependencies                                    │
│       • Migrate database                                        │
│       • Collect static files                                    │
│       • Restart services                                        │
│       ↓                                                          │
│  5. PRODUCTION TESTS (Job 4)                                    │
│       • Health check                                            │
│       • Página principal                                        │
│       • Admin                                                   │
│       • Static files                                            │
│       ↓                                                          │
│  6. NOTIFY (Job 5)                                              │
│       • Notificação de sucesso/falha                            │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔐 Passo 1: Configurar GitHub Secrets

### Acessar Configurações

1. Vá para: https://github.com/fourmindsorg/s_agendamento
2. Clique em **Settings**
3. No menu lateral: **Secrets and variables** → **Actions**
4. Clique em **New repository secret**

### Secrets Obrigatórios

#### AWS Credentials
```
Nome: AWS_ACCESS_KEY_ID
Valor: <sua_aws_access_key>
Descrição: Access Key da AWS para Terraform
```

```
Nome: AWS_SECRET_ACCESS_KEY
Valor: <sua_aws_secret_key>
Descrição: Secret Key da AWS para Terraform
```

#### Database
```
Nome: DB_PASSWORD
Valor: senha_segura_postgre
Descrição: Senha do banco RDS PostgreSQL
```

```
Nome: DB_NAME
Valor: agendamentos_db
Descrição: Nome do banco de dados
```

```
Nome: DB_USER
Valor: postgres
Descrição: Usuário do banco de dados
```

```
Nome: DB_HOST
Valor: sistema-agendamento-4minds-postgres.xxx.us-east-1.rds.amazonaws.com
Descrição: Endpoint do RDS (obter após primeiro deploy)
```

```
Nome: DB_PORT
Valor: 5432
Descrição: Porta do PostgreSQL
```

#### Django
```
Nome: SECRET_KEY
Valor: <gerar_chave_secreta_django>
Descrição: SECRET_KEY do Django para produção
```

**Gerar SECRET_KEY:**
```bash
python -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())'
```

#### SSH
```
Nome: SSH_PRIVATE_KEY
Valor: <conteúdo_da_chave_privada_ssh>
Descrição: Chave SSH para conectar na EC2
```

**Obter chave SSH:**
```bash
cat ~/.ssh/id_rsa
# Copie TODO o conteúdo (incluindo -----BEGIN e -----END)
```

#### Notificações
```
Nome: NOTIFICATION_EMAIL
Valor: fourmindsorg@gmail.com
Descrição: Email para notificações de alertas
```

---

## 📝 Passo 2: Verificar Workflows

### Workflows Criados

```
.github/workflows/
├── deploy.yml              # Deploy automático para produção
├── test.yml                # Testes em PRs e branches
└── terraform-plan.yml      # Preview de mudanças Terraform
```

### 1. deploy.yml (Deploy Automático)

**Trigger:** Push para branch `main`

**Jobs:**
1. ✅ Validate & Test
2. 🏗️ Terraform Deploy
3. 🚀 App Deploy
4. 🧪 Production Tests
5. 📧 Notify

### 2. test.yml (Testes)

**Trigger:** Pull Requests e pushes (exceto main)

**Executa:**
- Linting (flake8, black, isort)
- Django check
- Testes unitários
- Cobertura de código

### 3. terraform-plan.yml (Preview)

**Trigger:** PR que modifica arquivos Terraform

**Executa:**
- Terraform plan
- Comenta no PR com preview das mudanças

---

## 🚀 Passo 3: Primeiro Deploy

### Preparação

1. **Certifique-se de que todos os secrets estão configurados**
2. **Faça commit das alterações:**

```bash
git add .
git commit -m "Configure CI/CD with GitHub Actions"
git push origin main
```

3. **Acompanhe o workflow:**
   - Vá para: https://github.com/fourmindsorg/s_agendamento/actions
   - Clique no workflow "Deploy to AWS"
   - Veja o progresso em tempo real

### Tempo Estimado

- **Validate & Test:** ~3-5 minutos
- **Terraform Deploy:** ~15-20 minutos (primeiro deploy)
- **App Deploy:** ~3-5 minutos
- **Production Tests:** ~1 minuto
- **Total:** ~25-30 minutos

---

## 🔧 Passo 4: Configurar DNS

Após o primeiro deploy, configure o DNS:

```bash
# 1. Obter IP da EC2
# Ver nos logs do workflow ou executar:
cd aws-infrastructure
terraform output ec2_public_ip
```

**Configurar registros DNS:**
```
Tipo: A
Nome: @
Valor: <IP_DA_EC2>
TTL: 300

Tipo: A
Nome: www
Valor: <IP_DA_EC2>
TTL: 300
```

---

## 🔐 Passo 5: Configurar SSL (Opcional)

Após DNS propagado:

```bash
# Conectar na EC2
ssh ubuntu@fourmindstech.com.br

# Instalar e configurar SSL
sudo certbot --nginx -d fourmindstech.com.br -d www.fourmindstech.com.br

# Seguir instruções do certbot
```

---

## 📊 Uso do CI/CD

### Deploy Automático

Qualquer push para `main` dispara deploy automático:

```bash
# Fazer alterações
git add .
git commit -m "Nova funcionalidade"
git push origin main

# Deploy inicia automaticamente!
```

### Deploy Manual

Acesse: https://github.com/fourmindsorg/s_agendamento/actions/workflows/deploy.yml

Clique em **Run workflow** → **Run workflow**

### Testar em Pull Request

```bash
# Criar branch
git checkout -b feature/nova-funcionalidade

# Fazer alterações
git add .
git commit -m "Implementar nova funcionalidade"
git push origin feature/nova-funcionalidade

# Criar PR no GitHub
# Testes executam automaticamente!
```

---

## 🧪 Testes Locais

Antes de fazer push, teste localmente:

```bash
# Linting
flake8 .
black --check .
isort --check-only .

# Django check
python manage.py check

# Testes
python manage.py test

# Terraform
cd aws-infrastructure
terraform fmt -check
terraform validate
```

---

## 📋 Checklist de Verificação

```
✅ CONFIGURAÇÃO
  ✅ Todos os GitHub Secrets configurados
  ✅ SSH key adicionada aos secrets
  ✅ AWS credentials configuradas
  ✅ Django SECRET_KEY gerada

✅ WORKFLOWS
  ✅ deploy.yml criado
  ✅ test.yml criado
  ✅ terraform-plan.yml criado

✅ PRIMEIRO DEPLOY
  ✅ Push para main realizado
  ✅ Workflow executado com sucesso
  ✅ EC2 IP obtido
  ✅ Aplicação acessível

✅ PÓS-DEPLOY
  ⏳ DNS configurado
  ⏳ SSL configurado
  ⏳ Testes de produção OK
```

---

## 🛠️ Troubleshooting

### Erro: SSH Connection Failed

**Causa:** Chave SSH incorreta ou instância não pronta

**Solução:**
```bash
# 1. Verificar chave SSH no secret
# 2. Aguardar mais tempo (aumentar sleep no workflow)
# 3. Verificar security group permite SSH
```

### Erro: Terraform Apply Failed

**Causa:** Credenciais AWS incorretas ou recursos já existem

**Solução:**
```bash
# 1. Verificar AWS secrets
# 2. Verificar permissões IAM
# 3. Limpar estado do Terraform se necessário
```

### Erro: Django Migration Failed

**Causa:** Banco de dados não acessível

**Solução:**
```bash
# 1. Verificar DB_HOST está correto
# 2. Verificar security group RDS
# 3. Verificar credenciais do banco
```

### Erro: Static Files 404

**Causa:** collectstatic não executou ou permissões incorretas

**Solução:**
```bash
# Conectar na EC2 e executar:
cd /home/django/sistema-de-agendamento
sudo -u django bash -c 'source venv/bin/activate && python manage.py collectstatic --noinput'
sudo chown -R www-data:www-data staticfiles/
sudo chmod -R 755 staticfiles/
```

---

## 📈 Monitoramento

### Ver Logs em Tempo Real

**Durante deploy:**
- Acesse: https://github.com/fourmindsorg/s_agendamento/actions
- Clique no workflow em execução
- Veja logs de cada job

**Após deploy:**
```bash
# Conectar na EC2
ssh ubuntu@fourmindstech.com.br

# Ver logs Django
sudo journalctl -u django -f

# Ver logs Nginx
sudo tail -f /var/log/nginx/django_error.log
```

### Status dos Serviços

```bash
# Django
sudo systemctl status django

# Nginx
sudo systemctl status nginx

# Ver processos Gunicorn
ps aux | grep gunicorn
```

---

## 🔄 Workflow de Desenvolvimento

```
┌──────────────────────────────────────────────────────────┐
│                   FLUXO DE TRABALHO                       │
├──────────────────────────────────────────────────────────┤
│                                                           │
│  1. Criar branch                                         │
│     git checkout -b feature/nova-funcionalidade          │
│                                                           │
│  2. Desenvolver localmente                               │
│     • Fazer alterações                                   │
│     • Testar localmente                                  │
│     • Commit                                             │
│                                                           │
│  3. Push para GitHub                                     │
│     git push origin feature/nova-funcionalidade          │
│     → Testes executam automaticamente (test.yml)         │
│                                                           │
│  4. Criar Pull Request                                   │
│     → Code review                                        │
│     → Testes devem passar                                │
│                                                           │
│  5. Merge para main                                      │
│     → Deploy automático inicia (deploy.yml)              │
│     → Infraestrutura atualizada                          │
│     → Aplicação deployada                                │
│     → Testes de produção                                 │
│                                                           │
│  6. Verificar produção                                   │
│     http://fourmindstech.com.br/agendamento/             │
│                                                           │
└──────────────────────────────────────────────────────────┘
```

---

## 📞 Suporte

**Email:** fourmindsorg@gmail.com  
**GitHub:** https://github.com/fourmindsorg  
**Website:** http://fourmindstech.com.br/agendamento/

---

## 🎯 Comandos Úteis

### GitHub CLI

```bash
# Ver workflows
gh workflow list

# Ver runs
gh run list

# Ver logs de um run
gh run view <run-id> --log

# Disparar workflow manualmente
gh workflow run deploy.yml
```

### Terraform

```bash
cd aws-infrastructure

# Ver output
terraform output

# Ver estado
terraform show

# Refresh estado
terraform refresh
```

### Git

```bash
# Ver status do último deploy
git log --oneline -1

# Ver branches
git branch -a

# Ver tags
git tag
```

---

## ✅ Status

```
┌────────────────────────────────────────────────────────┐
│                                                         │
│  ✅ CI/CD TOTALMENTE CONFIGURADO                       │
│                                                         │
│  📊 Workflows:         3 criados                       │
│  🔐 Secrets:           10 necessários                  │
│  🚀 Deploy:            Automático                      │
│  🧪 Testes:            Automáticos                     │
│  📈 Monitoramento:     Configurado                     │
│                                                         │
│  🌐 Domínio:           fourmindstech.com.br           │
│  📍 Subpath:           /agendamento                    │
│  🏢 Organização:       fourmindsorg                    │
│  📦 Repositório:       s_agendamento                   │
│                                                         │
└────────────────────────────────────────────────────────┘
```

---

*Documentação CI/CD - Versão 1.0*  
*Data: 11 de Outubro de 2025*  
*Organização: fourmindsorg*

