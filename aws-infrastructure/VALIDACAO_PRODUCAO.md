# ✅ CHECKLIST DE VALIDAÇÃO EM PRODUÇÃO

## 🎯 Como Saber Se Está Funcionando

Este guia mostra **passo a passo** como validar se sua infraestrutura está funcionando em produção.

---

## 📋 ETAPA 1: Verificar Terraform Apply

### ✅ Terraform deve ter completado com sucesso

Ao final do `terraform apply`, você deve ver:

```
Apply complete! Resources: 15 added, 0 changed, 0 destroyed.

Outputs:

ec2_public_ip = "54.xxx.xxx.xxx"
rds_endpoint = "agendamento-4minds-postgres.xxxxx.us-east-1.rds.amazonaws.com:5432"
application_url = "http://54.xxx.xxx.xxx"
s3_bucket_name = "agendamento-4minds-static-files-xxxxxxxx"
ssh_command = "ssh -i ~/.ssh/id_rsa ubuntu@54.xxx.xxx.xxx"
```

**❌ Se deu erro:** Terraform mostrará qual recurso falhou

**✅ Se completou:** Prossiga para Etapa 2

---

## 📋 ETAPA 2: Verificar Recursos na AWS

### 2.1 Verificar EC2

```bash
# Ver se EC2 está rodando
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=agendamento-4minds-web-server" \
  --query 'Reservations[0].Instances[0].[InstanceId,State.Name,PublicIpAddress]' \
  --output table
```

**Esperado:**
```
-----------------------------------------
|        DescribeInstances              |
+--------------+---------+---------------+
|  i-xxxxx     | running | 54.xxx.xxx.xxx|
+--------------+---------+---------------+
```

**Status correto:** `running`

---

### 2.2 Verificar RDS

```bash
# Ver se RDS está disponível
aws rds describe-db-instances \
  --db-instance-identifier agendamento-4minds-postgres \
  --query 'DBInstances[0].[DBInstanceIdentifier,DBInstanceStatus,Endpoint.Address]' \
  --output table
```

**Esperado:**
```
-------------------------------------------------------------------------
|                        DescribeDBInstances                            |
+----------------------------+-----------+------------------------------+
|  agendamento-4minds-postgres| available | xxx.us-east-1.rds.amazonaws.com|
+----------------------------+-----------+------------------------------+
```

**Status correto:** `available`

**⚠️ Atenção:** RDS demora 8-12 minutos para ficar `available`

---

### 2.3 Verificar S3

```bash
# Listar buckets criados
aws s3 ls | findstr agendamento-4minds
```

**Esperado:**
```
2025-10-12 19:30:00 agendamento-4minds-static-files-abc123
```

---

### 2.4 Verificar CloudWatch

```bash
# Listar alarmes
aws cloudwatch describe-alarms \
  --query 'MetricAlarms[?starts_with(AlarmName, `agendamento-4minds`)].AlarmName' \
  --output table
```

**Esperado:** ~5 alarmes listados

---

### 2.5 Verificar SNS

```bash
# Listar tópicos SNS
aws sns list-topics | findstr agendamento-4minds
```

**Esperado:**
```
"TopicArn": "arn:aws:sns:us-east-1:xxxxx:agendamento-4minds-alerts"
```

---

## 📋 ETAPA 3: Testar Conexão SSH

### 3.1 Conectar via SSH

```bash
# Obter IP da EC2
terraform output ec2_public_ip

# Conectar (substitua IP_DA_EC2)
ssh -i ~/.ssh/id_rsa ubuntu@IP_DA_EC2
```

**✅ Se conectou:** Servidor está acessível

**❌ Se deu timeout:** 
- Security Group pode estar bloqueando
- EC2 pode não ter iniciado completamente

### 3.2 Verificar Serviços no Servidor

Após conectar via SSH:

```bash
# 1. Ver status do Nginx
sudo systemctl status nginx

# 2. Ver status do Gunicorn
sudo supervisorctl status

# 3. Ver logs do user_data
sudo tail -100 /var/log/user-data.log

# 4. Ver logs do Gunicorn
sudo tail -50 /var/log/gunicorn/gunicorn.log
```

**Status esperados:**
- Nginx: `active (running)`
- Gunicorn: `RUNNING`

