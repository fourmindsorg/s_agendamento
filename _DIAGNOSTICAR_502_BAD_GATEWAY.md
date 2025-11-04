# 🔧 Como Diagnosticar e Corrigir Erro 502 Bad Gateway

## ⚠️ Problema

**Erro 502 Bad Gateway** geralmente significa que o nginx não consegue se comunicar com o servidor Django (gunicorn/uwsgi).

---

## 🔍 Passo 1: Verificar se o Django Está Rodando

Conecte ao servidor:

```bash
ssh -i sua-chave.pem ubuntu@52.20.60.108
```

Verifique processos:

```bash
# Ver processos Python/Django
ps aux | grep python | grep manage.py

# Ver processos gunicorn
ps aux | grep gunicorn

# Ver processos uwsgi
ps aux | grep uwsgi
```

**Se não houver processos rodando, o Django não está ativo!**

---

## 🔍 Passo 2: Verificar Logs do Nginx

```bash
# Ver logs de erro do nginx
sudo tail -f /var/log/nginx/error.log

# Ver logs de acesso
sudo tail -f /var/log/nginx/access.log
```

**Procure por mensagens como:**
- "Connection refused"
- "No upstream server"
- "upstream prematurely closed"

---

## 🔍 Passo 3: Verificar Configuração do Nginx

```bash
# Ver configuração do nginx
sudo cat /etc/nginx/sites-available/default
# OU
sudo cat /etc/nginx/sites-available/s-agendamento
# OU
sudo cat /etc/nginx/sites-enabled/*

# Verificar se há erros de sintaxe
sudo nginx -t
```

**O arquivo deve ter algo como:**

```nginx
upstream django {
    server 127.0.0.1:8000;  # ou unix:/path/to/socket
}

server {
    listen 80;
    server_name fourmindstech.com.br;
    
    location / {
        proxy_pass http://django;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

---

## ✅ Solução 1: Reiniciar o Django

### Se estiver usando systemd:

```bash
# Verificar status
sudo systemctl status s-agendamento
# OU
sudo systemctl status gunicorn

# Reiniciar
sudo systemctl restart s-agendamento
# OU
sudo systemctl restart gunicorn

# Verificar se iniciou
sudo systemctl status s-agendamento
```

### Se estiver rodando manualmente:

```bash
# Encontrar processo
ps aux | grep python | grep manage.py

# Matar processo antigo (se houver)
kill PID

# Reiniciar
cd ~/s_agendamento
source .venv/bin/activate
python manage.py runserver 0.0.0.0:8000
```

### Se estiver usando gunicorn:

```bash
# Reiniciar gunicorn
pkill -HUP gunicorn
# OU
sudo systemctl restart gunicorn
```

---

## ✅ Solução 2: Verificar Porta/Unix Socket

### Verificar se a porta está correta:

```bash
# Ver se algo está ouvindo na porta 8000
sudo netstat -tlnp | grep 8000
# OU
sudo ss -tlnp | grep 8000
```

### Verificar unix socket (se estiver usando):

```bash
# Ver se o socket existe
ls -la /tmp/gunicorn.sock
# OU
ls -la /run/gunicorn.sock

# Verificar permissões
stat /tmp/gunicorn.sock
```

---

## ✅ Solução 3: Verificar Logs do Django

```bash
# Ver logs do Django
tail -f /opt/s-agendamento/logs/django.log
# OU
tail -f ~/s_agendamento/logs/django.log
# OU
sudo journalctl -u s-agendamento -f
```

**Procure por erros de:**
- Importação de módulos
- Configuração incorreta
- Erro de conexão com banco de dados
- Erro de variáveis de ambiente

---

## ✅ Solução 4: Verificar Configuração do Nginx

### Testar configuração:

```bash
sudo nginx -t
```

**Se houver erros, corrigir:**

```bash
sudo nano /etc/nginx/sites-available/default
```

### Recarregar nginx:

```bash
sudo systemctl reload nginx
# OU
sudo nginx -s reload
```

---

## ✅ Solução 5: Verificar Permissões e Firewall

### Verificar permissões:

```bash
# Verificar se o usuário do Django tem permissões
ls -la ~/s_agendamento

# Verificar permissões do socket (se usar)
ls -la /tmp/gunicorn.sock
```

### Verificar firewall:

```bash
# Ver regras do firewall
sudo ufw status

# Se necessário, permitir porta 8000
sudo ufw allow 8000/tcp
```

---

## 🎯 Solução Rápida (Reiniciar Tudo)

```bash
# 1. Reiniciar Django
sudo systemctl restart s-agendamento
# OU
sudo systemctl restart gunicorn

# 2. Verificar se está rodando
ps aux | grep python | grep manage.py

# 3. Recarregar nginx
sudo systemctl reload nginx

# 4. Verificar status
sudo systemctl status s-agendamento
sudo systemctl status nginx
```

---

## 📋 Checklist de Diagnóstico

- [ ] Django está rodando? (`ps aux | grep python`)
- [ ] Porta 8000 está aberta? (`sudo netstat -tlnp | grep 8000`)
- [ ] Nginx está rodando? (`sudo systemctl status nginx`)
- [ ] Configuração do nginx está correta? (`sudo nginx -t`)
- [ ] Logs do nginx mostram erro? (`sudo tail -f /var/log/nginx/error.log`)
- [ ] Logs do Django mostram erro? (`tail -f /opt/s-agendamento/logs/django.log`)
- [ ] Permissões estão corretas?
- [ ] Firewall não está bloqueando?

---

## 🚨 Problemas Comuns

### "Connection refused"
**Causa:** Django não está rodando ou porta errada
**Solução:** Reiniciar Django e verificar porta

### "No upstream server"
**Causa:** Configuração do nginx incorreta
**Solução:** Verificar `proxy_pass` no nginx

### "Permission denied"
**Causa:** Permissões incorretas no socket
**Solução:** Ajustar permissões do socket

### Django não inicia
**Causa:** Erro de configuração, banco de dados, ou variáveis de ambiente
**Solução:** Verificar logs do Django

---

**Dica:** Comece verificando se o Django está rodando e depois verifique os logs!

