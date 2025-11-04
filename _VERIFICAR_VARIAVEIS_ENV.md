# 🔍 Verificar Variáveis de Ambiente

## ⚠️ Problema Identificado

O Django settings não está encontrando a chave, mesmo usando `ASAAS_API_KEY_SANDBOX` e `ASAAS_API_KEY_PRODUCTION`.

---

## 🔍 Passo 1: Verificar Variáveis no Shell Python

No shell Python, digite estes comandos:

```python
import os
from dotenv import load_dotenv
load_dotenv()

print("ASAAS_ENV:", os.environ.get('ASAAS_ENV'))
print("ASAAS_API_KEY_PRODUCTION:", os.environ.get('ASAAS_API_KEY_PRODUCTION') and 'OK' or 'NAO ENCONTRADA')
print("ASAAS_API_KEY_SANDBOX:", os.environ.get('ASAAS_API_KEY_SANDBOX') and 'OK' or 'NAO ENCONTRADA')
```

**Se mostrar "NAO ENCONTRADA", o problema está no `.env`.**

---

## 🔍 Passo 2: Verificar Arquivo .env

No servidor (fora do shell Python), execute:

```bash
cat .env | grep ASAAS
```

**Deve mostrar:**
```
ASAAS_ENV=production
ASAAS_API_KEY_PRODUCTION=$aact_...
ASAAS_API_KEY_SANDBOX=$aact_...
```

---

## ✅ Solução: Verificar e Corrigir .env

### 1. Verificar conteúdo do .env:

```bash
cat .env | grep ASAAS
```

### 2. Se não aparecer, editar:

```bash
nano .env
```

### 3. Adicionar/Verificar estas linhas:

```env
ASAAS_ENV=production
ASAAS_API_KEY_PRODUCTION=$aact_SUA_CHAVE_PRODUCAO_AQUI
ASAAS_API_KEY_SANDBOX=$aact_SUA_CHAVE_SANDBOX_AQUI
```

**IMPORTANTE:**
- ✅ Sem espaços ao redor do `=`
- ✅ Sem aspas nos valores
- ✅ Chave começa com `$aact_`

### 4. Verificar formato correto:

```bash
# Ver linhas ASAAS com formatação
cat .env | grep ASAAS | cat -A
```

**Deve mostrar:**
```
ASAAS_ENV=production$
ASAAS_API_KEY_PRODUCTION=$aact_...$
```

**Se mostrar espaços ou caracteres estranhos, está errado!**

---

## ✅ Testar Após Corrigir

### 1. No shell Python:

```python
import os
from dotenv import load_dotenv
load_dotenv()

print("Variáveis após load_dotenv():")
print("ASAAS_ENV:", os.environ.get('ASAAS_ENV'))
print("ASAAS_API_KEY_PRODUCTION:", os.environ.get('ASAAS_API_KEY_PRODUCTION')[:20] + '...' if os.environ.get('ASAAS_API_KEY_PRODUCTION') else 'NAO ENCONTRADA')
print("ASAAS_API_KEY_SANDBOX:", os.environ.get('ASAAS_API_KEY_SANDBOX')[:20] + '...' if os.environ.get('ASAAS_API_KEY_SANDBOX') else 'NAO ENCONTRADA')
```

### 2. Verificar qual chave será usada:

```python
asaas_env = os.environ.get('ASAAS_ENV', 'sandbox').lower()
if asaas_env == 'sandbox':
    chave = os.environ.get('ASAAS_API_KEY_SANDBOX') or os.environ.get('ASAAS_API_KEY')
    print("Chave usada (sandbox):", chave[:20] + '...' if chave else 'NAO ENCONTRADA')
else:
    chave = os.environ.get('ASAAS_API_KEY_PRODUCTION') or os.environ.get('ASAAS_API_KEY')
    print("Chave usada (production):", chave[:20] + '...' if chave else 'NAO ENCONTRADA')
```

### 3. Testar Django settings:

```python
from django.conf import settings
print("Settings ASAAS_ENV:", getattr(settings, 'ASAAS_ENV', 'NAO CONFIGURADO'))
print("Settings ASAAS_API_KEY:", getattr(settings, 'ASAAS_API_KEY', None) and 'OK' or 'NAO ENCONTRADA')
print("Settings ASAAS_ENABLED:", getattr(settings, 'ASAAS_ENABLED', False))
```

---

## 🚨 Problemas Comuns

### 1. Variáveis não aparecem após `load_dotenv()`

**Causa:** `.env` não está no diretório correto ou `python-dotenv` não está instalado

**Solução:**
```python
from pathlib import Path
print("Diretório atual:", Path.cwd())
print(".env existe:", Path('.env').exists())
print(".env caminho:", Path('.env').absolute())
```

### 2. Variáveis aparecem mas Django não encontra

**Causa:** Django foi iniciado antes de carregar o `.env`

**Solução:** Reiniciar o Django após editar `.env`

### 3. Formato incorreto no .env

**Causa:** Espaços ou caracteres especiais

**Solução:**
```bash
# Ver formato exato
cat .env | grep ASAAS | od -c
```

---

## 📋 Checklist Completo

- [ ] `.env` existe no diretório do projeto
- [ ] `ASAAS_ENV=production` está no `.env`
- [ ] `ASAAS_API_KEY_PRODUCTION=$aact_...` está no `.env`
- [ ] `ASAAS_API_KEY_SANDBOX=$aact_...` está no `.env`
- [ ] Sem espaços ao redor do `=`
- [ ] Sem aspas nos valores
- [ ] `python-dotenv` está instalado
- [ ] `load_dotenv()` retorna `True`
- [ ] Variáveis aparecem em `os.environ` após `load_dotenv()`
- [ ] Django settings mostra chave configurada

---

**Dica:** Execute primeiro o teste no shell Python para ver se as variáveis aparecem após `load_dotenv()`!

