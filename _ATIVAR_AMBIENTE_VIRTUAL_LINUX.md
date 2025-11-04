# 🐍 Como Ativar Ambiente Virtual no Linux

## 🔍 Problema

Você tentou:
```bash
source .venv/scripts/activate  # ❌ Caminho do Windows
```

**No Linux, o caminho é diferente!**

---

## ✅ Solução: Caminho Correto

### No Linux (Ubuntu):
```bash
source .venv/bin/activate
```

**Diferença:**
- Windows: `.venv/scripts/activate`
- Linux: `.venv/bin/activate`

---

## 🔍 Passo 1: Encontrar o Ambiente Virtual

No servidor, execute:

```bash
# Verificar se existe .venv
ls -la ~/s_agendamento/.venv

# OU procurar por ambientes virtuais
find ~/s_agendamento -name "activate" -type f 2>/dev/null

# OU verificar outros nomes comuns
ls -la ~/s_agendamento/ | grep -E "(venv|env|virtualenv)"
```

---

## ✅ Opção 1: Se Existe .venv

```bash
cd ~/s_agendamento
source .venv/bin/activate

# Verificar se ativou (deve mostrar (.venv) no prompt)
# Exemplo: (venv) ubuntu@ip-10-0-1-9:~/s_agendamento$
```

---

## ✅ Opção 2: Se Existe venv (sem ponto)

```bash
cd ~/s_agendamento
source venv/bin/activate
```

---

## ✅ Opção 3: Se Existe env

```bash
cd ~/s_agendamento
source env/bin/activate
```

---

## ✅ Opção 4: Criar Novo Ambiente Virtual (se não existir)

```bash
cd ~/s_agendamento

# Criar ambiente virtual
python3 -m venv .venv

# Ativar
source .venv/bin/activate

# Instalar dependências
pip install -r requirements.txt
```

---

## ✅ Opção 5: Usar Python do Sistema (sem venv)

Se não houver ambiente virtual e o Django estiver instalado globalmente:

```bash
cd ~/s_agendamento

# Verificar se Django está instalado
python3 -c "import django; print(django.get_version())"

# Se funcionar, pode usar direto:
python3 manage.py shell
python3 manage.py runserver
```

---

## 🔍 Verificar se Está Ativado

Após ativar, você deve ver `(venv)` ou `(.venv)` no início do prompt:

```bash
# Antes: ubuntu@ip-10-0-1-9:~/s_agendamento$
# Depois: (.venv) ubuntu@ip-10-0-1-9:~/s_agendamento$
```

---

## 📋 Comandos Completos para Testar

```bash
# 1. Ir para o diretório
cd ~/s_agendamento

# 2. Tentar ativar ambiente virtual
source .venv/bin/activate

# 3. Se não funcionar, verificar se existe
ls -la .venv/bin/activate

# 4. Se não existir, criar novo
python3 -m venv .venv
source .venv/bin/activate

# 5. Instalar dependências
pip install -r requirements.txt

# 6. Testar Django
python manage.py --version
```

---

## 🎯 Testar Variáveis de Ambiente com Venv Ativado

```bash
# 1. Ativar ambiente virtual
cd ~/s_agendamento
source .venv/bin/activate

# 2. Verificar se python-dotenv está instalado
pip list | grep python-dotenv

# 3. Se não estiver, instalar
pip install python-dotenv

# 4. Testar variáveis
python manage.py shell
```

```python
# No shell Python:
>>> import os
>>> from dotenv import load_dotenv
>>> load_dotenv()
>>> print(os.environ.get('ASAAS_ENV'))
>>> print(os.environ.get('ASAAS_API_KEY_PRODUCTION')[:20] + '...')
```

---

## 🚨 Problemas Comuns

### "No such file or directory"
**Causa:** Ambiente virtual não existe ou caminho errado
**Solução:** Criar novo ou usar caminho correto (`bin/activate` no Linux)

### "Permission denied"
**Causa:** Permissões incorretas
**Solução:**
```bash
chmod +x .venv/bin/activate
```

### "Django not found" mesmo com venv ativado
**Causa:** Django não instalado no venv
**Solução:**
```bash
source .venv/bin/activate
pip install -r requirements.txt
```

---

## 📝 Checklist

- [ ] Encontrei o ambiente virtual (`.venv`, `venv`, ou `env`)
- [ ] Ativei com `source .venv/bin/activate` (Linux)
- [ ] Vejo `(venv)` no prompt
- [ ] Django está instalado (`pip list | grep Django`)
- [ ] `python-dotenv` está instalado
- [ ] Consigo testar variáveis no shell

---

**Dica:** No Linux, sempre use `bin/activate` ao invés de `scripts/activate`!

