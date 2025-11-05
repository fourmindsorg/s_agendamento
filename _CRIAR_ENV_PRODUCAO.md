# 🚀 Criar arquivo .env em produção

## ❌ Problema identificado

O diagnóstico mostrou:
- ❌ Arquivo `.env` **não existe** em `/opt/s-agendamento/.env`
- ❌ `ASAAS_API_KEY` não configurada
- ❌ `ASAAS_ENV` não definido
- ⚠️ `DJANGO_SETTINGS_MODULE` está como `core.settings` (deveria ser `core.settings_production`)
- ⚠️ `DEBUG` está `True` (deveria ser `False` em produção)

## ✅ Solução passo a passo

### 1. Criar o arquivo .env

Execute no servidor:

```bash
cd /opt/s-agendamento

# Criar arquivo .env
sudo nano .env
```

### 2. Adicionar conteúdo mínimo

Cole o seguinte conteúdo no arquivo `.env`:

```bash
# Django
SECRET_KEY=sua-chave-secreta-aqui-use-uma-chave-forte-aleatoria
DEBUG=False
ALLOWED_HOSTS=fourmindstech.com.br,www.fourmindstech.com.br,localhost,127.0.0.1

# Database (ajuste conforme sua configuração)
DB_NAME=s_agendamento
DB_USER=postgres
DB_PASSWORD=sua-senha-postgres
DB_HOST=localhost
DB_PORT=5432

# Asaas - PRODUÇÃO
ASAAS_API_KEY=$aact_SUA_CHAVE_PRODUCAO_AQUI
ASAAS_ENV=production
ASAAS_ENABLED=True

# Outras configurações (ajuste conforme necessário)
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USE_TLS=True
EMAIL_HOST_USER=seu-email@gmail.com
EMAIL_HOST_PASSWORD=sua-senha-email
```

### 3. Substituir valores

**IMPORTANTE:** Substitua os seguintes valores:

- `sua-chave-secreta-aqui-use-uma-chave-forte-aleatoria` → Gere uma chave secreta forte:
  ```bash
  python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"
  ```

- `$aact_SUA_CHAVE_PRODUCAO_AQUI` → Sua chave de produção do Asaas (formato: `$aact_prod_...`)

- `sua-senha-postgres` → Senha do banco de dados PostgreSQL

- Outras configurações de email e banco conforme necessário

### 4. Ajustar permissões

```bash
# Dar propriedade ao usuário do Gunicorn (geralmente 'django' ou 'ubuntu')
sudo chown django:django /opt/s-agendamento/.env

# OU, se for o usuário ubuntu:
sudo chown ubuntu:ubuntu /opt/s-agendamento/.env

# Proteger o arquivo (apenas leitura para outros)
sudo chmod 640 /opt/s-agendamento/.env

# Verificar
ls -la /opt/s-agendamento/.env
```

### 5. Verificar configuração do Gunicorn

O Gunicorn precisa estar configurado para usar `core.settings_production`:

```bash
# Verificar arquivo do systemd
sudo cat /etc/systemd/system/s-agendamento.service

# OU verificar Supervisor
sudo cat /etc/supervisor/conf.d/s-agendamento.conf
```

**Deve conter:**
```ini
Environment=DJANGO_SETTINGS_MODULE=core.settings_production
```

Se não estiver, ajuste:

**Para systemd:**
```bash
sudo nano /etc/systemd/system/s-agendamento.service
```

Adicione ou ajuste:
```ini
[Service]
Environment=DJANGO_SETTINGS_MODULE=core.settings_production
```

Depois:
```bash
sudo systemctl daemon-reload
sudo systemctl restart s-agendamento
```

**Para Supervisor:**
```bash
sudo nano /etc/supervisor/conf.d/s-agendamento.conf
```

Adicione ou ajuste:
```ini
environment=DJANGO_SETTINGS_MODULE="core.settings_production"
```

Depois:
```bash
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl restart s-agendamento
```

### 6. Reiniciar o serviço

