# 🔧 Como Corrigir: ASAAS_API_KEY_PRODUCTION não encontrada

## ⚠️ Problema Identificado

O teste mostrou:
```
ASAAS_ENV: production ✅
ASAAS_API_KEY_PRODUCTION: ❌ Não configurada
```

---

## 🔍 Passo 1: Verificar o Arquivo .env

No servidor, execute:

```bash
cd ~/s_agendamento
cat .env | grep ASAAS
```

**Deve mostrar algo como:**
```
ASAAS_ENV=production
ASAAS_API_KEY_PRODUCTION=$aact_YTU5YTE0M2M2N2I4MTIxN2E2...
ASAAS_API_KEY_SANDBOX=$aact_YTU5YTE0M2M2N2I4MTIxN2E2...
```

---

## ✅ Solução 1: Verificar se a Linha Existe

Se não aparecer `ASAAS_API_KEY_PRODUCTION`, adicione:

```bash
nano .env
```

**Adicione estas linhas (substitua pela sua chave real):**

```env
ASAAS_ENV=production
ASAAS_API_KEY_PRODUCTION=$aact_SUA_CHAVE_PRODUCAO_AQUI
ASAAS_API_KEY_SANDBOX=$aact_SUA_CHAVE_SANDBOX_AQUI
```

**IMPORTANTE:**
- ✅ Sem espaços ao redor do `=`
- ✅ Sem aspas nos valores
- ✅ A chave deve começar com `$aact_`

---

## ✅ Solução 2: Verificar Formato Correto

O arquivo `.env` deve ter este formato:

```env
# ✅ CORRETO
ASAAS_ENV=production
ASAAS_API_KEY_PRODUCTION=$aact_YTU5YTE0M2M2N2I4MTIxN2E2MTExYTBiYjE1MGQ4

# ❌ ERRADO (com espaços)
ASAAS_ENV = production
ASAAS_API_KEY_PRODUCTION = $aact_...

# ❌ ERRADO (com aspas)
ASAAS_API_KEY_PRODUCTION="$aact_..."
ASAAS_API_KEY_PRODUCTION='$aact_...'
```

---

## ✅ Solução 3: Verificar Localização do .env

O arquivo `.env` deve estar no mesmo diretório do `manage.py`:

```bash
# Verificar onde está o manage.py
cd ~/s_agendamento
ls -la manage.py

# Verificar se .env está no mesmo lugar
ls -la .env

# Deve estar no mesmo diretório!
```

---

## ✅ Solução 4: Recarregar Variáveis

Após editar o `.env`, o Django precisa recarregar:

### Se estiver usando systemd:
```bash
sudo systemctl restart s-agendamento
```

### Se estiver rodando manualmente:
```bash
# Encontrar processo
ps aux | grep python | grep manage.py

# Matar (substitua PID)
kill PID

# Reiniciar
cd ~/s_agendamento
source .venv/bin/activate
python manage.py runserver 0.0.0.0:8000
```

---

## 🧪 Testar Novamente

Após corrigir, teste novamente:

```bash
python manage.py shell < test_asaas_server.py
```

**OU** digite no shell Python (um comando por vez):

```python
import os
from dotenv import load_dotenv
load_dotenv()
print("ASAAS_API_KEY_PRODUCTION:", '✅' if os.environ.get('ASAAS_API_KEY_PRODUCTION') else '❌')
```

---

## 📋 Checklist de Verificação

Execute no servidor:

```bash
cd ~/s_agendamento

# 1. Verificar se .env existe
ls -la .env

# 2. Ver conteúdo (linhas ASAAS)
cat .env | grep ASAAS

# 3. Verificar formato (sem espaços)
cat .env | grep "ASAAS_API_KEY_PRODUCTION" | cat -A
# Deve mostrar: ASAAS_API_KEY_PRODUCTION=$aact_...$
# Sem espaços antes ou depois do =

# 4. Verificar se está no diretório correto
pwd
ls -la manage.py .env
```

---

## 🎯 Comandos Rápidos para Corrigir

```bash
cd ~/s_agendamento

# Editar .env
nano .env

# Verificar após editar
cat .env | grep ASAAS

# Testar
python manage.py shell
```

No shell Python:
```python
import os
from dotenv import load_dotenv
load_dotenv()
print(os.environ.get('ASAAS_API_KEY_PRODUCTION') and '✅' or '❌')
```

---

## 💡 Se Ainda Não Funcionar

1. **Verificar se python-dotenv está instalado:**
   ```bash
   pip list | grep python-dotenv
   ```

2. **Se não estiver, instalar:**
   ```bash
   pip install python-dotenv
   ```

3. **Verificar se o Django está carregando o .env:**
   ```python
   # No shell Python
   from pathlib import Path
   print(Path('.env').exists())
   print(Path('.env').absolute())
   ```

---

**Dica:** O problema mais comum é ter espaços ao redor do `=` ou a chave não estar no arquivo `.env`!

