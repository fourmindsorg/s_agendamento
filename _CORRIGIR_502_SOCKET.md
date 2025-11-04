# 🔧 Corrigir 502 Bad Gateway - Unix Socket

## ⚠️ Problema Identificado

O erro no log mostra:
```
upstream prematurely closed connection while reading response header from upstream
upstream: "http://unix:/opt/s-agendamento/s-agendamento.sock"
```

**Isso significa:**
- O nginx está usando um **unix socket** (não TCP)
- O socket está em `/opt/s-agendamento/s-agendamento.sock`
- A conexão foi fechada prematuramente (gunicorn pode ter crashado)

---

## 🔍 Passo 1: Verificar o Socket

```bash
# Verificar se o socket existe
ls -la /opt/s-agendamento/s-agendamento.sock

# Verificar permissões
stat /opt/s-agendamento/s-agendamento.sock
```

**Se não existir, o gunicorn não está rodando!**

---

## 🔍 Passo 2: Verificar Processos Gunicorn

```bash
# Ver processos gunicorn
ps aux | grep gunicorn

# Ver se há processos Python
ps aux | grep python | grep -v grep
```

---

## 🔍 Passo 3: Verificar Logs do Django/Gunicorn

```bash
# Ver logs do Django
tail -f /opt/s-agendamento/logs/django.log

# OU verificar se há logs em outro lugar
find /opt/s-agendamento -name "*.log" -type f
find ~/s_agendamento -name "*.log" -type f

# Ver logs do systemd (se usar)
sudo journalctl -u s-agendamento -f
sudo journalctl -u gunicorn -f
```

---

## ✅ Solução 1: Reiniciar Gunicorn

### Se estiver usando systemd:

```bash
# Verificar qual serviço existe
sudo systemctl list-units --type=service | grep -E "(agendamento|gunicorn)"

# Reiniciar
sudo systemctl restart s-agendamento
# OU
sudo systemctl restart gunicorn

# Verificar status
sudo systemctl status s-agendamento
```

### Se não houver serviço systemd:

```bash
# Encontrar processo gunicorn
ps aux | grep gunicorn

# Matar processo (substitua PID)
kill PID

# Reiniciar gunicorn
cd /opt/s-agendamento
# OU
cd ~/s_agendamento

source .venv/bin/activate

# Iniciar gunicorn com socket
gunicorn core.wsgi:application \
    --bind unix:/opt/s-agendamento/s-agendamento.sock \
    --workers 3 \
    --timeout 120 \
    --log-level info \
    --access-logfile /opt/s-agendamento/logs/access.log \
    --error-logfile /opt/s-agendamento/logs/error.log \
    --daemon
```

---

## ✅ Solução 2: Verificar Permissões do Socket

```bash
# Verificar permissões
ls -la /opt/s-agendamento/s-agendamento.sock

# Verificar se o diretório existe
ls -la /opt/s-agendamento/

# Se não existir, criar
sudo mkdir -p /opt/s-agendamento
sudo chown ubuntu:ubuntu /opt/s-agendamento
```

---

## ✅ Solução 3: Verificar Configuração do Gunicorn

O gunicorn precisa estar configurado para usar o socket correto. Verifique:

```bash
# Ver se há arquivo de configuração
find /opt/s-agendamento -name "gunicorn.conf.py"
find ~/s_agendamento -name "gunicorn.conf.py"

# Ver arquivo de serviço systemd
sudo cat /etc/systemd/system/s-agendamento.service
```

---

## ✅ Solução 4: Criar Serviço systemd (Recomendado)

Se não houver serviço, crie um:

```bash
sudo nano /etc/systemd/system/s-agendamento.service
```

**Conteúdo:**

```ini
[Unit]
Description=Sistema de Agendamento Django (Gunicorn)
After=network.target

[Service]
Type=notify
User=ubuntu
Group=ubuntu
WorkingDirectory=/opt/s-agendamento
Environment="PATH=/opt/s-agendamento/.venv/bin"
ExecStart=/opt/s-agendamento/.venv/bin/gunicorn \
    --bind unix:/opt/s-agendamento/s-agendamento.sock \
    --workers 3 \
    --timeout 120 \
    --log-level info \
    --access-logfile /opt/s-agendamento/logs/access.log \
    --error-logfile /opt/s-agendamento/logs/error.log \
    core.wsgi:application
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

**Ajustar:**
- `WorkingDirectory`: caminho do projeto
- `User`: seu usuário
- Caminhos do `.venv` e logs

**Depois:**

```bash
# Recarregar systemd
sudo systemctl daemon-reload

# Habilitar
sudo systemctl enable s-agendamento

# Iniciar
sudo systemctl start s-agendamento

# Verificar
sudo systemctl status s-agendamento
```

---

## 🔍 Verificar Logs do Django

```bash
# Ver logs em tempo real
tail -f /opt/s-agendamento/logs/django.log

# Ver últimos erros
tail -100 /opt/s-agendamento/logs/django.log | grep -i error

# Verificar se há erros de importação
tail -100 /opt/s-agendamento/logs/django.log | grep -i "import\|module\|error"
```

---

## 📋 Checklist de Verificação

- [ ] Socket existe: `ls -la /opt/s-agendamento/s-agendamento.sock`
- [ ] Gunicorn está rodando: `ps aux | grep gunicorn`
- [ ] Permissões do socket estão corretas
- [ ] Diretório `/opt/s-agendamento` existe
- [ ] Logs do Django não mostram erros críticos
- [ ] Serviço systemd está ativo (se usar)

---

## 🚨 Se o Django Não Iniciar

Verifique os logs para erros:

```bash
# Ver logs do Django
tail -100 /opt/s-agendamento/logs/django.log

# Verificar erros de configuração
python manage.py check

# Verificar se consegue importar
python manage.py shell
```

---

**Dica:** O erro "upstream prematurely closed" geralmente significa que o gunicorn crashou ou não está respondendo. Verifique os logs do Django primeiro!

