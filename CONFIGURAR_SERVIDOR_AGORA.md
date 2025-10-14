# 🚀 CONFIGURAR SERVIDOR AWS - GUIA RÁPIDO

## ✅ Situação Atual

- ✅ Infraestrutura criada (Terraform)
- ✅ Código no GitHub: https://github.com/fourmindsorg/s_agendamento
- ✅ EC2 rodando: `13.221.138.11`
- ❌ Django ainda não configurado (502 Bad Gateway)

---

## 📋 PASSO A PASSO - COPIE E COLE

### PASSO 1: Acessar Console AWS

1. Abra: https://console.aws.amazon.com/ec2
2. Clique em **Instances** (menu lateral)
3. Procure: `agendamento-4minds-web-server`
4. Selecione a instância (checkbox)
5. Clique em **Connect** (botão laranja)
6. Escolha aba **EC2 Instance Connect**
7. Clique em **Connect**

**Terminal vai abrir no navegador!** ✅

---

### PASSO 2: Verificar User Data (No terminal do servidor)

```bash
# Ver se user_data completou
sudo tail -20 /var/log/user-data.log
sudo tail -20 /var/log/user-data.log

# Verificar serviços
sudo systemctl status nginx
sudo supervisorctl status
```

---

### PASSO 3: Clonar Repositório

```bash
# Mudar para usuário django
sudo su - django

# Navegar para diretório
cd /home/django/app

# Clonar repositório do GitHub
git clone https://github.com/fourmindsorg/s_agendamento.git .

# Verificar que clinou
ls -la

# Sair do usuário django
exit
```

---

### PASSO 4: Gerar SECRET_KEY

```bash
# Gerar chave segura
python3 -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"
```

**COPIE A CHAVE GERADA!** Exemplo:
```
abc123xyz456def789ghi012jkl345mno678pqr901stu234
```

---

### PASSO 5: Obter Endpoint do RDS

No seu terminal Windows, execute:

```bash
cd aws-infrastructure
terraform output rds_endpoint
```

**COPIE O ENDPOINT!** Exemplo:
```
agendamento-4minds-postgres.xxxxx.us-east-1.rds.amazonaws.com:5432
```

---

### PASSO 6: Configurar .env.production

No terminal do servidor:

```bash
# Editar arquivo
sudo nano /home/django/app/.env.production
```

**Atualize estas linhas:**

```bash
# 1. SECRET_KEY (cole a chave gerada no PASSO 4)
SECRET_KEY=COLE_AQUI_A_CHAVE_DO_PASSO_4

# 2. DB_HOST (cole o endpoint do PASSO 5, SEM a porta :5432)
DB_HOST=agendamento-4minds-postgres.xxxxx.us-east-1.rds.amazonaws.com

# 3. DB_PASSWORD (a mesma que você configurou no terraform.tfvars)
DB_PASSWORD=4MindsAgendamento2025!SecureDB#Pass

# 4. EMAIL_HOST_PASSWORD (seu App Password do Gmail)
# Gere em: https://myaccount.google.com/apppasswords
EMAIL_HOST_PASSWORD=SEU_APP_PASSWORD_DE_16_CARACTERES

# 5. HTTPS_REDIRECT (mude para True depois de configurar DNS)
HTTPS_REDIRECT=False
```

**Salvar:** Ctrl+X, depois Y, depois Enter

---

### PASSO 7: Instalar Dependências

```bash
sudo -u django bash << 'EOF'
cd /home/django/app
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
EOF
```

**Aguarde ~2-3 minutos** para instalar tudo.

---

### PASSO 8: Executar Migrations

```bash
sudo -u django bash << 'EOF'
cd /home/django/app
source venv/bin/activate
export DJANGO_SETTINGS_MODULE=core.settings_production
python manage.py migrate --noinput
python manage.py collectstatic --noinput --clear
EOF
```

---

### PASSO 9: Criar Superuser

```bash
sudo -u django bash << 'EOF'
cd /home/django/app
source venv/bin/activate
export DJANGO_SETTINGS_MODULE=core.settings_production
python manage.py createsuperuser
EOF
```

**Será pedido:**
- Username: `admin` (ou o que preferir)
- Email: `fourmindsorg@gmail.com`
- Password: (digite uma senha forte)
- Password (again): (repita a senha)

---

### PASSO 10: Reiniciar Gunicorn

```bash
sudo supervisorctl restart gunicorn
sudo supervisorctl status
```

**Status esperado:** `gunicorn RUNNING pid xxxxx, uptime 0:00:03`

---

### PASSO 11: Verificar Logs

```bash
# Ver se Django iniciou
sudo tail -50 /var/log/gunicorn/gunicorn.log

# Deve mostrar algo como:
# [INFO] Booting worker with pid: xxxxx
# [INFO] Listening at: http://0.0.0.0:8000
```

---

### PASSO 12: Testar Health Check

No terminal do servidor:

```bash
curl http://localhost/health/
```

**Esperado:**
```json
{"status":"ok","service":"sistema-agendamento","version":"1.0.0"}
```

---

### PASSO 13: Testar do Seu Computador

No seu terminal Windows:

```bash
curl http://13.221.138.11/health/
```

**Se retornar JSON = FUNCIONANDO!** 🎉

---

### PASSO 14: Testar Admin no Navegador

Abra no navegador:
```
http://13.221.138.11/admin/
```

**Esperado:**
- ✅ Página de login aparece
- ✅ CSS carregando (estilos do Django Admin)
- ✅ Consegue fazer login com superuser criado

---

## ✅ CHECKLIST DE VALIDAÇÃO

Após completar os 14 passos:

- [ ] Repositório clonado
- [ ] SECRET_KEY configurado
- [ ] DB_HOST configurado
- [ ] Dependências instaladas
- [ ] Migrations executadas
- [ ] Collectstatic executado
- [ ] Superuser criado
- [ ] Gunicorn rodando
- [ ] Health check funcionando (localhost)
- [ ] Health check funcionando (IP público)
- [ ] Admin acessível no navegador
- [ ] Login funcionando

---

## 🌐 PRÓXIMO: Configurar DNS

Após tudo funcionar com o IP, configure DNS:

**No provedor de domínio (Registro.br):**
```
Tipo: A
Nome: @
Valor: 13.221.138.11
TTL: 300

Tipo: A  
Nome: www
Valor: 13.221.138.11
TTL: 300
```

**Aguardar 5-30 minutos**, depois testar:
```bash
curl http://fourmindstech.com.br/health/
```

---

## 🔒 Configurar HTTPS

Após DNS propagar:

```bash
# No servidor
sudo certbot --nginx -d fourmindstech.com.br -d www.fourmindstech.com.br --email fourmindsorg@gmail.com --agree-tos --non-interactive --redirect

# Depois, atualizar .env.production
sudo nano /home/django/app/.env.production
# Mudar: HTTPS_REDIRECT=True

# Reiniciar
sudo supervisorctl restart gunicorn
```

---

## 🎯 RESULTADO FINAL

Quando tudo estiver pronto:

✅ **https://fourmindstech.com.br/** - Funcionando  
✅ **https://fourmindstech.com.br/admin/** - Admin Django  
✅ **https://fourmindstech.com.br/health/** - Health check  
✅ SSL ativo (cadeado verde)  
✅ Custo: $0/mês (Free Tier)

---

**Tempo total:** ~30-40 minutos  
**Criado:** Outubro 2025

