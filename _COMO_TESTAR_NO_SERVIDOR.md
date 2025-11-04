# 🧪 Como Testar Configuração Asaas no Servidor

## 🎯 Opção 1: Usar Script Simplificado (Recomendado)

### Passo 1: Criar o arquivo no servidor

No servidor, execute:

```bash
cd ~/s_agendamento
nano test_asaas_simples.py
```

### Passo 2: Copiar o conteúdo

Cole o conteúdo do arquivo `test_asaas_simples.py` (que está no repositório).

### Passo 3: Executar

```bash
python manage.py shell < test_asaas_simples.py
```

---

## 🎯 Opção 2: Testar Manualmente no Shell Python

### Abrir o shell:

```bash
python manage.py shell
```

### Digite estes comandos (SEM o >>>):

```python
import os
from dotenv import load_dotenv
load_dotenv()

print("ASAAS_ENV:", os.environ.get('ASAAS_ENV', 'NÃO ENCONTRADO'))
print("ASAAS_API_KEY_PRODUCTION:", '✅' if os.environ.get('ASAAS_API_KEY_PRODUCTION') else '❌')
print("ASAAS_API_KEY_SANDBOX:", '✅' if os.environ.get('ASAAS_API_KEY_SANDBOX') else '❌')
```

### Verificar com Django settings:

```python
from django.conf import settings
print("Settings ASAAS_ENV:", getattr(settings, 'ASAAS_ENV', 'NÃO CONFIGURADO'))
print("Settings ASAAS_API_KEY:", '✅ Configurada' if getattr(settings, 'ASAAS_API_KEY', None) else '❌ Não configurada')
print("Settings ASAAS_ENABLED:", getattr(settings, 'ASAAS_ENABLED', False))
```

### Testar cliente Asaas:

```python
from financeiro.services.asaas import AsaasClient
client = AsaasClient()
print("Base URL:", client.base)
print("Ambiente:", client.env)
```

---

## 🎯 Opção 3: Verificar .env Diretamente

```bash
# Ver conteúdo do .env (sem mostrar senhas completas)
cat .env | grep ASAAS

# Ver se está no lugar certo
ls -la .env

# Ver permissões
stat .env
```

---

## 🎯 Opção 4: Testar com Comando Único

```bash
python manage.py shell -c "
import os
from dotenv import load_dotenv
load_dotenv()
from django.conf import settings
print('ASAAS_ENV:', getattr(settings, 'ASAAS_ENV', 'NÃO CONFIGURADO'))
print('ASAAS_API_KEY:', '✅' if getattr(settings, 'ASAAS_API_KEY', None) else '❌')
"
```

---

## ✅ Resultado Esperado

Se tudo estiver correto, você deve ver:

```
ASAAS_ENV: production
ASAAS_API_KEY_PRODUCTION: ✅
Settings ASAAS_ENV: production
Settings ASAAS_API_KEY: ✅ Configurada
Settings ASAAS_ENABLED: True
Base URL: https://www.asaas.com/api/v3/
Ambiente: production
```

---

## 🚨 Problemas Comuns

### "python-dotenv não encontrado"

**Solução:**
```bash
source .venv/bin/activate
pip install python-dotenv
```

### ".env não encontrado"

**Solução:**
```bash
# Verificar se existe
ls -la .env

# Se não existir, criar
nano .env
# Adicionar as variáveis
```

### "Variáveis não aparecem"

**Solução:**
1. Verificar se o `.env` está no diretório correto (onde está o `manage.py`)
2. Verificar se não há espaços ao redor do `=` no `.env`
3. Reiniciar o Django (se estiver rodando)

---

## 📋 Checklist Rápido

- [ ] Ambiente virtual ativado (`source .venv/bin/activate`)
- [ ] Arquivo `.env` existe no diretório do projeto
- [ ] Variáveis configuradas no `.env` (sem espaços no `=`)
- [ ] `python-dotenv` instalado (`pip list | grep python-dotenv`)
- [ ] Teste executado com sucesso
- [ ] Ambiente mostra "production"
- [ ] API Key mostra "✅ Configurada"

---

**Dica:** Use a **Opção 2** (teste manual) para começar rápido!

