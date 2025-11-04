# 🔧 Resolver Conflito no CSS

## ⚠️ Problema

Há um conflito de merge no arquivo `staticfiles/css/style.css` (arquivo gerado automaticamente).

---

## ✅ Solução Rápida

### Opção 1: Usar Versão do Repositório (Recomendado)

```bash
# Usar versão do repositório (descartar mudanças locais)
git checkout --theirs staticfiles/css/style.css

# Marcar como resolvido
git add staticfiles/css/style.css

# Finalizar merge
git commit -m "Resolver conflito: usar versão do repositório para style.css"
```

### Opção 2: Regenerar Staticfiles (Melhor para Produção)

```bash
# Descartar conflito
git checkout --theirs staticfiles/css/style.css
git add staticfiles/css/style.css

# Regenerar staticfiles
python manage.py collectstatic --noinput

# Finalizar merge
git commit -m "Resolver conflito e regenerar staticfiles"
```

### Opção 3: Usar Versão Local (Se tiver mudanças importantes)

```bash
# Usar versão local
git checkout --ours staticfiles/css/style.css

# Marcar como resolvido
git add staticfiles/css/style.css

# Finalizar merge
git commit -m "Resolver conflito: manter versão local do style.css"
```

---

## 🎯 Solução Recomendada (Regenerar)

Execute no servidor:

```bash
# 1. Usar versão do repositório
git checkout --theirs staticfiles/css/style.css
git add staticfiles/css/style.css

# 2. Regenerar staticfiles (se necessário)
python manage.py collectstatic --noinput

# 3. Finalizar merge
git commit -m "Resolver conflito CSS - regenerar staticfiles"

# 4. Verificar status
git status
```

---

## 📋 Depois de Resolver

```bash
# Verificar se está tudo ok
git status

# Verificar último commit
git log --oneline -1

# Reiniciar gunicorn
sudo systemctl restart gunicorn
```

---

**Nota:** Como `staticfiles` geralmente contém arquivos gerados automaticamente, é seguro usar a versão do repositório e regenerar depois.