---

## 📋 ETAPA 4: Testar Aplicação Web

### 4.1 Testar Health Check

```bash
# Obter IP
terraform output ec2_public_ip

# Testar health check (substitua IP)
curl http://54.xxx.xxx.xxx/health/
```

**✅ Resposta esperada:**
```json
{"status":"ok","service":"sistema-agendamento","version":"1.0.0"}
```

**❌ Se não funcionar:**
- Gunicorn pode não ter iniciado
- Nginx pode estar mal configurado

---

### 4.2 Testar Página Home

```bash
# Testar home
curl -I http://54.xxx.xxx.xxx/
```

**✅ Resposta esperada:**
```
HTTP/1.1 200 OK
Server: nginx/1.x
```

**Status 200 = Funcionando!**

---

### 4.3 Testar Admin

Abra no navegador:
```
http://54.xxx.xxx.xxx/admin/
```

**✅ Esperado:** Página de login do Django Admin (pode não ter CSS ainda)

**❌ Se der 502/503:** Gunicorn não está rodando

---

## 📋 ETAPA 5: Verificar Banco de Dados

### 5.1 Testar Conexão com RDS

No servidor (via SSH):

```bash
# Testar conexão PostgreSQL
psql -h ENDPOINT_DO_RDS -U postgres -d agendamentos_db -c "SELECT version();"
```

**✅ Deve mostrar:** Versão do PostgreSQL

**❌ Se falhar:**
- Security Group pode estar bloqueando
- Credenciais incorretas

---

### 5.2 Verificar Migrations

```bash
# No servidor via SSH
cd /home/django/app
source venv/bin/activate
python manage.py showmigrations
```

**✅ Esperado:** Lista de migrations com [X] (aplicadas)

---

## 📋 ETAPA 6: Configurar DNS (Para domínio funcionar)

### 6.1 Obter IP da EC2

```bash
terraform output ec2_public_ip
```

Exemplo: `54.123.45.67`

### 6.2 Configurar no Registro.br (ou seu provedor)

**Configuração DNS:**
```
Tipo: A
Nome: @
Valor: 54.123.45.67
TTL: 300

Tipo: A
Nome: www
Valor: 54.123.45.67
TTL: 300
```

### 6.3 Verificar Propagação DNS

```bash
# Verificar DNS (repita até funcionar)
nslookup fourmindstech.com.br

# Esperado:
# Address: 54.123.45.67
```

**Tempo:** 5-30 minutos para propagar

---

### 6.4 Testar com Domínio

```bash
# Após DNS propagar
curl http://fourmindstech.com.br/health/
```

**✅ Esperado:** `{"status":"ok",...}`

---

## 📋 ETAPA 7: Verificar SSL (HTTPS)

### 7.1 Aguardar Certbot (Automático)

O user_data.sh instala SSL automaticamente após DNS propagar.

Aguarde ~2-5 minutos após DNS funcionar.

### 7.2 Testar HTTPS

```bash
curl https://fourmindstech.com.br/
```

**✅ Se funcionar:** SSL configurado!

**❌ Se falhar:** Certbot ainda não executou

### 7.3 Verificar Certificado (SSH)

```bash
# No servidor
sudo certbot certificates
```

**✅ Esperado:**
```
Certificate Name: fourmindstech.com.br
  Domains: fourmindstech.com.br www.fourmindstech.com.br
  Expiry Date: 2026-01-xx
  Certificate Path: /etc/letsencrypt/live/fourmindstech.com.br/fullchain.pem
```

---

## 📋 ETAPA 8: Validar Monitoramento

### 8.1 Confirmar Email SNS

Você deve ter recebido um email de:
```
From: AWS Notifications
Subject: AWS Notification - Subscription Confirmation
```

**Clique no link** para confirmar a subscription.

### 8.2 Testar Alarmes

```bash
# Ver alarmes
aws cloudwatch describe-alarms \
  --alarm-names agendamento-4minds-high-cpu \
  --query 'MetricAlarms[0].[AlarmName,StateValue]'
```

**Estado esperado:** `OK` ou `INSUFFICIENT_DATA`

---

## 📋 ETAPA 9: Validação Completa no Navegador

### 9.1 Abrir Aplicação

```
https://fourmindstech.com.br/
```

