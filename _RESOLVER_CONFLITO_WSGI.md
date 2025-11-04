# 🔧 Resolver Conflito no wsgi.py

## ❌ Problema
Git pull falha porque há mudanças locais no `core/wsgi.py`.

## ✅ Solução Rápida

### Opção 1: Descartar Mudanças Locais (Recomendado)
Se você editou o arquivo localmente mas quer usar a versão do repositório:

```bash
# Descartar mudanças locais
git checkout -- core/wsgi.py

# Agora fazer pull
git pull origin main

# Verificar se foi atualizado
cat core/wsgi.py | grep DJANGO_SETTINGS_MODULE
```

### Opção 2: Fazer Stash (Se quiser salvar as mudanças)
Se você quer salvar as mudanças locais para depois:

```bash
# Salvar mudanças locais
git stash

# Fazer pull
git pull origin main

# Ver mudanças salvas (se quiser recuperar depois)
git stash show
```

### Opção 3: Ver Diferenças Primeiro
Se quiser ver o que mudou antes de descartar:

```bash
# Ver diferenças
git diff core/wsgi.py

# Se quiser descartar, use:
git checkout -- core/wsgi.py

# Se quiser manter, faça commit:
git add core/wsgi.py
git commit -m "Mudanças locais no wsgi.py"
git pull origin main
```

---

## 🚀 Comandos Completos (Copiar e Colar)

```bash
# Descartar mudanças locais e fazer pull
git checkout -- core/wsgi.py
git pull origin main

# Verificar
cat core/wsgi.py | grep DJANGO_SETTINGS_MODULE

# Reiniciar gunicorn
sudo systemctl restart gunicorn
sudo systemctl status gunicorn
```

---

**Status:** ⚠️ Execute os comandos acima para resolver o conflito

