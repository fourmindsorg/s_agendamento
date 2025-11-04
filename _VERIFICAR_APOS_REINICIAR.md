# ✅ Verificar Após Reiniciar Gunicorn

## 🔍 Passo 1: Verificar Status do Gunicorn

```bash
# Verificar status
sudo systemctl status gunicorn

# Verificar processos
ps aux | grep gunicorn | grep -v grep

# Verificar socket
ls -la /opt/s-agendamento/s-agendamento.sock
```

---

## 🔍 Passo 2: Verificar Logs

```bash
# Logs do gunicorn
sudo journalctl -u gunicorn -n 50

# OU logs do Django
tail -50 /opt/s-agendamento/logs/django.log

# Verificar se há erros
tail -50 /opt/s-agendamento/logs/django.log | grep -i error
```

---

## 🔍 Passo 3: Testar Conexão

```bash
# Testar se o socket responde
curl --unix-socket /opt/s-agendamento/s-agendamento.sock http://localhost/

# OU testar HTTP direto (se estiver usando TCP)
curl http://localhost:8000/
```

---

## 🔍 Passo 4: Verificar Nginx

```bash
# Verificar status do nginx
sudo systemctl status nginx

# Ver últimos erros
sudo tail -20 /var/log/nginx/error.log

# Recarregar nginx (se necessário)
sudo systemctl reload nginx
```

---

## ✅ Se Estiver Funcionando

Você deve ver:
- ✅ Gunicorn rodando: `ps aux | grep gunicorn`
- ✅ Socket existe: `ls -la /opt/s-agendamento/s-agendamento.sock`
- ✅ Nginx sem erros recentes
- ✅ Site acessível

---

## 🚨 Se Ainda Não Funcionar

### Verificar logs detalhados:

```bash
# Ver logs do gunicorn em tempo real
sudo journalctl -u gunicorn -f

# Ver logs do Django
tail -f /opt/s-agendamento/logs/django.log

# Ver logs do nginx
sudo tail -f /var/log/nginx/error.log
```

### Verificar erros no Django:

```bash
cd ~/s_agendamento
source .venv/bin/activate
python manage.py check
```

---

**Dica:** Após reiniciar, aguarde alguns segundos e teste o site novamente!