### 9.2 Verificar:

- [ ] ✅ Página carrega
- [ ] ✅ CSS está funcionando (estilos aparecendo)
- [ ] ✅ Imagens carregando
- [ ] ✅ HTTPS ativo (cadeado verde)

### 9.3 Testar Login Admin

```
https://fourmindstech.com.br/admin/
```

- [ ] ✅ Página de login aparece
- [ ] ✅ Consegue fazer login
- [ ] ✅ Dashboard admin funciona

---

## 📋 ETAPA 10: Verificação Final

### ✅ CHECKLIST COMPLETO

- [ ] Terraform apply completou (15 recursos)
- [ ] EC2 status: `running`
- [ ] RDS status: `available`
- [ ] SSH funciona
- [ ] Nginx rodando
- [ ] Gunicorn rodando
- [ ] Health check retorna 200
- [ ] DNS propagado
- [ ] HTTPS funcionando
- [ ] Admin acessível
- [ ] CSS carregando
- [ ] Banco de dados conectado
- [ ] Email SNS confirmado
- [ ] Alarmes ativos

---

## 🐛 TROUBLESHOOTING RÁPIDO

### ❌ Health check retorna 502/503

**Causa:** Gunicorn não iniciou

**Solução:**
```bash
ssh ubuntu@IP
sudo supervisorctl restart gunicorn
sudo tail -f /var/log/gunicorn/gunicorn.log
```

---

### ❌ DNS não resolve

**Causa:** Ainda propagando ou configuração errada

**Solução:**
```bash
# Verificar se configurou corretamente
dig fourmindstech.com.br

# Aguardar 5-30 minutos
```

---

### ❌ SSL não funciona

**Causa:** Certbot ainda não executou

**Solução:**
```bash
ssh ubuntu@IP
sudo certbot --nginx -d fourmindstech.com.br -d www.fourmindstech.com.br
```

---

### ❌ CSS não carrega

**Causa:** Arquivos estáticos não coletados

**Solução:**
```bash
ssh ubuntu@IP
cd /home/django/app
source venv/bin/activate
python manage.py collectstatic --noinput
sudo supervisorctl restart gunicorn
```

---

### ❌ Erro 500 na aplicação

**Causa:** Erro no código ou configuração

**Solução:**
```bash
# Ver logs
ssh ubuntu@IP
sudo tail -100 /var/log/gunicorn/error.log
```

---

## 🎯 COMANDOS RÁPIDOS DE VALIDAÇÃO

### Script Completo (Execute no seu terminal)

```bash
# 1. Obter IP
EC2_IP=$(terraform output -raw ec2_public_ip)
echo "EC2 IP: $EC2_IP"

# 2. Testar Health Check
echo "Testando health check..."
curl -s http://$EC2_IP/health/ | jq

# 3. Verificar EC2
echo "Verificando EC2..."
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=agendamento-4minds-web-server" \
  --query 'Reservations[0].Instances[0].State.Name'

# 4. Verificar RDS
echo "Verificando RDS..."
aws rds describe-db-instances \
  --db-instance-identifier agendamento-4minds-postgres \
  --query 'DBInstances[0].DBInstanceStatus'

# 5. Testar DNS
echo "Verificando DNS..."
nslookup fourmindstech.com.br

echo "Validação concluída!"
```

---

## 📊 MÉTRICAS DE SUCESSO

### ✅ Produção Funcionando Se:

1. **Terraform:** 15/15 recursos criados ✅
2. **EC2:** Status `running` ✅
3. **RDS:** Status `available` ✅
4. **Health Check:** HTTP 200 ✅
5. **DNS:** Resolve para IP da EC2 ✅
6. **HTTPS:** Certificado válido ✅
7. **Admin:** Acessível e funcional ✅

---

## 📞 PRÓXIMOS PASSOS

Após validar tudo:

1. ✅ Configurar SECRET_KEY no servidor
2. ✅ Configurar EMAIL_HOST_PASSWORD
3. ✅ Criar superuser Django
4. ✅ Testar todas as funcionalidades
5. ✅ Configurar backup adicional
6. ✅ Monitorar uso do Free Tier

---

**Criado:** Outubro 2025  
**Versão:** 1.0  
**Status:** Pronto para uso

