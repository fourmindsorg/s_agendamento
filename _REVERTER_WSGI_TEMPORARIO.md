# 🔄 Reverter wsgi.py Temporariamente

## ⚠️ Problema
Erro 500 após mudança para `settings_production`. Precisa reverter temporariamente.

## ✅ Solução Rápida

### 1. Sair do Shell Python
Se você estiver no shell Python (vejo que está), saia primeiro:
```python
>>> exit()
# OU pressione Ctrl+D
```

### 2. Editar Arquivo wsgi.py
```bash
nano core/wsgi.py
```

### 3. Alterar Linha 15
Encontrar a linha:
```python
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "core.settings_production")
```

Alterar para:
```python
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "core.settings")
```

### 4. Salvar e Sair
- Pressione `Ctrl+O` para salvar
- Pressione `Enter` para confirmar
- Pressione `Ctrl+X` para sair

### 5. Reiniciar Gunicorn
```bash
sudo systemctl restart gunicorn
# OU
sudo systemctl restart s-agendamento
```

### 6. Verificar Status
```bash
sudo systemctl status gunicorn
```

---

## 📝 Comandos Completos (Copiar e Colar)

```bash
# Sair do shell Python se estiver dentro (Ctrl+D ou digite exit())

# Editar arquivo
nano core/wsgi.py

# Alterar linha 15 de:
# os.environ.setdefault("DJANGO_SETTINGS_MODULE", "core.settings_production")
# Para:
# os.environ.setdefault("DJANGO_SETTINGS_MODULE", "core.settings")

# Salvar (Ctrl+O, Enter, Ctrl+X)

# Reiniciar
sudo systemctl restart gunicorn

# Verificar
curl -I http://localhost
# OU acessar o site no navegador
```

---

**Status:** ⚠️ Solução temporária - restaurar site rapidamente

