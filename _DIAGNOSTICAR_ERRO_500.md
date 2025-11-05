# 🔍 Diagnosticar Internal Server Error (500)

## ❌ Problema
O site está retornando "Internal Server Error" (500).

## 🔍 Diagnóstico Imediato

Execute no servidor:

```bash
# 1. Ver logs recentes do Gunicorn com erros
sudo journalctl -u s-agendamento -n 100 --no-pager | grep -i -E "(error|exception|traceback|failed)"

# 2. Ver TODOS os logs recentes
sudo journalctl -u s-agendamento -n 200 --no-pager

# 3. Ver logs em tempo real enquanto acessa o site
sudo journalctl -u s-agendamento -f
```

## 🔍 Verificar Erros Comuns

### 1. Erro de Database/Migrations

```bash
# Verificar se há erros de banco de dados
sudo journalctl -u s-agendamento -n 100 | grep -i -E "(database|migration|table|relation)"

# Verificar se as migrações foram aplicadas
cd /opt/s-agendamento
source .venv/bin/activate
python manage.py showmigrations
```

### 2. Erro de Importação/Module

```bash
# Verificar erros de importação
sudo journalctl -u s-agendamento -n 100 | grep -i -E "(import|module|no module named)"

# Verificar se todas as dependências estão instaladas
cd /opt/s-agendamento
source .venv/bin/activate
pip list | grep -i django
pip list | grep -i gunicorn
```

### 3. Erro de Permissões

```bash
# Verificar permissões de arquivos
ls -la /opt/s-agendamento | head -10
ls -la /opt/s-agendamento/staticfiles 2>/dev/null || echo "staticfiles não existe"
ls -la /opt/s-agendamento/mediafiles 2>/dev/null || echo "mediafiles não existe"

# Verificar permissões do socket
ls -la /opt/s-agendamento/s-agendamento.sock
```

### 4. Erro de Settings

```bash
# Verificar se o settings_production está sendo usado
sudo cat /etc/systemd/system/s-agendamento.service | grep Environment

# Verificar variável de ambiente no processo
sudo cat /proc/$(pgrep -f "gunicorn.*s-agendamento" | head -1)/environ | tr '\0' '\n' | grep DJANGO

# Verificar se há erros no settings
cd /opt/s-agendamento
source .venv/bin/activate
python manage.py check --deploy
```

### 5. Erro de Static Files

```bash
# Verificar se os static files foram coletados
ls -la /opt/s-agendamento/staticfiles/

# Se não existirem, coletar
cd /opt/s-agendamento
source .venv/bin/activate
python manage.py collectstatic --noinput
```

## 🔧 Soluções Comuns

### Solução 1: Aplicar Migrações

```bash
cd /opt/s-agendamento
source .venv/bin/activate
python manage.py migrate
sudo systemctl restart s-agendamento
```

### Solução 2: Coletar Static Files

```bash
cd /opt/s-agendamento
source .venv/bin/activate
python manage.py collectstatic --noinput
sudo systemctl restart s-agendamento
```

### Solução 3: Verificar Logs do Django

```bash
# Verificar se há arquivo de log do Django
ls -la /opt/s-agendamento/logs/ 2>/dev/null || echo "Diretório logs não existe"

# Verificar configuração de logging
grep -i "LOGGING" /opt/s-agendamento/core/settings_production.py
```

### Solução 4: Verificar Erro Específico

```bash
# Executar o Django shell para testar
cd /opt/s-agendamento
source .venv/bin/activate
python manage.py shell

# No shell, testar:
from django.conf import settings
print(settings.DEBUG)
print(settings.ALLOWED_HOSTS)
```

### Solução 5: Verificar Nginx

```bash
# Verificar se o Nginx está configurado corretamente
sudo nginx -t

# Ver logs do Nginx
sudo tail -n 50 /var/log/nginx/error.log

# Verificar se o socket existe
ls -la /opt/s-agendamento/s-agendamento.sock
```

## 📝 Checklist de Diagnóstico

- [ ] Logs do Gunicorn verificados
- [ ] Migrações aplicadas
- [ ] Static files coletados
- [ ] Permissões verificadas
- [ ] Settings_production sendo usado
- [ ] Nginx configurado corretamente
- [ ] Socket Unix existe e tem permissões corretas

## 🔄 Reiniciar e Testar

```bash
# Reiniciar serviço
sudo systemctl restart s-agendamento

# Verificar status
sudo systemctl status s-agendamento

# Ver logs em tempo real
sudo journalctl -u s-agendamento -f

# Em outro terminal, testar
curl -I https://fourmindstech.com.br
```

