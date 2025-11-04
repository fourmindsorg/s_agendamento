# ⚡ Solução Rápida: Reiniciar Django sem Serviço systemd

## 🔍 Descobrir Como Está Rodando

Execute estes comandos no servidor:

```bash
# 1. Ver processos Python rodando
ps aux | grep python | grep -v grep

# 2. Ver se há gunicorn
ps aux | grep gunicorn

# 3. Ver serviços disponíveis
sudo systemctl list-units --type=service --all | grep -E "(gunicorn|django|app)"

# 4. Ver sessões screen/tmux
screen -ls
tmux ls
```

---

## ✅ Solução 1: Se Estiver Rodando Manualmente

### Encontrar o processo:

```bash
ps aux | grep "python.*manage.py"
```

### Matar e reiniciar:

```bash
# Pegar o PID (número da segunda coluna do comando acima)
# Exemplo: se mostrar "ubuntu 12345 ...", o PID é 12345
kill PID

# Depois reiniciar
cd ~/s_agendamento
python3 manage.py runserver 0.0.0.0:8000
```

---

## ✅ Solução 2: Se Estiver em Screen/Tmux

### Screen:
```bash
# Ver sessões
screen -ls

# Entrar na sessão (substitua NOME)
screen -r NOME

# Dentro: Ctrl+C para parar
# Depois: python3 manage.py runserver 0.0.0.0:8000
```

### Tmux:
```bash
tmux ls
tmux attach -t NOME
# Dentro: Ctrl+C, depois reiniciar
```

---

## ✅ Solução 3: Recarregar Variáveis sem Reiniciar (Teste Rápido)

Para testar se as variáveis estão corretas **sem reiniciar**:

```bash
# No servidor, exportar variáveis
export ASAAS_ENV=production
export ASAAS_API_KEY_PRODUCTION=$aact_SUA_CHAVE_PRODUCAO

# Testar no shell
cd ~/s_agendamento
python3 manage.py shell
```

```python
# No shell Python:
>>> import os
>>> print(os.environ.get('ASAAS_ENV'))
>>> print(os.environ.get('ASAAS_API_KEY_PRODUCTION')[:20] + '...')

>>> from django.conf import settings
>>> print(getattr(settings, 'ASAAS_ENV'))
>>> print(getattr(settings, 'ASAAS_API_KEY')[:20] + '...')
```

**Nota:** Isso só funciona para testar. Para permanente, o Django precisa reiniciar.

---

## ✅ Solução 4: Verificar se .env Está Sendo Lido

O Django pode já estar lendo o `.env` automaticamente (se tiver `python-dotenv`):

```bash
# Verificar se python-dotenv está instalado
pip3 list | grep python-dotenv

# Se não estiver, instalar:
pip3 install python-dotenv

# Verificar se o .env está no lugar certo
cd ~/s_agendamento
ls -la .env
cat .env | grep ASAAS
```

**Se o `python-dotenv` estiver instalado**, o Django carrega o `.env` automaticamente quando inicia. Só precisa reiniciar o processo.

---

## ✅ Solução 5: Criar Serviço systemd (Recomendado)

Se não houver serviço, crie um:

```bash
# Criar arquivo de serviço
sudo nano /etc/systemd/system/s-agendamento.service
```

**Cole este conteúdo (ajuste os caminhos):**

```ini
[Unit]
Description=Sistema de Agendamento Django
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/s_agendamento
EnvironmentFile=/home/ubuntu/s_agendamento/.env
ExecStart=/usr/bin/python3 /home/ubuntu/s_agendamento/manage.py runserver 0.0.0.0:8000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

**Importante:** A linha `EnvironmentFile=/home/ubuntu/s_agendamento/.env` faz o systemd carregar automaticamente todas as variáveis do `.env`!

**Depois:**

```bash
# Recarregar systemd
sudo systemctl daemon-reload

# Habilitar para iniciar no boot
sudo systemctl enable s-agendamento

# Iniciar
sudo systemctl start s-agendamento

# Ver status
sudo systemctl status s-agendamento

# Agora pode reiniciar normalmente:
sudo systemctl restart s-agendamento
```

---

## 🎯 Solução Mais Simples (Agora)

**Para testar se as variáveis estão corretas sem reiniciar:**

1. Verificar se o `.env` está correto:
   ```bash
   cat ~/s_agendamento/.env | grep ASAAS
   ```

2. Testar no shell Python:
   ```bash
   cd ~/s_agendamento
   python3 manage.py shell
   ```
   ```python
   >>> import os
   >>> from pathlib import Path
   >>> from dotenv import load_dotenv
   >>> load_dotenv()
   >>> print(os.environ.get('ASAAS_ENV'))
   ```

3. Se estiver correto, **o Django vai carregar automaticamente** na próxima vez que iniciar (se tiver `python-dotenv` instalado).

---

## 📋 Comandos Rápidos para Copiar

```bash
# 1. Ver como está rodando
ps aux | grep python | grep manage.py

# 2. Se encontrar processo, matar (substitua PID)
kill PID

# 3. Reiniciar manualmente
cd ~/s_agendamento
nohup python3 manage.py runserver 0.0.0.0:8000 > /tmp/django.log 2>&1 &

# 4. Verificar se iniciou
ps aux | grep python | grep manage.py

# 5. Ver logs
tail -f /tmp/django.log
```

---

**Dica:** Se não conseguir reiniciar agora, as variáveis do `.env` serão carregadas automaticamente na próxima vez que o Django iniciar (se tiver `python-dotenv` instalado).

