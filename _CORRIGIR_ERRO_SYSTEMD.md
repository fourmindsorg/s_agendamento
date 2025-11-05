# 🔧 Corrigir: Erro "bad unit file setting" no systemd

## ❌ Problema
```
Failed to restart s-agendamento.service: Unit s-agendamento.service has a bad unit file setting.
```

Isso indica um erro de sintaxe no arquivo `/etc/systemd/system/s-agendamento.service`.

## 🔍 Diagnóstico

Execute no servidor:

```bash
# Ver detalhes do erro
sudo systemctl status s-agendamento.service

# Verificar sintaxe do arquivo
sudo systemd-analyze verify /etc/systemd/system/s-agendamento.service

# Ver conteúdo do arquivo
sudo cat /etc/systemd/system/s-agendamento.service
```

## ✅ Solução

### 1. Verificar o arquivo atual

```bash
sudo cat /etc/systemd/system/s-agendamento.service
```

### 2. Corrigir o arquivo

```bash
sudo nano /etc/systemd/system/s-agendamento.service
```

O arquivo deve ter este formato (exemplo correto):

```ini
[Unit]
Description=Sistema de Agendamento - 4Minds
After=network.target

[Service]
Type=exec
User=django
Group=django
WorkingDirectory=/opt/s-agendamento
Environment="DJANGO_SETTINGS_MODULE=core.settings_production"
ExecStart=/opt/s-agendamento/venv/bin/gunicorn core.wsgi:application --bind unix:/opt/s-agendamento/s-agendamento.sock --workers 3 --timeout 60
ExecReload=/bin/kill -s HUP $MAINPID
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
```

### 3. Erros comuns

**Erro 1: Aspas duplas ao redor da variável Environment**
```ini
# ERRADO:
Environment=DJANGO_SETTINGS_MODULE="core.settings_production"

# CORRETO (sem aspas):
Environment=DJANGO_SETTINGS_MODULE=core.settings_production

# OU (com aspas duplas externas):
Environment="DJANGO_SETTINGS_MODULE=core.settings_production"
```

**Erro 2: Espaços extras**
```ini
# ERRADO:
Environment = DJANGO_SETTINGS_MODULE=core.settings_production

# CORRETO (sem espaços ao redor do =):
Environment=DJANGO_SETTINGS_MODULE=core.settings_production
```

**Erro 3: Linha quebrada incorretamente**
```ini
# ERRADO:
Environment=DJANGO_SETTINGS_MODULE=
core.settings_production

# CORRETO (tudo na mesma linha):
Environment=DJANGO_SETTINGS_MODULE=core.settings_production
```

**Erro 4: Seção [Service] faltando ou mal formatada**
```ini
# Certifique-se de que há [Service] antes das configurações:
[Service]
Type=exec
...
```

### 4. Verificar sintaxe

```bash
# Validar sintaxe
sudo systemd-analyze verify /etc/systemd/system/s-agendamento.service

# Se não houver erros, não mostrará nada
# Se houver erros, mostrará mensagens específicas
```

### 5. Recarregar e reiniciar

```bash
# Recarregar configuração
sudo systemctl daemon-reload

# Verificar se o arquivo está correto agora
sudo systemctl status s-agendamento.service

# Tentar iniciar
sudo systemctl start s-agendamento.service

# Verificar status
sudo systemctl status s-agendamento.service
```

## 🔍 Alternativa: Recriar arquivo do zero

Se o arquivo estiver muito corrompido, recrie:

```bash
# Fazer backup do arquivo atual
sudo cp /etc/systemd/system/s-agendamento.service /etc/systemd/system/s-agendamento.service.backup

# Criar novo arquivo
sudo tee /etc/systemd/system/s-agendamento.service > /dev/null << 'EOF'
[Unit]
Description=Sistema de Agendamento - 4Minds
After=network.target

[Service]
Type=exec
User=django
Group=django
WorkingDirectory=/opt/s-agendamento
Environment=DJANGO_SETTINGS_MODULE=core.settings_production
ExecStart=/opt/s-agendamento/venv/bin/gunicorn core.wsgi:application --bind unix:/opt/s-agendamento/s-agendamento.sock --workers 3 --timeout 60
ExecReload=/bin/kill -s HUP $MAINPID
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# Recarregar e reiniciar
sudo systemctl daemon-reload
sudo systemctl restart s-agendamento
sudo systemctl status s-agendamento
```

## ⚠️ Ajustar Usuário se Necessário

Se o usuário do Gunicorn não for `django`, ajuste:

```bash
# Verificar usuário do Gunicorn
ps aux | grep gunicorn | grep -v grep | awk '{print $1}'

# Se for 'ubuntu', ajuste no arquivo:
# User=ubuntu
# Group=ubuntu
```

## 📝 Verificação Final

```bash
# Status do serviço
sudo systemctl status s-agendamento

# Logs recentes
sudo journalctl -u s-agendamento -n 50 | grep -i -E "(production|asaas|error)"

# Deve mostrar:
# [PRODUCTION] Arquivo .env carregado...
# [PRODUCTION] ASAAS_API_KEY carregada...
```

