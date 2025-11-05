# 🔧 Corrigir Permissões do .env para Gunicorn

## ❌ Problema
O arquivo `.env` tem permissão negada para o usuário do Gunicorn.

## 🔍 Verificar Usuário do Gunicorn

```bash
# Ver qual usuário está rodando o Gunicorn
ps aux | grep gunicorn | grep -v grep | awk '{print $1}'

# Verificar no arquivo systemd
sudo cat /etc/systemd/system/s-agendamento.service | grep "^User="
```

## ✅ Solução

### Se o usuário for `django`:

```bash
# Ajustar propriedade e permissões
sudo chown django:django /opt/s-agendamento/.env
sudo chmod 640 /opt/s-agendamento/.env

# Verificar
ls -la /opt/s-agendamento/.env
# Deve mostrar: -rw-r----- 1 django django

# Reiniciar serviço
sudo systemctl restart s-agendamento
```

### Se o usuário for `ubuntu`:

```bash
# Ajustar propriedade e permissões
sudo chown ubuntu:ubuntu /opt/s-agendamento/.env
sudo chmod 640 /opt/s-agendamento/.env

# Verificar
ls -la /opt/s-agendamento/.env
# Deve mostrar: -rw-r----- 1 ubuntu ubuntu

# Reiniciar serviço
sudo systemctl restart s-agendamento
```

## 🔍 Verificar Logs Após Correção

```bash
# Ver logs do Gunicorn para verificar se o .env foi carregado
sudo journalctl -u s-agendamento -n 100 | grep -i -E "(production|env|asaas|error)"

# Deve mostrar:
# [PRODUCTION] Arquivo .env carregado de: /opt/s-agendamento/.env
# [PRODUCTION] ASAAS_API_KEY carregada com sucesso
```

## 📝 Verificar se Funciona

```bash
# Testar como usuário do Gunicorn
sudo -u django cat /opt/s-agendamento/.env | head -5

# OU se for ubuntu:
sudo -u ubuntu cat /opt/s-agendamento/.env | head -5
```

Se funcionar, o Gunicorn também conseguirá ler o arquivo.

