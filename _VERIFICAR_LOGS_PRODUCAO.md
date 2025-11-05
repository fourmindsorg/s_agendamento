# 🔍 Verificar Logs de Produção

## ✅ Status do Serviço

O serviço está rodando! Verifique se os logs de produção estão sendo gerados.

## 🔍 Verificar Logs

Execute no servidor:

```bash
# 1. Ver todos os logs recentes (sem filtro)
sudo journalctl -u s-agendamento -n 200 --no-pager

# 2. Ver logs desde o início do serviço
sudo journalctl -u s-agendamento --since "10 minutes ago" --no-pager

# 3. Procurar por mensagens de produção
sudo journalctl -u s-agendamento -n 200 | grep -i -E "(production|settings|env|asaas)" --color=always

# 4. Ver logs do Django especificamente
sudo journalctl -u s-agendamento -n 200 | grep -i django

# 5. Ver erros
sudo journalctl -u s-agendamento -n 200 | grep -i error
```

## 🔍 Verificar se Settings está Carregando

```bash
# Verificar se o settings_production está sendo usado
sudo journalctl -u s-agendamento --since "10 minutes ago" | grep -i "settings_production"

# Verificar se o .env está sendo carregado
sudo journalctl -u s-agendamento --since "10 minutes ago" | grep -i ".env"
```

## 📝 Logs Esperados

Se tudo estiver configurado corretamente, você deve ver:

```
[PRODUCTION] Arquivo .env carregado de: /opt/s-agendamento/.env
[PRODUCTION] ASAAS_API_KEY carregada com sucesso
```

## ⚠️ Se os Logs Não Aparecerem

Se os logs de `[PRODUCTION]` não aparecerem, pode ser que:

1. **O logging não está configurado para produção**
   - Verificar `core/settings_production.py`
   - Verificar se o logger está configurado

2. **O Django não está usando settings_production**
   - Verificar se `DJANGO_SETTINGS_MODULE=core.settings_production` está no systemd
   - Verificar variável de ambiente: `sudo cat /etc/systemd/system/s-agendamento.service | grep Environment`

3. **Os logs estão indo para outro lugar**
   - Verificar arquivos de log: `ls -la /opt/s-agendamento/logs/`
   - Verificar se há redirecionamento de logs

## 🔍 Verificar Configuração do Logging

```bash
# Verificar se o settings_production tem logging configurado
grep -i "logging" /opt/s-agendamento/core/settings_production.py

# Verificar se há arquivos de log
ls -la /opt/s-agendamento/logs/ 2>/dev/null || echo "Diretório logs não existe"
```

## 🧪 Testar Acesso

```bash
# Testar se o serviço responde
curl -I http://localhost

# OU via socket (se Nginx estiver configurado)
curl -I https://fourmindstech.com.br

# Ver logs em tempo real enquanto testa
sudo journalctl -u s-agendamento -f
```

## 📝 Verificar Variável de Ambiente

```bash
# Verificar se a variável está no arquivo systemd
sudo cat /etc/systemd/system/s-agendamento.service | grep Environment

# Deve mostrar:
# Environment=DJANGO_SETTINGS_MODULE=core.settings_production

# Verificar se o processo está usando a variável
sudo cat /proc/$(pgrep -f "gunicorn.*s-agendamento" | head -1)/environ | tr '\0' '\n' | grep DJANGO
```

