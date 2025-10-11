# ⚡ Comandos Rápidos - Subpath /agendamento

## 🚀 Comandos Essenciais

### Desenvolvimento Local

```bash
# Ativar ambiente virtual
source venv/bin/activate  # Linux/Mac
venv\Scripts\activate     # Windows

# Rodar servidor de desenvolvimento
python manage.py runserver

# Acessar
# http://127.0.0.1:8000/agendamento/
```

### Coletar Arquivos Estáticos

```bash
# Com settings padrão
python manage.py collectstatic --noinput

# Com settings de produção
python manage.py collectstatic --noinput --settings=core.settings_production
```

### Verificar Configurações

```bash
# Abrir shell do Django
python manage.py shell

# Verificar FORCE_SCRIPT_NAME
>>> from django.conf import settings
>>> settings.FORCE_SCRIPT_NAME
'/agendamento'

# Verificar STATIC_URL
>>> settings.STATIC_URL
'/agendamento/static/'

# Verificar ALLOWED_HOSTS
>>> settings.ALLOWED_HOSTS
['localhost', '127.0.0.1', '0.0.0.0', 'fourmindstech.com.br', ...]
```

---

## 🌐 Deploy e Produção

### Deploy Terraform

```bash
cd aws-infrastructure

# Ver o que será criado
terraform plan

# Aplicar mudanças
terraform apply

# Ver outputs (IP da instância)
terraform output ec2_public_ip
```

### Conectar no Servidor

```bash
# Obter IP
cd aws-infrastructure
terraform output ec2_public_ip

# Conectar via SSH
ssh -i ~/.ssh/id_rsa ubuntu@fourmindstech.com.br
```

### Verificar Status no Servidor

```bash
# Status do Django
sudo systemctl status django

# Status do Nginx
sudo systemctl status nginx

# Logs do Django
sudo journalctl -u django -f

# Logs do Nginx
sudo tail -f /var/log/nginx/django_error.log
sudo tail -f /var/log/nginx/django_access.log
```

### Reiniciar Serviços

```bash
# Reiniciar Django
sudo systemctl restart django

# Reiniciar Nginx
sudo systemctl restart nginx

# Parar Gunicorn (se não estiver como serviço)
sudo pkill -f gunicorn

# Iniciar Gunicorn manualmente
cd /home/django/sistema-de-agendamento
source venv/bin/activate
gunicorn --bind 127.0.0.1:8000 core.wsgi:application --daemon
```

---

## 🧪 Testes

### Testar Localmente

```bash
# Testar aplicação
curl -I http://127.0.0.1:8000/agendamento/

# Testar admin
curl -I http://127.0.0.1:8000/agendamento/admin/

# Testar arquivos estáticos
curl -I http://127.0.0.1:8000/agendamento/static/admin/css/base.css
```

### Testar em Produção

```bash
# Testar redirecionamento raiz
curl -I http://fourmindstech.com.br/
# Deve retornar: 301 Location: /agendamento/

# Testar aplicação
curl -I http://fourmindstech.com.br/agendamento/

# Testar admin
curl -I http://fourmindstech.com.br/agendamento/admin/

# Testar static files
curl -I http://fourmindstech.com.br/agendamento/static/admin/css/base.css

# Testar health check
curl http://fourmindstech.com.br/agendamento/health/
```

### Scripts de Diagnóstico

```powershell
# Windows PowerShell

# Diagnóstico completo
.\diagnose-server.ps1

# Corrigir arquivos estáticos
.\fix-static-files.ps1

# Corrigir Nginx
.\fix-nginx-static.ps1

# Deploy manual
.\deploy-manual.ps1

# Deploy via SCP
.\deploy-scp.ps1
```

---

## 🔧 Nginx

### Testar Configuração

```bash
# Testar sintaxe do Nginx
sudo nginx -t

# Ver configuração ativa
sudo cat /etc/nginx/sites-enabled/django

# Ver linha específica
sudo cat /etc/nginx/sites-enabled/django | grep "location /agendamento/"
```

### Recarregar/Reiniciar Nginx

```bash
# Recarregar (sem downtime)
sudo nginx -s reload

# Reiniciar (com pequeno downtime)
sudo systemctl restart nginx

# Parar Nginx
sudo systemctl stop nginx

# Iniciar Nginx
sudo systemctl start nginx
```

---

## 🗄️ Banco de Dados

### Migrações

```bash
# Criar migrações
python manage.py makemigrations

# Aplicar migrações
python manage.py migrate

# Aplicar em produção
python manage.py migrate --settings=core.settings_production
```

### Backup

```bash
# Backup local (SQLite)
cp db.sqlite3 db.sqlite3.backup

# Backup RDS (PostgreSQL) - no servidor
pg_dump -h <RDS_ENDPOINT> -U postgres -d agendamentos_db > backup.sql

# Restore
psql -h <RDS_ENDPOINT> -U postgres -d agendamentos_db < backup.sql
```

---

## 👤 Usuários e Permissões

### Criar Superusuário

```bash
# Interativo
python manage.py createsuperuser

# Programático
python manage.py shell
>>> from django.contrib.auth import get_user_model
>>> User = get_user_model()
>>> User.objects.create_superuser('admin', 'admin@fourmindstech.com.br', 'senha123')
```

### Alterar Senha

```bash
python manage.py changepassword admin
```

---

## 🔐 SSL/HTTPS

### Configurar Certbot

```bash
# Instalar Certbot
sudo apt install certbot python3-certbot-nginx -y

# Obter certificado
sudo certbot --nginx -d fourmindstech.com.br -d www.fourmindstech.com.br

# Renovar manualmente
sudo certbot renew

# Testar renovação
sudo certbot renew --dry-run

# Ver certificados
sudo certbot certificates
```

