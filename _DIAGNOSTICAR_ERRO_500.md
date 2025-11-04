# 🔍 Diagnosticar Erro 500 do Servidor

## ❌ Problema
Após alterar `wsgi.py` para usar `core.settings_production`, o servidor retorna erro 500.

## ✅ Solução Passo a Passo

### 1. Verificar Logs do Gunicorn
```bash
# Ver logs do gunicorn (últimas 50 linhas)
sudo journalctl -u gunicorn -n 50 --no-pager

# OU se o serviço for s-agendamento:
sudo journalctl -u s-agendamento -n 50 --no-pager

# Ver logs em tempo real
sudo journalctl -u gunicorn -f
```

### 2. Verificar Logs do Django (se existir arquivo)
```bash
# Verificar se existe arquivo de log
ls -la /opt/s-agendamento/logs/django.log 2>/dev/null || echo "Arquivo não encontrado"

# Se existir, ver últimas linhas
tail -n 50 /opt/s-agendamento/logs/django.log
```

### 3. Testar Importação do Settings
```bash
python manage.py shell
```

```python
>>> import os
>>> os.environ['DJANGO_SETTINGS_MODULE'] = 'core.settings_production'
>>> import django
>>> django.setup()
>>> from django.conf import settings
>>> print(settings.DEBUG)  # Deve mostrar False
>>> print(settings.DATABASES)  # Verificar se database está configurado
```

Se houver erro aqui, o problema está no `settings_production.py`.

### 4. Verificar Erro Específico no Python
```bash
# Tentar importar diretamente
python -c "from core import settings_production; print('OK')"
```

### 5. Verificar Status do Gunicorn
```bash
# Ver se o gunicorn está rodando
sudo systemctl status gunicorn

# Ver processos
ps aux | grep gunicorn
```

### 6. Verificar Erros Comuns

#### Erro: "ModuleNotFoundError" ou "ImportError"
- Verificar se todas as dependências estão instaladas
- Verificar se o ambiente virtual está ativado

#### Erro: "Database connection"
- Verificar se as credenciais do banco estão corretas no `.env`
- Verificar se o banco está acessível

#### Erro: "SECRET_KEY"
- Verificar se `SECRET_KEY` está configurada no `.env`

#### Erro: "ALLOWED_HOSTS"
- Verificar se o domínio está na lista de `ALLOWED_HOSTS`

---

## 🔧 Solução Temporária: Reverter para settings.py

Se o erro 500 persistir e você precisar restaurar o site rapidamente:

### Opção 1: Reverter wsgi.py
```bash
nano core/wsgi.py
```

Alterar linha 15:
```python
# DE:
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "core.settings_production")

# PARA:
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "core.settings")
```

Depois:
```bash
git add core/wsgi.py
git commit -m "Reverter para settings.py temporariamente"
git push

# No servidor:
git pull
sudo systemctl restart gunicorn
```

### Opção 2: Configurar via Systemd (Recomendado)
Manter `wsgi.py` como está e configurar via systemd:

```bash
sudo nano /etc/systemd/system/gunicorn.service
# OU
sudo nano /etc/systemd/system/s-agendamento.service
```

Adicionar/modificar:
```ini
[Service]
Environment=DJANGO_SETTINGS_MODULE=core.settings
```

Depois:
```bash
sudo systemctl daemon-reload
sudo systemctl restart gunicorn
```

---

## 📋 Checklist de Diagnóstico

- [ ] Logs do gunicorn verificados
- [ ] Logs do Django verificados (se existir)
- [ ] Importação do settings_production testada
- [ ] Status do gunicorn verificado
- [ ] Erro específico identificado
- [ ] Solução aplicada

---

## 🚨 Enviar Informações para Diagnóstico

Se ainda não conseguir resolver, execute e envie:

```bash
# 1. Logs do gunicorn
sudo journalctl -u gunicorn -n 100 --no-pager > logs_gunicorn.txt

# 2. Teste de importação
python manage.py shell << EOF > teste_settings.txt
import os
os.environ['DJANGO_SETTINGS_MODULE'] = 'core.settings_production'
import django
django.setup()
from django.conf import settings
print("DEBUG:", settings.DEBUG)
print("ASAAS_ENV:", getattr(settings, 'ASAAS_ENV', 'N/A'))
EOF

# 3. Status do serviço
sudo systemctl status gunicorn > status_gunicorn.txt
```

---

**Status:** ⚠️ Requer diagnóstico dos logs para identificar o erro específico

