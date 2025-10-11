# Configuração do Domínio fourmindstech.com.br

## 📋 Resumo das Alterações

Este documento consolida todas as alterações realizadas para configurar o sistema de agendamento com o domínio **fourmindstech.com.br**.

---

## ✅ Arquivos Atualizados

### 1. **Infraestrutura AWS (Terraform)**

#### `aws-infrastructure/terraform.tfvars`
- ✅ Domínio configurado: `domain_name = "fourmindstech.com.br"`
- ✅ Email de notificação: `fourmindsorg@gmail.com`

#### `aws-infrastructure/terraform.tfvars.example`
- ✅ Domínio de exemplo atualizado para `fourmindstech.com.br`

#### `aws-infrastructure/user_data.sh`
- ✅ Nginx configurado com `server_name fourmindstech.com.br www.fourmindstech.com.br _`
- ✅ Django ALLOWED_HOSTS atualizado com domínio principal e www

#### `aws-infrastructure/README.md`
- ✅ Exemplos de domínio atualizados
- ✅ Comandos SSL com domínio correto
- ✅ Informações de suporte atualizadas

---

### 2. **Configurações Django**

#### `core/settings.py`
- ✅ ALLOWED_HOSTS: `['localhost', '127.0.0.1', '0.0.0.0', 'fourmindstech.com.br', 'www.fourmindstech.com.br']`
- ✅ DEFAULT_FROM_EMAIL: `'4Minds - Sistema de Agendamentos <noreply@fourmindstech.com.br>'`
- ✅ ADMIN_SITE_HEADER: `'4Minds - Sistema de Agendamentos - Administração'`
- ✅ ADMIN_SITE_TITLE: `'4Minds Agendamentos'`

#### `core/settings_production.py`
- ✅ ALLOWED_HOSTS com domínio principal e www
- ✅ CSRF_TRUSTED_ORIGINS configurado com HTTP e HTTPS para ambos domínios
- ✅ Configurações de email atualizadas
- ✅ SESSION_COOKIE_DOMAIN e CSRF_COOKIE_DOMAIN configuráveis via variável de ambiente

---

### 3. **Configuração Nginx**

#### `nginx-django-fixed.conf`
- ✅ server_name: `fourmindstech.com.br www.fourmindstech.com.br`
- ✅ Configuração de arquivos estáticos
- ✅ Proxy pass para Django/Gunicorn

---

### 4. **Variáveis de Ambiente**

#### `env.example`
- ✅ ALLOWED_HOSTS: `fourmindstech.com.br,www.fourmindstech.com.br`
- ✅ DEFAULT_FROM_EMAIL: `4Minds - Sistema de Agendamentos <noreply@fourmindstech.com.br>`
- ✅ NOTIFICATION_EMAIL: `fourmindsorg@gmail.com`
- ✅ ALERT_EMAIL: `fourmindsorg@gmail.com`

#### `env.production.example`
- ✅ Mesmas configurações do env.example
- ✅ Configurações de segurança para produção

---

### 5. **Scripts de Deploy**

#### `deploy-manual.ps1`
- ✅ URLs atualizadas para `http://fourmindstech.com.br`
- ✅ Testes de aplicação com domínio correto

#### `deploy-scp.ps1`
- ✅ Comandos SSH usando `ubuntu@fourmindstech.com.br`
- ✅ Testes de aplicação com domínio correto

#### `fix-static-files.ps1`
- ✅ URLs de teste atualizadas

#### `fix-nginx-static.ps1`
- ✅ URLs de teste atualizadas

#### `diagnose-server.ps1`
- ✅ URLs de diagnóstico atualizadas

---

### 6. **Documentação**

#### `TERRAFORM_SETUP_GUIDE.md`
- ✅ Exemplos de domínio atualizados
- ✅ Comandos SSL com domínio correto
- ✅ Informações de suporte atualizadas

---

## 🔐 Configurações de Segurança

### CSRF Protection
```python
CSRF_TRUSTED_ORIGINS = [
    "http://fourmindstech.com.br",
    "https://fourmindstech.com.br",
    "http://www.fourmindstech.com.br",
    "https://www.fourmindstech.com.br",
]
```

### Cookies Seguros
- SESSION_COOKIE_SECURE: Habilitado em produção com HTTPS
- CSRF_COOKIE_SECURE: Habilitado em produção com HTTPS
- SESSION_COOKIE_DOMAIN: Configurável via variável de ambiente
- CSRF_COOKIE_DOMAIN: Configurável via variável de ambiente

