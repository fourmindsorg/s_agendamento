# 🔧 COMANDOS PARA CONFIGURAR O SERVIDOR

Execute estes comandos **no servidor** via EC2 Instance Connect.

---

## PASSO 1: Verificar Status do user_data.sh

```bash
# Ver se user_data ainda está rodando
ps aux | grep user-data

# Ver logs do user_data
sudo tail -100 /var/log/user-data.log

# Ver se completou
grep "Configuração concluída" /var/log/user-data.log
```

**Se mostrar "Configuração concluída" = user_data completou!**

---

## PASSO 2: Verificar Serviços

```bash
# Status do Nginx
sudo systemctl status nginx

# Status do Gunicorn
sudo supervisorctl status

# Ver logs do Gunicorn
sudo tail -50 /var/log/gunicorn/gunicorn.log
```

**Esperado:**
- Nginx: `active (running)` ✅
- Gunicorn: `FATAL` ou `STOPPED` ❌ (porque não tem código Django)

---

## PASSO 3: Navegar para Diretório da Aplicação

```bash
cd /home/django/app
ls -la
```

**Vai estar vazio** porque não clonamos o repositório.

---

## PASSO 4: Clonar Repositório do GitHub

⚠️ **IMPORTANTE:** Substitua pela URL do seu repositório!

```bash
# Se o repositório for público:
sudo -u django git clone https://github.com/SEU_USUARIO/s_agendamento.git .

# Se for privado, você precisa configurar token primeiro
```

**Não tem o repositório no GitHub?** Vou te ajudar a fazer upload.

---

## PASSO 5: Instalar Dependências

```bash
# Mudar para usuário django
sudo su - django

# Ativar virtualenv
cd /home/django/app
source venv/bin/activate

# Instalar dependências
pip install -r requirements.txt

# Sair do usuário django
exit
```

---

## PASSO 6: Configurar .env.production

```bash
# Gerar SECRET_KEY
python3 -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"

# Copiar a chave gerada e editar .env.production
sudo nano /home/django/app/.env.production
```

**Atualizar estas linhas:**
```bash
SECRET_KEY=COLE_A_CHAVE_GERADA_ACIMA
DB_HOST=agendamento-4minds-postgres.XXXXX.us-east-1.rds.amazonaws.com
EMAIL_HOST_PASSWORD=SEU_APP_PASSWORD_DO_GMAIL
```

**Salvar:** Ctrl+X, Y, Enter

---

## PASSO 7: Executar Migrations

```bash
sudo -u django bash << 'EOF'
cd /home/django/app
source venv/bin/activate
python manage.py migrate --noinput
python manage.py collectstatic --noinput
python manage.py createsuperuser
EOF
```

---

## PASSO 8: Reiniciar Gunicorn

```bash
sudo supervisorctl restart gunicorn
sudo supervisorctl status
```

**Status esperado:** `RUNNING` ✅

---

## PASSO 9: Testar

```bash
# Health check local
curl http://localhost/health/

# Deve retornar: {"status":"ok",...}
```

---

## PASSO 10: Testar do Seu Computador

No seu terminal local (Windows):
```bash
curl http://3.80.178.120/health/
```

**Se retornar JSON = FUNCIONANDO!** ✅

---

## 🔧 TROUBLESHOOTING

### Gunicorn não inicia

```bash
# Ver erro detalhado
sudo tail -100 /var/log/gunicorn/error.log

# Reiniciar
sudo supervisorctl restart gunicorn
```

### Erro de permissão

```bash
# Ajustar permissões
sudo chown -R django:django /home/django/app
```

### CSS não carrega

```bash
# Coletar arquivos estáticos
sudo -u django bash << 'EOF'
cd /home/django/app
source venv/bin/activate
python manage.py collectstatic --noinput --clear
EOF
```

---

**Criado:** Outubro 2025  
**Status:** Pronto para uso

