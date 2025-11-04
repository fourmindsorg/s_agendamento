# 🔄 Atualizar Código no Servidor - Resolver Erro ASAAS_API_KEY_SANDBOX

## ❌ Problema
O erro ainda menciona `ASAAS_API_KEY_SANDBOX`, o que significa que o servidor está usando **código antigo**.

## ✅ Solução

### 1. Atualizar Código
```bash
cd ~/s_agendamento
git pull origin main
```

### 2. Limpar Cache Python
```bash
# Limpar arquivos .pyc (bytecode cache)
find . -type f -name "*.pyc" -delete
find . -type d -name "__pycache__" -exec rm -r {} + 2>/dev/null || true

# Se estiver usando ambiente virtual
source .venv/bin/activate  # ou source venv/bin/activate
```

### 3. Verificar Código Atualizado
```bash
# Verificar se o arquivo foi atualizado
grep -n "ASAAS_API_KEY_SANDBOX" financeiro/services/asaas.py

# Se mostrar resultados, o código não foi atualizado
# Se não mostrar nada, o código está atualizado ✅
```

### 4. Reiniciar Gunicorn
```bash
# Parar gunicorn
sudo systemctl stop gunicorn

# Aguardar alguns segundos
sleep 3

# Iniciar gunicorn
sudo systemctl start gunicorn

# Verificar status
sudo systemctl status gunicorn
```

### 5. Verificar Logs
```bash
# Ver logs do Gunicorn
sudo journalctl -u gunicorn -n 50 --no-pager

# Ver logs do Django (se existir arquivo)
tail -n 50 /opt/s-agendamento/logs/django.log 2>/dev/null || echo "Arquivo de log não encontrado"
```

### 6. Testar
Tente fazer o checkout novamente. A mensagem de erro deve ser:

```
ASAAS_API_KEY não configurada nas variáveis de ambiente. 
Configure ASAAS_API_KEY no arquivo .env. 
Ambiente atual: production
```

**NÃO deve mais mencionar** `ASAAS_API_KEY_SANDBOX` ou `ASAAS_API_KEY_PRODUCTION`.

---

## 🔍 Verificar Configuração

### Verificar se ASAAS_API_KEY está configurada
```bash
# Verificar no arquivo .env
cat .env | grep ASAAS_API_KEY

# Deve mostrar algo como:
# ASAAS_API_KEY=$aact_SUA_CHAVE_AQUI
```

### Se não estiver configurada, adicionar:
```bash
# Editar arquivo .env
nano .env

# Adicionar linha:
ASAAS_API_KEY=$aact_SUA_CHAVE_PRODUCAO_AQUI
```

### Verificar variável de ambiente
```bash
# Testar no shell Python
python manage.py shell

# No shell Python:
>>> import os
>>> print(os.environ.get('ASAAS_API_KEY'))
# Deve mostrar a chave (ou None se não estiver configurada)
```

---

## 🚨 Se o Problema Persistir

### 1. Verificar se o código foi realmente atualizado
```bash
# Ver última alteração no arquivo
git log --oneline -5 financeiro/services/asaas.py

# Verificar conteúdo atual
grep -A 5 "Configure ASAAS_API_KEY" financeiro/services/asaas.py
```

### 2. Forçar reinicialização completa
```bash
# Parar todos os processos Python relacionados
sudo pkill -f gunicorn
sudo pkill -f "python.*manage.py"

# Limpar completamente o cache
find . -type f -name "*.pyc" -delete
find . -type d -name "__pycache__" -exec rm -r {} + 2>/dev/null || true

# Reiniciar Gunicorn
sudo systemctl restart gunicorn

# Aguardar alguns segundos
sleep 5

# Verificar se está rodando
ps aux | grep gunicorn
```

### 3. Verificar qual arquivo de settings está sendo usado
```bash
# Ver variável de ambiente
echo $DJANGO_SETTINGS_MODULE

# Ver no systemd service
sudo systemctl cat gunicorn | grep DJANGO_SETTINGS_MODULE
```

### 4. Testar diretamente no Python
```bash
python manage.py shell
```

```python
# No shell Python:
from financeiro.services.asaas import AsaasClient
try:
    client = AsaasClient()
    print("✅ Cliente criado com sucesso")
except RuntimeError as e:
    print(f"❌ Erro: {e}")
    # A mensagem deve mencionar apenas ASAAS_API_KEY
```

---

## 📝 Checklist

- [ ] Código atualizado: `git pull origin main`
- [ ] Cache Python limpo: `find . -name "*.pyc" -delete`
- [ ] Gunicorn reiniciado: `sudo systemctl restart gunicorn`
- [ ] ASAAS_API_KEY configurada no `.env`
- [ ] Mensagem de erro não menciona mais `ASAAS_API_KEY_SANDBOX`

---

**Status:** ✅ Código atualizado e pronto para aplicar no servidor!

