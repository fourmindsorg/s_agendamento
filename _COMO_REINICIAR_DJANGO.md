# 🔄 Como Reiniciar o Django no Servidor AWS

## 🔍 Passo 1: Descobrir Como Está Rodando

Execute este comando no servidor:

```bash
# Verificar processos Python
ps aux | grep python | grep manage.py

# Verificar serviços systemd
sudo systemctl list-units --type=service --all | grep -E "(agendamento|django|gunicorn)"

# Verificar supervisor
sudo supervisorctl status

# Verificar screen/tmux
screen -ls
tmux ls
```

---

## ✅ Opção 1: Se Estiver Rodando via systemd

### Descobrir o nome do serviço:

```bash
# Listar todos os serviços
sudo systemctl list-units --type=service --all

# Procurar por serviços relacionados
sudo systemctl list-units --type=service --all | grep -iE "(django|gunicorn|agendamento)"
```

### Reiniciar:

```bash
# Substitua NOME_DO_SERVICO pelo nome encontrado
sudo systemctl restart NOME_DO_SERVICO

# Verificar status
sudo systemctl status NOME_DO_SERVICO
```

**Exemplos de nomes comuns:**
- `gunicorn`
- `django`
- `app`
- `web`
- `s-agendamento`

---

## ✅ Opção 2: Se Estiver Rodando via Supervisor

```bash
# Ver status
sudo supervisorctl status

# Reiniciar (substitua NOME pelo nome do processo)
sudo supervisorctl restart NOME

# OU reiniciar todos
sudo supervisorctl restart all
```

---

## ✅ Opção 3: Se Estiver Rodando Manualmente (screen/tmux)

### Screen:

```bash
# Listar sessões
screen -ls

# Entrar na sessão
screen -r NOME_DA_SESSAO

# Dentro da sessão, parar o Django (Ctrl+C)
# Depois reiniciar:
python3 manage.py runserver 0.0.0.0:8000
# OU
gunicorn core.wsgi:application --bind 0.0.0.0:8000
```

### Tmux:

```bash
# Listar sessões
tmux ls

# Entrar na sessão
tmux attach -t NOME_DA_SESSAO

# Dentro da sessão, parar o Django (Ctrl+C)
# Depois reiniciar como acima
```

---

## ✅ Opção 4: Se Estiver Rodando como Processo Direto

### Encontrar o processo:

```bash
# Ver processos Python
ps aux | grep python | grep manage.py

# OU
ps aux | grep gunicorn
```

### Matar e reiniciar:

```bash
# Encontrar o PID (número da segunda coluna)
ps aux | grep python | grep manage.py

# Matar o processo (substitua PID pelo número)
kill PID

# OU forçar (se não parar)
kill -9 PID

# Depois reiniciar manualmente ou via systemd
```

---

## ✅ Opção 5: Reiniciar Apenas o Worker (Gunicorn)

Se estiver usando Gunicorn:

```bash
# Enviar sinal HUP para recarregar (sem desconectar clientes)
pkill -HUP gunicorn

# OU encontrar o processo e enviar sinal
ps aux | grep gunicorn
kill -HUP PID
```

---

## ✅ Opção 6: Carregar Variáveis sem Reiniciar (Temporário)

Se não conseguir reiniciar agora, você pode testar as variáveis diretamente:

```bash
# Exportar variáveis manualmente
export ASAAS_ENV=production
export ASAAS_API_KEY_PRODUCTION=$aact_SUA_CHAVE_AQUI

# Depois testar no shell
python3 manage.py shell
```

**Nota:** Isso só funciona para a sessão atual. Para permanente, precisa reiniciar o serviço.

---

## 🎯 Solução Rápida: Criar um Serviço systemd

Se não houver serviço configurado, você pode criar um:

### 1. Criar arquivo de serviço:

```bash
sudo nano /etc/systemd/system/s-agendamento.service
```

### 2. Adicionar conteúdo:

```ini
[Unit]
Description=Sistema de Agendamento Django
After=network.target

[Service]
Type=notify
User=ubuntu
Group=ubuntu
WorkingDirectory=/home/ubuntu/s_agendamento
Environment="ASAAS_ENV=production"
Environment="ASAAS_API_KEY_PRODUCTION=$aact_SUA_CHAVE_PRODUCAO"
Environment="ASAAS_API_KEY_SANDBOX=$aact_SUA_CHAVE_SANDBOX"
ExecStart=/usr/bin/python3 /home/ubuntu/s_agendamento/manage.py runserver 0.0.0.0:8000
# OU se usar gunicorn:
# ExecStart=/usr/local/bin/gunicorn core.wsgi:application --bind 0.0.0.0:8000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

**Ajuste:**
- `WorkingDirectory`: caminho do seu projeto
- `User`: seu usuário (ubuntu)
- `ExecStart`: comando para iniciar o Django

### 3. Habilitar e iniciar:

```bash
# Recarregar systemd
sudo systemctl daemon-reload

# Habilitar para iniciar no boot
sudo systemctl enable s-agendamento

# Iniciar o serviço
sudo systemctl start s-agendamento

# Verificar status
sudo systemctl status s-agendamento
```

---

## 🔍 Verificar se Funcionou

Após reiniciar, verifique:

```bash
# Ver logs do serviço (se systemd)
sudo journalctl -u s-agendamento -f

# OU verificar se está rodando
ps aux | grep python | grep manage.py

# Testar no shell
python3 manage.py shell
>>> from django.conf import settings
>>> print(getattr(settings, 'ASAAS_ENV'))
```

---

## 📝 Checklist

- [ ] Descobri como o Django está rodando
- [ ] Reiniciei o serviço/processo
- [ ] Verifiquei que está rodando novamente
- [ ] Testei as variáveis de ambiente no shell
- [ ] Confirmei que `ASAAS_ENV=production`

---

**Dica:** Se não conseguir reiniciar agora, as variáveis do `.env` serão carregadas na próxima vez que o Django iniciar.

