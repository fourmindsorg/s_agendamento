# 📋 Comandos para Testar no Shell Python

## 🎯 Passo a Passo

### 1. Abrir o Shell Python

```bash
cd ~/s_agendamento
source .venv/bin/activate
python manage.py shell
```

### 2. No Shell Python, Digite Estes Comandos (Um Por Vez)

**Comando 1:**
```python
import os
```

**Comando 2:**
```python
from dotenv import load_dotenv
```

**Comando 3:**
```python
load_dotenv()
```

**Comando 4:**
```python
print("ASAAS_ENV:", os.environ.get('ASAAS_ENV', 'NAO ENCONTRADO'))
```

**Comando 5:**
```python
print("ASAAS_API_KEY_PRODUCTION:", os.environ.get('ASAAS_API_KEY_PRODUCTION') and 'OK' or 'NAO ENCONTRADA')
```

**Comando 6:**
```python
print("ASAAS_API_KEY_SANDBOX:", os.environ.get('ASAAS_API_KEY_SANDBOX') and 'OK' or 'NAO ENCONTRADA')
```

**Comando 7:**
```python
from django.conf import settings
```

**Comando 8:**
```python
print("Settings ASAAS_ENV:", getattr(settings, 'ASAAS_ENV', 'NAO CONFIGURADO'))
```

**Comando 9:**
```python
print("Settings ASAAS_API_KEY:", getattr(settings, 'ASAAS_API_KEY', None) and 'OK' or 'NAO ENCONTRADA')
```

**Comando 10:**
```python
print("Settings ASAAS_ENABLED:", getattr(settings, 'ASAAS_ENABLED', False))
```

**Comando 11 (Opcional - Testar Cliente):**
```python
from financeiro.services.asaas import AsaasClient
```

**Comando 12:**
```python
client = AsaasClient()
```

**Comando 13:**
```python
print("Base URL:", client.base)
```

**Comando 14:**
```python
print("Ambiente:", client.env)
```

**Para Sair:**
```python
exit()
```

---

## 📋 Versão Resumida (Copiar e Colar)

Se preferir copiar tudo de uma vez, use este bloco (sem o `>>>`):

```python
import os
from dotenv import load_dotenv
load_dotenv()
print("ASAAS_ENV:", os.environ.get('ASAAS_ENV', 'NAO ENCONTRADO'))
print("ASAAS_API_KEY_PRODUCTION:", os.environ.get('ASAAS_API_KEY_PRODUCTION') and 'OK' or 'NAO ENCONTRADA')
print("ASAAS_API_KEY_SANDBOX:", os.environ.get('ASAAS_API_KEY_SANDBOX') and 'OK' or 'NAO ENCONTRADA')
from django.conf import settings
print("Settings ASAAS_ENV:", getattr(settings, 'ASAAS_ENV', 'NAO CONFIGURADO'))
print("Settings ASAAS_API_KEY:", getattr(settings, 'ASAAS_API_KEY', None) and 'OK' or 'NAO ENCONTRADA')
print("Settings ASAAS_ENABLED:", getattr(settings, 'ASAAS_ENABLED', False))
```

---

## ✅ Resultado Esperado

Se tudo estiver correto, você deve ver:

```
ASAAS_ENV: production
ASAAS_API_KEY_PRODUCTION: OK
ASAAS_API_KEY_SANDBOX: OK
Settings ASAAS_ENV: production
Settings ASAAS_API_KEY: OK
Settings ASAAS_ENABLED: True
```

---

## 🚨 Se Mostrar "NAO ENCONTRADA"

Se `ASAAS_API_KEY_PRODUCTION` mostrar "NAO ENCONTRADA":

1. **Sair do shell:** `exit()`

2. **Verificar .env:**
   ```bash
   cat .env | grep ASAAS
   ```

3. **Se não aparecer, editar:**
   ```bash
   nano .env
   ```

4. **Adicionar linha:**
   ```env
   ASAAS_API_KEY_PRODUCTION=$aact_SUA_CHAVE_PRODUCAO_AQUI
   ```

5. **Salvar e testar novamente**

---

## 📝 Checklist

- [ ] Shell Python aberto
- [ ] Comandos executados um por vez
- [ ] `ASAAS_ENV` mostra "production"
- [ ] `ASAAS_API_KEY_PRODUCTION` mostra "OK"
- [ ] `Settings ASAAS_API_KEY` mostra "OK"
- [ ] `Settings ASAAS_ENABLED` mostra "True"

---

**Dica:** Execute os comandos um por vez, pressionando Enter após cada um!

