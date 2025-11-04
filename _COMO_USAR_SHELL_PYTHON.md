# 🐍 Como Usar o Shell Python do Django

## ⚠️ Erro Comum

Você está fazendo isso:
```python
>>> >>> import os  # ❌ ERRO! Não digite o >>>
```

O `>>>` é apenas um **indicador visual** que o Python mostra automaticamente. Você **NÃO deve digitar** o `>>>`!

---

## ✅ Correto

No shell Python, digite apenas os comandos:

```python
>>> import os
```

**Como fazer:**
1. O Python mostra `>>>` automaticamente
2. Você digita apenas: `import os`
3. Pressiona Enter

---

## 📋 Comandos Corretos para Testar Variáveis

### No servidor, execute:

```bash
python manage.py shell
```

### No shell Python, digite APENAS isto (sem o >>>):

```python
import os
from dotenv import load_dotenv
load_dotenv()
print(os.environ.get('ASAAS_ENV'))
print(os.environ.get('ASAAS_API_KEY_PRODUCTION')[:20] + '...')
```

**Ou teste com settings do Django:**

```python
from django.conf import settings
print(getattr(settings, 'ASAAS_ENV', 'NÃO CONFIGURADO'))
print(getattr(settings, 'ASAAS_API_KEY', None) and '✅ Configurada' or '❌ Não configurada')
```

---

## 🎯 Passo a Passo Visual

### 1. Abrir o shell:
```bash
python manage.py shell
```

### 2. Você verá:
```
Python 3.10.12 (main, Aug 15 2025, 14:32:43) [GCC 11.4.0] on linux
Type "help", "copyright", "credits" or "license" for more information.
(InteractiveConsole)
>>> 
```

### 3. Digite (SEM o >>>):
```
import os
```
Pressione Enter

### 4. Você verá:
```
>>> import os
>>> 
```

### 5. Digite o próximo comando:
```
from dotenv import load_dotenv
```
Pressione Enter

### 6. Continue digitando os comandos, um por vez, SEM o >>>.

---

## 📝 Script Completo para Copiar e Colar

Se quiser copiar tudo de uma vez, use este formato (sem o >>>):

```python
import os
from dotenv import load_dotenv
load_dotenv()
print("ASAAS_ENV:", os.environ.get('ASAAS_ENV'))
print("ASAAS_API_KEY_PRODUCTION:", os.environ.get('ASAAS_API_KEY_PRODUCTION')[:20] + '...' if os.environ.get('ASAAS_API_KEY_PRODUCTION') else 'NÃO CONFIGURADO')
from django.conf import settings
print("Settings ASAAS_ENV:", getattr(settings, 'ASAAS_ENV', 'NÃO CONFIGURADO'))
print("Settings ASAAS_API_KEY:", '✅ Configurada' if getattr(settings, 'ASAAS_API_KEY', None) else '❌ Não configurada')
```

---

## ✅ Alternativa: Usar Script Python

Crie um arquivo de teste:

```bash
# No servidor
nano test_asaas.py
```

Cole este conteúdo:

```python
import os
from pathlib import Path
from dotenv import load_dotenv

# Carregar .env
load_dotenv()

print("=" * 50)
print("🔍 Verificação de Variáveis Asaas")
print("=" * 50)
print()
print(f"ASAAS_ENV: {os.environ.get('ASAAS_ENV', 'NÃO ENCONTRADO')}")
print(f"ASAAS_API_KEY_PRODUCTION: {'✅ Configurada' if os.environ.get('ASAAS_API_KEY_PRODUCTION') else '❌ Não configurada'}")
if os.environ.get('ASAAS_API_KEY_PRODUCTION'):
    key = os.environ.get('ASAAS_API_KEY_PRODUCTION')
    print(f"   Chave (mascarada): {key[:10]}...{key[-10:]}")
print()

# Testar com Django settings
import django
django.setup()
from django.conf import settings

print("Configurações do Django:")
print(f"ASAAS_ENV: {getattr(settings, 'ASAAS_ENV', 'NÃO CONFIGURADO')}")
print(f"ASAAS_API_KEY: {'✅ Configurada' if getattr(settings, 'ASAAS_API_KEY', None) else '❌ Não configurada'}")
print(f"ASAAS_ENABLED: {getattr(settings, 'ASAAS_ENABLED', False)}")
```

Execute:

```bash
python manage.py shell < test_asaas.py
```

---

## 🎯 Solução Mais Simples

Use o script que já criamos:

```bash
# No servidor
python _VERIFICAR_CONFIGURACAO_ASAAS.py
```

Este script já faz tudo automaticamente!

---

## 📋 Resumo

1. ✅ **NÃO digite** o `>>>` - ele aparece automaticamente
2. ✅ Digite apenas o comando: `import os`
3. ✅ Pressione Enter após cada comando
4. ✅ Ou use o script: `python _VERIFICAR_CONFIGURACAO_ASAAS.py`

---

**Dica:** Se preferir, use o script `_VERIFICAR_CONFIGURACAO_ASAAS.py` que já faz tudo automaticamente!

