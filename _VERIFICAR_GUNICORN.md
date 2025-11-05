# 🔍 Verificar e Corrigir Gunicorn

## ❌ Problema
```
Command /opt/s-agendamento/venv/bin/gunicorn is not executable: No such file or directory
```

## 🔍 Diagnóstico

Execute no servidor:

```bash
# 1. Verificar qual ambiente virtual existe
ls -la /opt/s-agendamento/ | grep -E "venv|\.venv"

# 2. Verificar se Gunicorn existe
ls -la /opt/s-agendamento/.venv/bin/gunicorn 2>/dev/null || echo "❌ .venv/bin/gunicorn não existe"
ls -la /opt/s-agendamento/venv/bin/gunicorn 2>/dev/null || echo "❌ venv/bin/gunicorn não existe"

# 3. Verificar qual Python está sendo usado
which python3
which python

# 4. Verificar se está no ambiente virtual
source /opt/s-agendamento/.venv/bin/activate 2>/dev/null || source /opt/s-agendamento/venv/bin/activate 2>/dev/null
which gunicorn
```

## ✅ Solução 1: Gunicorn existe mas caminho errado

Se o Gunicorn existe em `.venv` mas o script procurou em `venv`:

```bash
# Verificar caminho real
ls -la /opt/s-agendamento/.venv/bin/gunicorn

# Se existir, criar arquivo systemd manualmente com caminho correto
sudo nano /etc/systemd/system/s-agendamento.service
```

Use este conteúdo (ajuste o caminho se necessário):

```ini
[Unit]
Description=Sistema de Agendamento - 4Minds
After=network.target

[Service]
Type=exec
User=django
Group=django
WorkingDirectory=/opt/s-agendamento
Environment=DJANGO_SETTINGS_MODULE=core.settings_production
ExecStart=/opt/s-agendamento/.venv/bin/gunicorn core.wsgi:application --bind unix:/opt/s-agendamento/s-agendamento.sock --workers 3 --timeout 60
ExecReload=/bin/kill -s HUP $MAINPID
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
```

## ✅ Solução 2: Gunicorn não existe - Instalar

Se o Gunicorn não existe, instale:

```bash
# Ativar ambiente virtual
cd /opt/s-agendamento
source .venv/bin/activate 2>/dev/null || source venv/bin/activate 2>/dev/null

# Instalar Gunicorn
pip install gunicorn

# Verificar instalação
which gunicorn
gunicorn --version

# Depois, executar o script novamente
sudo bash recriar_systemd.sh
```

## ✅ Solução 3: Ambiente virtual não existe - Criar

Se nem `.venv` nem `venv` existem:

```bash
cd /opt/s-agendamento

# Criar ambiente virtual
python3 -m venv .venv

# Ativar
source .venv/bin/activate

# Instalar dependências
pip install -r requirements.txt

# Instalar Gunicorn (se não estiver no requirements.txt)
pip install gunicorn

# Verificar
which gunicorn
```

## 🔍 Verificar Usuário do Gunicorn

O script detectou `django`, mas verifique:

```bash
# Ver se usuário django existe
id django

# Se não existir, verificar qual usuário roda processos
ps aux | grep python | head -5

# Ajustar no arquivo systemd se necessário
# User=ubuntu  (ou outro usuário)
```

## 📝 Sequência Completa

```bash
# 1. Verificar ambiente virtual
cd /opt/s-agendamento
ls -la | grep -E "venv|\.venv"

# 2. Ativar ambiente virtual
source .venv/bin/activate 2>/dev/null || source venv/bin/activate 2>/dev/null

# 3. Verificar Gunicorn
which gunicorn

# 4. Se não existir, instalar
pip install gunicorn

# 5. Atualizar script e executar novamente
git pull origin main
sudo bash recriar_systemd.sh

# 6. OU criar manualmente
sudo nano /etc/systemd/system/s-agendamento.service
# (cole o conteúdo acima com caminho correto)

# 7. Validar e reiniciar
sudo systemd-analyze verify /etc/systemd/system/s-agendamento.service
sudo systemctl daemon-reload
sudo systemctl restart s-agendamento
sudo systemctl status s-agendamento
```

## ⚠️ Importante

- O caminho do Gunicorn deve ser **absoluto** no arquivo systemd
- O usuário no systemd deve ter permissão para executar o Gunicorn
- O ambiente virtual deve estar ativado ao instalar o Gunicorn