```bash
# Se usar systemd
sudo systemctl restart s-agendamento

# Se usar Supervisor
sudo supervisorctl restart s-agendamento

# Verificar status
sudo systemctl status s-agendamento
# OU
sudo supervisorctl status s-agendamento
```

### 7. Verificar se funcionou

Execute o diagnóstico novamente:

```bash
cd /opt/s-agendamento
source venv/bin/activate  # ou .venv/bin/activate se usar .venv
python manage.py diagnosticar_asaas
```

**Deve mostrar:**
- ✅ Arquivo `.env` existe
- ✅ `ASAAS_API_KEY` configurada
- ✅ `ASAAS_ENV` = production
- ✅ `AsaasClient` inicializado com sucesso

### 8. Verificar logs

```bash
# Ver logs do Gunicorn
sudo journalctl -u s-agendamento -n 100 | grep -i asaas

# OU, se usar Supervisor
sudo tail -n 100 /opt/s-agendamento/logs/gunicorn.log | grep -i asaas
```

**Deve mostrar:**
```
[PRODUCTION] Arquivo .env carregado de: /opt/s-agendamento/.env
[PRODUCTION] ASAAS_API_KEY carregada com sucesso
```

## 🔍 Troubleshooting

### Se o .env não for carregado

1. Verificar se o arquivo existe:
   ```bash
   ls -la /opt/s-agendamento/.env
   ```

2. Verificar permissões:
   ```bash
   ls -la /opt/s-agendamento/.env
   # Deve mostrar: -rw-r----- 1 django django (ou ubuntu ubuntu)
   ```

3. Verificar se o usuário do Gunicorn tem acesso:
   ```bash
   # Ver qual usuário roda o Gunicorn
   ps aux | grep gunicorn
   # Ajustar propriedade se necessário
   sudo chown USUARIO_DO_GUNICORN:USUARIO_DO_GUNICORN /opt/s-agendamento/.env
   ```

4. Verificar se o caminho está correto:
   ```bash
   # O BASE_DIR deve apontar para /opt/s-agendamento
   python manage.py shell
   >>> from django.conf import settings
   >>> from pathlib import Path
   >>> print(Path(settings.BASE_DIR) / '.env')
   ```

### Se ainda aparecer "ASAAS_API_KEY não configurada"

1. Verificar se está no arquivo:
   ```bash
   grep ASAAS_API_KEY /opt/s-agendamento/.env
   ```

2. Verificar se não tem espaços extras:
   ```bash
   # Formato correto (SEM espaços ao redor do =)
   ASAAS_API_KEY=$aact_prod_...
   # ERRADO:
   ASAAS_API_KEY = $aact_prod_...
   ```

3. Verificar se não tem aspas desnecessárias:
   ```bash
   # Formato correto (SEM aspas)
   ASAAS_API_KEY=$aact_prod_...
   # ERRADO:
   ASAAS_API_KEY="$aact_prod_..."
   ```

4. Reiniciar o serviço:
   ```bash
   sudo systemctl restart s-agendamento
   ```

## 📝 Checklist final

- [ ] Arquivo `.env` criado em `/opt/s-agendamento/.env`
- [ ] `ASAAS_API_KEY` configurada (formato: `$aact_prod_...`)
- [ ] `ASAAS_ENV=production` configurado
- [ ] `SECRET_KEY` configurada (chave forte gerada)
- [ ] `DEBUG=False` configurado
- [ ] Permissões corretas no arquivo `.env` (640, usuário do Gunicorn)
- [ ] Gunicorn configurado com `DJANGO_SETTINGS_MODULE=core.settings_production`
- [ ] Serviço reiniciado
- [ ] Diagnóstico executado e passou
- [ ] Logs mostram carregamento da chave

## ⚠️ Segurança

- **NUNCA** commite o arquivo `.env` no Git
- **NUNCA** compartilhe o arquivo `.env` publicamente
- Use permissões restritivas (640)
- Mantenha backups seguros do arquivo `.env`
- Use chaves de API diferentes para desenvolvimento e produção

