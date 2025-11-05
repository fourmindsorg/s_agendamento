# 🔍 Verificar Erro 203/EXEC do Gunicorn

## ❌ Problema
```
status=203/EXEC
Failed to start Sistema de Agendamento - 4Minds
```

Isso significa que o Gunicorn não pode ser executado.

## 🔍 Diagnóstico

Execute no servidor:

```bash
# 1. Verificar se o Gunicorn existe
ls -la /opt/s-agendamento/.venv/bin/gunicorn

# 2. Verificar permissões
ls -la /opt/s-agendamento/.venv/bin/gunicorn | awk '{print $1, $3, $4}'

# 3. Tentar executar manualmente como usuário do serviço
sudo -u django /opt/s-agendamento/.venv/bin/gunicorn --version

# OU se o usuário for ubuntu:
sudo -u ubuntu /opt/s-agendamento/.venv/bin/gunicorn --version
```

## ✅ Soluções

### Solução 1: Ajustar Permissões do Gunicorn

```bash
# Dar permissão de execução
sudo chmod +x /opt/s-agendamento/.venv/bin/gunicorn

# Ajustar propriedade (se necessário)
sudo chown django:django /opt/s-agendamento/.venv/bin/gunicorn

# Verificar
ls -la /opt/s-agendamento/.venv/bin/gunicorn
# Deve mostrar: -rwxr-xr-x (ou -rwxr-x--- se for restrito)

# Reiniciar
sudo systemctl restart s-agendamento
```

### Solução 2: Verificar se o Ambiente Virtual está Completo

```bash
# Verificar se o Python está no ambiente virtual
ls -la /opt/s-agendamento/.venv/bin/python*

# Verificar se todas as dependências estão instaladas
cd /opt/s-agendamento
source .venv/bin/activate
pip list | grep gunicorn
which gunicorn
```

### Solução 3: Reinstalar Gunicorn

```bash
cd /opt/s-agendamento
source .venv/bin/activate

# Reinstalar Gunicorn
pip install --upgrade gunicorn

# Verificar instalação
which gunicorn
gunicorn --version

# Ajustar permissões
sudo chmod +x /opt/s-agendamento/.venv/bin/gunicorn
sudo chown django:django /opt/s-agendamento/.venv/bin/gunicorn

# Reiniciar
sudo systemctl restart s-agendamento
```

### Solução 4: Verificar Shebang do Gunicorn

```bash
# Verificar primeira linha do arquivo gunicorn
head -1 /opt/s-agendamento/.venv/bin/gunicorn

# Deve mostrar algo como:
# #!/opt/s-agendamento/.venv/bin/python3
# OU
# #!/usr/bin/env python3

# Se o shebang estiver errado, pode precisar reinstalar
```

### Solução 5: Verificar Permissões do Diretório

```bash
# Verificar permissões do diretório .venv
ls -la /opt/s-agendamento/ | grep venv

# Verificar permissões do diretório bin
ls -la /opt/s-agendamento/.venv/ | grep bin

# Ajustar se necessário
sudo chown -R django:django /opt/s-agendamento/.venv
sudo chmod -R 755 /opt/s-agendamento/.venv/bin
```

## 🔍 Verificar Usuário do Serviço

```bash
# Ver qual usuário está configurado
sudo cat /etc/systemd/system/s-agendamento.service | grep "^User="

# Verificar se o usuário existe
id django
# OU
id ubuntu

# Verificar se o usuário tem acesso ao diretório
sudo -u django ls -la /opt/s-agendamento/.venv/bin/gunicorn
```

## 📝 Sequência Completa de Correção

```bash
# 1. Verificar se existe
ls -la /opt/s-agendamento/.venv/bin/gunicorn

# 2. Ajustar permissões
sudo chmod +x /opt/s-agendamento/.venv/bin/gunicorn
sudo chown django:django /opt/s-agendamento/.venv/bin/gunicorn

# 3. Testar execução como usuário do serviço
sudo -u django /opt/s-agendamento/.venv/bin/gunicorn --version

# 4. Se não funcionar, reinstalar
cd /opt/s-agendamento
source .venv/bin/activate
pip install --upgrade --force-reinstall gunicorn

# 5. Ajustar permissões novamente
sudo chmod +x /opt/s-agendamento/.venv/bin/gunicorn
sudo chown -R django:django /opt/s-agendamento/.venv/bin

# 6. Reiniciar
sudo systemctl restart s-agendamento
sudo systemctl status s-agendamento
```

## ⚠️ Se o Ambiente Virtual Estiver em Outro Lugar

Se o ambiente virtual não estiver em `.venv`, verifique:

```bash
# Verificar onde está
ls -la /opt/s-agendamento/ | grep -E "venv|\.venv"

# Ajustar o arquivo systemd com o caminho correto
sudo nano /etc/systemd/system/s-agendamento.service
```

