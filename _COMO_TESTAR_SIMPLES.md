# 🧪 Como Testar - Versão Simples (Sem Emojis)

## ⚠️ Problema: Erro de Encoding

O erro `UnicodeEncodeError` ocorre porque o terminal não suporta emojis. Use a versão sem emojis.

---

## ✅ Solução: Usar Script Sem Emojis

### No servidor, crie o arquivo:

```bash
cd ~/s_agendamento
nano test_asaas_simples_sem_emoji.py
```

### Cole o conteúdo do arquivo `test_asaas_simples_sem_emoji.py`

### Execute:

```bash
python manage.py shell < test_asaas_simples_sem_emoji.py
```

---

## ✅ Alternativa: Teste Manual (Mais Simples)

Abra o shell Python:

```bash
python manage.py shell
```

Digite estes comandos **um por vez** (pressione Enter após cada um):

```python
import os
from dotenv import load_dotenv
load_dotenv()
print("ASAAS_ENV:", os.environ.get('ASAAS_ENV'))
print("ASAAS_API_KEY_PRODUCTION:", os.environ.get('ASAAS_API_KEY_PRODUCTION') and 'OK' or 'NAO ENCONTRADA')
```

Depois teste com Django:

```python
from django.conf import settings
print("Settings ASAAS_ENV:", getattr(settings, 'ASAAS_ENV'))
print("Settings ASAAS_API_KEY:", getattr(settings, 'ASAAS_API_KEY') and 'OK' or 'NAO ENCONTRADA')
```

---

## ✅ Verificar .env Diretamente

```bash
# Ver linhas ASAAS
cat .env | grep ASAAS

# Ver se a chave está configurada
cat .env | grep "ASAAS_API_KEY_PRODUCTION"
```

**Deve mostrar:**
```
ASAAS_ENV=production
ASAAS_API_KEY_PRODUCTION=$aact_...
```

Se não aparecer, edite o `.env`:

```bash
nano .env
```

Adicione:
```env
ASAAS_API_KEY_PRODUCTION=$aact_SUA_CHAVE_AQUI
```

**Sem espaços ao redor do `=`!**

---

## 📋 Checklist Rápido

1. ✅ Arquivo `.env` existe no diretório do projeto
2. ✅ Linha `ASAAS_API_KEY_PRODUCTION=$aact_...` existe no `.env`
3. ✅ Sem espaços ao redor do `=`
4. ✅ Chave começa com `$aact_`
5. ✅ Django reiniciado após editar `.env`

---

## 🎯 Comandos Rápidos

```bash
# 1. Verificar .env
cat .env | grep ASAAS

# 2. Se não aparecer, editar
nano .env

# 3. Testar
python manage.py shell
```

No shell:
```python
import os
from dotenv import load_dotenv
load_dotenv()
print(os.environ.get('ASAAS_API_KEY_PRODUCTION') and 'OK' or 'NAO ENCONTRADA')
```

---

**Dica:** Use a versão sem emojis ou teste manualmente no shell Python!

