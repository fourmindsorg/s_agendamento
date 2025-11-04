# 🔧 Resolver Conflito no Git Pull

## ⚠️ Problema

O git pull está bloqueado porque:
1. Arquivo modificado localmente: `staticfiles/css/style.css`
2. Arquivo não rastreado: `test_asaas_server.py`

---

## ✅ Solução Rápida

### Opção 1: Fazer Backup e Atualizar (Recomendado)

```bash
# 1. Fazer backup do arquivo modificado
cp staticfiles/css/style.css staticfiles/css/style.css.backup

# 2. Remover arquivo não rastreado (ou mover para outro lugar)
mv test_asaas_server.py test_asaas_server.py.local

# 3. Fazer stash das mudanças locais
git stash

# 4. Fazer pull
git pull origin main

# 5. Se precisar restaurar o arquivo CSS depois:
# cp staticfiles/css/style.css.backup staticfiles/css/style.css
```

### Opção 2: Descartar Mudanças Locais (Se não importarem)

```bash
# 1. Descartar mudanças no CSS
git checkout -- staticfiles/css/style.css

# 2. Remover arquivo não rastreado
rm test_asaas_server.py

# 3. Fazer pull
git pull origin main
```

### Opção 3: Commitar Mudanças Locais (Se forem importantes)

```bash
# 1. Adicionar arquivo não rastreado (se quiser manter)
git add test_asaas_server.py

# 2. Commitar mudanças locais
git add staticfiles/css/style.css
git commit -m "Mudanças locais no CSS"

# 3. Fazer pull (pode precisar resolver conflitos)
git pull origin main

# 4. Se houver conflitos, resolver e fazer commit
```

---

## 🎯 Solução Mais Simples (Recomendada)

Execute no servidor:

```bash
# Fazer stash das mudanças
git stash

# Remover arquivo não rastreado (já está no repositório)
rm test_asaas_server.py

# Fazer pull
git pull origin main

# Se precisar restaurar algo depois:
# git stash pop
```

---

## 📋 Verificar Depois

```bash
# Ver status
git status

# Ver últimas mudanças
git log --oneline -5

# Verificar se está atualizado
git log --oneline -1
# Deve mostrar: bcfa540 (ou mais recente)
```

---

**Dica:** O arquivo `test_asaas_server.py` já está no repositório, então pode ser removido localmente sem problemas!

