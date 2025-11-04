# 🔧 Corrigir DEBUG=True em Produção

## ❌ Problema
O servidor está usando `core.settings` (DEBUG=True) em vez de `core.settings_production` (DEBUG=False).

## ✅ Solução

### 1. Verificar qual settings está sendo usado
```bash
python manage.py shell
```

```python
>>> from django.conf import settings
>>> print(settings.DEBUG)  # Se mostrar True, está usando settings.py
>>> import settings as current_settings
>>> print(current_settings.__file__)  # Mostra qual arquivo está sendo usado
```

### 2. Verificar variável de ambiente
```bash
# Verificar se DJANGO_SETTINGS_MODULE está configurada
echo $DJANGO_SETTINGS_MODULE

# Deve mostrar: core.settings_production ou core.settings_production_aws
# Se não mostrar nada, precisa configurar
```

### 3. Verificar configuração do Gunicorn/Systemd

#### Opção A: Se estiver usando systemd (gunicorn)
```bash
# Verificar configuração do serviço
sudo systemctl cat gunicorn

# OU se o serviço for s-agendamento:
sudo systemctl cat s-agendamento

# Verificar se tem a linha:
# Environment=DJANGO_SETTINGS_MODULE=core.settings_production
```

#### Opção B: Se não encontrar o serviço, verificar processos
```bash
# Ver processos gunicorn
ps aux | grep gunicorn

# Ver variáveis de ambiente do processo
sudo cat /proc/$(pgrep -f gunicorn | head -1)/environ | tr '\0' '\n' | grep DJANGO
```

### 4. Corrigir configuração do Systemd

#### Se o serviço for `gunicorn`:
```bash
# Editar arquivo do serviço
sudo nano /etc/systemd/system/gunicorn.service
```

#### Se o serviço for `s-agendamento`:
```bash
# Editar arquivo do serviço
sudo nano /etc/systemd/system/s-agendamento.service
```

#### Adicionar/modificar a seção [Service]:
```ini
[Service]
Type=exec
User=ubuntu  # ou django, conforme seu setup
Group=ubuntu
WorkingDirectory=/home/ubuntu/s_agendamento  # ou /opt/s-agendamento
Environment=DJANGO_SETTINGS_MODULE=core.settings_production
ExecStart=/home/ubuntu/s_agendamento/.venv/bin/gunicorn core.wsgi:application --bind unix:/opt/s-agendamento/s-agendamento.sock --workers 3 --timeout 60
ExecReload=/bin/kill -s HUP $MAINPID
Restart=always
RestartSec=3
```

**IMPORTANTE:** A linha `Environment=DJANGO_SETTINGS_MODULE=core.settings_production` é essencial!

### 5. Recarregar e reiniciar o serviço
```bash
# Recarregar configuração do systemd
sudo systemctl daemon-reload

# Reiniciar o serviço
sudo systemctl restart gunicorn
# OU
sudo systemctl restart s-agendamento

# Verificar status
sudo systemctl status gunicorn
# OU
sudo systemctl status s-agendamento
```

### 6. Verificar se foi corrigido
```bash
python manage.py shell
```

```python
>>> from django.conf import settings
>>> print(settings.DEBUG)  # Deve mostrar False agora
>>> print(settings.ASAAS_ENV)  # Deve mostrar "production"
```

### 7. Se ainda estiver True, verificar qual arquivo está sendo importado
```python
>>> import settings as current_settings
>>> print(current_settings.__file__)
# Deve mostrar: .../core/settings_production.py
# Se mostrar: .../core/settings.py, ainda está usando o errado
```

---

## 🔍 Alternativa: Modificar wsgi.py temporariamente

Se não conseguir configurar via systemd, pode modificar temporariamente o `wsgi.py`:

```bash
nano core/wsgi.py
```

Alterar:
```python
# ANTES:
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "core.settings")

# DEPOIS:
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "core.settings_production")
```

**⚠️ ATENÇÃO:** Isso é uma solução temporária. O ideal é configurar via systemd.

---

## 📋 Checklist

- [ ] Verificado que `settings.DEBUG` está True
- [ ] Verificado `DJANGO_SETTINGS_MODULE` no systemd
- [ ] Adicionado `Environment=DJANGO_SETTINGS_MODULE=core.settings_production` no serviço
- [ ] Executado `sudo systemctl daemon-reload`
- [ ] Reiniciado o serviço
- [ ] Verificado que `settings.DEBUG` agora está False
- [ ] Testado o checkout novamente

---

## 🚨 Se o problema persistir

1. **Verificar se o arquivo existe:**
   ```bash
   ls -la core/settings_production.py
   ```

2. **Testar importação manual:**
   ```bash
   python manage.py shell
   ```
   ```python
   >>> import os
   >>> os.environ['DJANGO_SETTINGS_MODULE'] = 'core.settings_production'
   >>> import django
   >>> django.setup()
   >>> from django.conf import settings
   >>> print(settings.DEBUG)  # Deve ser False
   ```

3. **Verificar logs do gunicorn:**
   ```bash
   sudo journalctl -u gunicorn -n 50
   # OU
   sudo journalctl -u s-agendamento -n 50
   ```

---

**Status:** ⚠️ Requer ação no servidor para configurar DJANGO_SETTINGS_MODULE

