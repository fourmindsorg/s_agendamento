# 🔧 Alinhar Branches Local e Remota

## ⚠️ Situação Atual

A branch local está 2 commits à frente do remoto. O `staticfiles` está ignorado pelo `.gitignore` (correto).

---

## ✅ Solução 1: Verificar e Fazer Merge

```bash
# Ver commits locais que não estão no remoto
git log origin/main..HEAD --oneline

# Ver status
git status

# Tentar fazer merge novamente
git pull origin main --no-rebase
```

---

## ✅ Solução 2: Reset para Alinhar com Remoto (Se commits locais não importam)

**⚠️ CUIDADO:** Isso descarta commits locais!

```bash
# Ver o que será perdido
git log origin/main..HEAD --oneline

# Se não importar, resetar para o remoto
git reset --hard origin/main

# Verificar
git status
```

---

## ✅ Solução 3: Fazer Pull com Rebase (Mais Limpo)

```bash
# Fazer pull com rebase
git pull origin main --rebase

# Se houver conflitos, resolver e continuar
# git rebase --continue
```

---

## 🎯 Solução Recomendada

Execute no servidor:

```bash
# 1. Ver o que tem local
git log origin/main..HEAD --oneline

# 2. Se os commits locais não forem importantes (ex: apenas merge de conflito CSS):
git reset --hard origin/main

# 3. Verificar que está alinhado
git status
git log --oneline -3
```

---

## ✅ Depois de Alinhar

```bash
# Verificar que está atualizado
git log --oneline -1
# Deve mostrar: a385304

# Reiniciar gunicorn
sudo systemctl restart gunicorn
```

---

**Dica:** Se os commits locais forem apenas de resolução de conflitos CSS (que já está resolvido), pode fazer reset sem problemas.