### ALLOWED_HOSTS
- localhost (desenvolvimento)
- 127.0.0.1 (desenvolvimento)
- 0.0.0.0 (bind interno)
- fourmindstech.com.br (produção)
- www.fourmindstech.com.br (produção)

---

## 🚀 Próximos Passos para Deploy

### 1. Configurar DNS
Apontar o domínio `fourmindstech.com.br` para o IP da instância EC2:

```bash
# Obter IP da instância
terraform output ec2_public_ip

# Configurar registros DNS:
# A record: fourmindstech.com.br -> <IP_EC2>
# A record: www.fourmindstech.com.br -> <IP_EC2>
```

### 2. Configurar SSL/TLS
Após DNS propagado, obter certificado Let's Encrypt:

```bash
# Conectar na instância
ssh -i ~/.ssh/id_rsa ubuntu@fourmindstech.com.br

# Instalar Certbot
sudo apt install certbot python3-certbot-nginx -y

# Obter certificado
sudo certbot --nginx -d fourmindstech.com.br -d www.fourmindstech.com.br

# Configurar renovação automática (já incluído)
sudo systemctl status certbot.timer
```

### 3. Atualizar Variáveis de Ambiente em Produção
Após SSL configurado, atualizar `.env.production`:

```bash
HTTPS_REDIRECT=True
SECURE_SSL_REDIRECT=True
```

### 4. Aplicar Infraestrutura Terraform
```bash
cd aws-infrastructure
terraform plan
terraform apply
```

### 5. Verificar Aplicação
```bash
# Testar HTTP
curl -I http://fourmindstech.com.br

# Testar HTTPS (após SSL)
curl -I https://fourmindstech.com.br

# Testar www
curl -I https://www.fourmindstech.com.br
```

---

## 📊 Configurações de Monitoramento

### CloudWatch Logs
- `/aws/ec2/sistema-agendamento-4minds/django`
- `/aws/ec2/sistema-agendamento-4minds/nginx-access`
- `/aws/ec2/sistema-agendamento-4minds/nginx-error`

### Alertas SNS
- Email: `fourmindsorg@gmail.com`
- CPU > 80%
- Memória > 80%
- Disco > 85%

---

## 🔧 Troubleshooting

### Problema: DNS não resolve
```bash
# Verificar propagação DNS
nslookup fourmindstech.com.br
dig fourmindstech.com.br

# Aguardar propagação (pode levar até 48h)
```

### Problema: SSL não funciona
```bash
# Verificar Nginx
sudo nginx -t
sudo systemctl status nginx

# Reobter certificado
sudo certbot --nginx -d fourmindstech.com.br -d www.fourmindstech.com.br --force-renewal
```

### Problema: CSRF Token Error
```bash
# Verificar CSRF_TRUSTED_ORIGINS no settings_production.py
# Limpar cache do navegador
# Verificar se o domínio está correto
```

### Problema: Redirecionamento incorreto
```bash
# Verificar Nginx server_name
sudo cat /etc/nginx/sites-enabled/django | grep server_name

# Deve mostrar: fourmindstech.com.br www.fourmindstech.com.br
```

---

## ✅ Checklist de Validação

- [x] Terraform configurado com domínio
- [x] Django ALLOWED_HOSTS atualizado
- [x] Nginx server_name configurado
- [x] CSRF_TRUSTED_ORIGINS configurado
- [x] Emails atualizados
- [x] Scripts de deploy atualizados
- [x] Documentação atualizada
- [ ] DNS configurado (aguardando cliente)
- [ ] SSL/TLS configurado (após DNS)
- [ ] Testes de produção realizados (após DNS)

---

## 📞 Suporte

**Email:** fourmindsorg@gmail.com  
**Website:** http://fourmindstech.com.br

---

## 📝 Notas Importantes

1. **Backup**: Sistema configurado com backup automático diário
2. **Segurança**: HTTPS será habilitado após configuração SSL
3. **Monitoramento**: CloudWatch configurado para alertas
4. **Custos**: Free Tier por 12 meses, depois ~$25-30/mês
5. **Senha do Banco**: Alterar `senha_segura_postgre` para uma senha forte em produção

---

**Data de Configuração:** 11/10/2025  
**Versão:** 1.0  
**Status:** ✅ Configuração completa - Aguardando DNS

