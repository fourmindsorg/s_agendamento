# 🔧 Ajustar DJANGO_SETTINGS_MODULE para produção

## ✅ Status Atual

O diagnóstico mostra que tudo está funcionando, EXCETO:
- ⚠️ `DJANGO_SETTINGS_MODULE` está como `core.settings` (deveria ser `core.settings_production`)

## 🔍 Verificar Configuração Atual

Execute no servidor:

```bash
# Verificar arquivo do systemd
sudo cat /etc/systemd/system/s-agendamento.service
```

Procure pela linha:
```ini
Environment=DJANGO_SETTINGS_MODULE=core.settings_production
```

## ✅ Solução: Ajustar arquivo do systemd

### 1. Editar arquivo do serviço

```bash
sudo nano /etc/systemd/system/s-agendamento.service
```

### 2. Adicionar/ajustar variável de ambiente

O arquivo deve ter algo assim:

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
ExecStart=/opt/s-agendamento/venv/bin/gunicorn core.wsgi:application --bind unix:/opt/s-agendamento/s-agendamento.sock --workers 3 --timeout 60
ExecReload=/bin/kill -s HUP $MAINPID
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
```

**IMPORTANTE:** A linha `Environment=DJANGO_SETTINGS_MODULE=core.settings_production` deve estar na seção `[Service]`.

### 3. Recarregar e reiniciar

```bash
# Recarregar configuração do systemd
sudo systemctl daemon-reload

# Reiniciar o serviço
sudo systemctl restart s-agendamento

# Verificar status
sudo systemctl status s-agendamento
```

### 4. Verificar logs

```bash
# Ver logs recentes do Gunicorn
sudo journalctl -u s-agendamento -n 50 | grep -i -E "(settings|asaas|production)"

# Deve mostrar:
# [PRODUCTION] Arquivo .env carregado de: /opt/s-agendamento/.env
# [PRODUCTION] ASAAS_API_KEY carregada com sucesso
```

## 🔍 Alternativa: Se usar Supervisor

Se o projeto usa Supervisor em vez de systemd:

```bash
# Editar configuração do Supervisor
sudo nano /etc/supervisor/conf.d/s-agendamento.conf
```

Adicionar/ajustar:
```ini
[program:s-agendamento]
command=/opt/s-agendamento/venv/bin/gunicorn core.wsgi:application --bind unix:/opt/s-agendamento/s-agendamento.sock --workers 3
directory=/opt/s-agendamento
user=django
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/opt/s-agendamento/logs/gunicorn.log
stderr_logfile=/opt/s-agendamento/logs/gunicorn_error.log
environment=DJANGO_SETTINGS_MODULE="core.settings_production"
```

Depois:
```bash
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl restart s-agendamento
```

## ✅ Verificação Final

Após ajustar, verifique:

1. **Status do serviço:**
   ```bash
   sudo systemctl status s-agendamento
   ```

2. **Logs do Gunicorn:**
   ```bash
   sudo journalctl -u s-agendamento -n 100 | grep -i production
   ```

3. **Testar requisição HTTP:**
   ```bash
   curl -I https://fourmindstech.com.br
   ```

4. **Testar geração de QR Code:**
   - Acesse a aplicação e tente gerar um QR Code
   - Deve funcionar sem erros de `ASAAS_API_KEY`

## 📝 Checklist

- [ ] Arquivo `/etc/systemd/system/s-agendamento.service` editado
- [ ] Linha `Environment=DJANGO_SETTINGS_MODULE=core.settings_production` adicionada
- [ ] `systemctl daemon-reload` executado
- [ ] `systemctl restart s-agendamento` executado
- [ ] Logs mostram `[PRODUCTION]` e `ASAAS_API_KEY carregada`
- [ ] Teste de geração de QR Code funcionando

## ⚠️ Importante

- O comando `python manage.py diagnosticar_asaas` executado manualmente sempre usa `core.settings` (padrão)
- O importante é que o **Gunicorn** use `core.settings_production`
- Após ajustar, o Gunicorn carregará as configurações de produção corretamente

