# 🔧 Resolver Branches Divergentes

## ⚠️ Problema

As branches local e remota divergiram. Há commits locais que não estão no remoto.

---

## ✅ Solução Rápida

### Opção 1: Merge (Recomendado - Mais Seguro)

```bash
# Fazer merge das branches
git pull origin main --no-rebase

# Se houver conflitos, resolver e commitar
# Depois verificar
git status
```

### Opção 2: Rebase (Mais Limpo, mas Reescreve Histórico)

```bash
# Fazer rebase
git pull origin main --rebase

# Se houver conflitos, resolver e continuar
git rebase --continue
```

### Opção 3: Ver o Que Tem Local e Decidir

```bash
# Ver commits locais que não estão no remoto
git log origin/main..HEAD

# Ver diferenças
git diff origin/main

# Depois decidir: merge ou rebase
```

---

## 🎯 Solução Recomendada (Merge)

Execute no servidor:

```bash
# Ver o que tem local primeiro
git log --oneline -5

# Fazer merge
git pull origin main --no-rebase

# Se pedir mensagem de commit, aceitar a padrão ou escrever uma
# (geralmente: "Merge branch 'main' of ... into main")

# Verificar status
git status
```

---

## 🚨 Se Houver Conflitos

```bash
# Ver arquivos em conflito
git status

# Resolver conflitos manualmente
# OU usar estratégia:
git checkout --theirs arquivo_em_conflito  # usar versão remota
# OU
git checkout --ours arquivo_em_conflito    # usar versão local

# Depois adicionar e continuar
git add arquivo_em_conflito
git commit -m "Resolver conflito"
```

---

## ✅ Depois de Resolver

```bash
# Verificar que está tudo ok
git status

# Verificar último commit
git log --oneline -3

# Reiniciar gunicorn
sudo systemctl restart gunicorn
```

---

**Dica:** Use `--no-rebase` para manter o histórico completo, ou `--rebase` para um histórico mais limpo.