### Verificar SSL

```bash
# Verificar certificado
openssl s_client -connect fourmindstech.com.br:443 -servername fourmindstech.com.br

# Testar SSL grade
curl -I https://fourmindstech.com.br/agendamento/
```

---

## 📊 Monitoramento

### Ver Logs em Tempo Real

```bash
# Django logs
sudo journalctl -u django -f

# Nginx access logs
sudo tail -f /var/log/nginx/django_access.log

# Nginx error logs
sudo tail -f /var/log/nginx/django_error.log

# System logs
sudo tail -f /var/log/syslog
```

### Verificar Recursos

```bash
# CPU e Memória
htop
# ou
top

# Espaço em disco
df -h

# Uso de disco por diretório
du -sh /home/django/sistema-de-agendamento/*

# Processos do Gunicorn
ps aux | grep gunicorn

# Conexões ativas
netstat -an | grep :8000
```

---

## 🔍 Troubleshooting

### CSS não carrega (404)

```bash
# 1. Verificar STATIC_URL
python manage.py shell
>>> from django.conf import settings
>>> settings.STATIC_URL
# Deve ser: '/agendamento/static/'

# 2. Coletar static files
python manage.py collectstatic --noinput

# 3. Verificar permissões
ls -la staticfiles/
sudo chown -R www-data:www-data staticfiles/
sudo chmod -R 755 staticfiles/

# 4. Testar Nginx
curl -I http://localhost/agendamento/static/admin/css/base.css
```

### Redirecionamento infinito

```bash
# 1. Verificar FORCE_SCRIPT_NAME
python manage.py shell
>>> from django.conf import settings
>>> settings.FORCE_SCRIPT_NAME
# Deve ser: '/agendamento'

# 2. Verificar Nginx X-Script-Name
sudo cat /etc/nginx/sites-enabled/django | grep X-Script-Name
# Deve ter: proxy_set_header X-Script-Name /agendamento;

# 3. Reiniciar serviços
sudo systemctl restart nginx
sudo systemctl restart django
```

### Aplicação não inicia

```bash
# 1. Ver erros do Django
sudo journalctl -u django -n 50

# 2. Testar manualmente
cd /home/django/sistema-de-agendamento
source venv/bin/activate
python manage.py check --settings=core.settings_production

# 3. Testar Gunicorn
gunicorn --bind 127.0.0.1:8000 core.wsgi:application

# 4. Ver portas em uso
sudo netstat -tulpn | grep :8000
```

---

## 🔄 Git

### Commit e Push

```bash
# Ver status
git status

# Adicionar arquivos
git add .

# Commit
git commit -m "Reconfigurado para subpath /agendamento"

# Push
git push origin main
```

### Pull Últimas Alterações (no servidor)

```bash
cd /home/django/sistema-de-agendamento
git pull origin main

# Reinstalar dependências (se necessário)
source venv/bin/activate
pip install -r requirements.txt

# Aplicar migrações
python manage.py migrate --settings=core.settings_production

# Coletar static
python manage.py collectstatic --noinput --settings=core.settings_production

# Reiniciar
sudo systemctl restart django
```

---

## 🎯 Comandos Por Situação

### Acabei de clonar o repositório
```bash
# 1. Criar ambiente virtual
python3 -m venv venv

# 2. Ativar
source venv/bin/activate  # Linux/Mac
venv\Scripts\activate     # Windows

# 3. Instalar dependências
pip install -r requirements.txt

# 4. Configurar .env
cp env.example .env
# Editar .env com suas configurações

# 5. Migrar banco
python manage.py migrate

# 6. Criar superuser
python manage.py createsuperuser

# 7. Coletar static
python manage.py collectstatic --noinput

# 8. Rodar
python manage.py runserver
```

### Fiz alterações no código
```bash
# 1. Testar localmente
python manage.py runserver

# 2. Fazer commit
git add .
git commit -m "Descrição das alterações"
git push origin main

# 3. Deploy no servidor
.\deploy-manual.ps1  # Windows
# ou
ssh ubuntu@fourmindstech.com.br "cd /home/django/sistema-de-agendamento && git pull && sudo systemctl restart django"
```

### Mudei o CSS/JS
```bash
# 1. Coletar static
python manage.py collectstatic --noinput

# 2. Deploy
.\deploy-manual.ps1

# 3. Limpar cache do navegador
# Ctrl+Shift+R (Chrome/Firefox)
```

### Site está fora do ar
```bash
# 1. Verificar status
ssh ubuntu@fourmindstech.com.br
sudo systemctl status nginx
sudo systemctl status django

# 2. Ver logs
sudo journalctl -u django -n 50
sudo tail -n 50 /var/log/nginx/django_error.log

# 3. Reiniciar
sudo systemctl restart nginx
sudo systemctl restart django

# 4. Se não resolver
.\diagnose-server.ps1
```

---

## 📞 Suporte Rápido

```bash
# Email
echo "Preciso de ajuda com..." | mail -s "Suporte" fourmindsorg@gmail.com

# Ver documentação
cat RESUMO_ALTERACAO_SUBPATH.md
cat CONFIGURACAO_SUBPATH_AGENDAMENTO.md
```

---

## 🎓 Dicas Úteis

```bash
# Alias úteis para .bashrc/.zshrc
alias dj='python manage.py'
alias djr='python manage.py runserver'
alias djm='python manage.py migrate'
alias djs='python manage.py shell'
alias djcs='python manage.py collectstatic --noinput'

# Uso:
djr  # roda servidor
djm  # aplica migrações
djcs # coleta static files
```

---

*Guia de Comandos Rápidos - Versão 2.0*  
*Atualizado em: 11 de Outubro de 2025*

