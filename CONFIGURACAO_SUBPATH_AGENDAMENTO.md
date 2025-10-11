# Configuração do Subpath /agendamento

## 📋 Resumo das Alterações

O sistema foi reconfigurado para ser acessado através do subpath `/agendamento` no domínio `fourmindstech.com.br`.

**URL de Acesso:** `http://fourmindstech.com.br/agendamento/`

---

## 🎯 Arquitetura da URL

### Antes (Domínio Raiz)
```
http://fourmindstech.com.br/
http://fourmindstech.com.br/admin/
http://fourmindstech.com.br/dashboard/
```

### Depois (Subpath /agendamento)
```
http://fourmindstech.com.br/agendamento/
http://fourmindstech.com.br/agendamento/admin/
http://fourmindstech.com.br/agendamento/dashboard/
```

### Redirecionamento Automático
- Acessar `http://fourmindstech.com.br/` → Redireciona para `/agendamento/`

---

## 🔧 Arquivos Modificados

### 1. Nginx (`nginx-django-fixed.conf`)

```nginx
server {
    listen 80;
    server_name fourmindstech.com.br www.fourmindstech.com.br;

    # Redirecionamento automático da raiz
    location = / {
        return 301 /agendamento/;
    }

    # Arquivos estáticos
    location /agendamento/static/ {
        alias /home/django/sistema-de-agendamento/staticfiles/;
    }

    # Arquivos de mídia
    location /agendamento/media/ {
        alias /home/django/sistema-de-agendamento/media/;
    }

    # Aplicação Django
    location /agendamento/ {
        proxy_pass http://127.0.0.1:8000/agendamento/;
        proxy_set_header X-Script-Name /agendamento;
        # ... outros headers
    }
}
```

### 2. Django Settings (`core/settings.py`)

```python
# Configuração para subpath /agendamento
FORCE_SCRIPT_NAME = '/agendamento'

STATIC_URL = '/agendamento/static/'
MEDIA_URL = '/agendamento/media/'

# URLs de redirecionamento
LOGIN_URL = '/agendamento/auth/login/'
LOGIN_REDIRECT_URL = '/agendamento/dashboard/'
LOGOUT_REDIRECT_URL = '/agendamento/auth/login/'
```

### 3. Django Settings Production (`core/settings_production.py`)

```python
# Configuração para subpath /agendamento (configurável via env)
FORCE_SCRIPT_NAME = os.environ.get("FORCE_SCRIPT_NAME", "/agendamento")

STATIC_URL = f"{FORCE_SCRIPT_NAME}/static/"
MEDIA_URL = f"{FORCE_SCRIPT_NAME}/media/"
```

### 4. Terraform User Data (`aws-infrastructure/user_data.sh`)

- ✅ Nginx configurado com subpath
- ✅ Django settings_production.py com FORCE_SCRIPT_NAME
- ✅ Health check endpoint: `/agendamento/health/`

### 5. Scripts de Deploy

Todos os scripts foram atualizados com as novas URLs:
- `deploy-manual.ps1`
- `deploy-scp.ps1`
- `diagnose-server.ps1`
- `fix-static-files.ps1`
- `fix-nginx-static.ps1`

---

## 📍 Endpoints Principais

| Endpoint | URL Completa |
|----------|--------------|
| Home | `http://fourmindstech.com.br/agendamento/` |
| Admin | `http://fourmindstech.com.br/agendamento/admin/` |
| Dashboard | `http://fourmindstech.com.br/agendamento/dashboard/` |
| Login | `http://fourmindstech.com.br/agendamento/auth/login/` |
| Static | `http://fourmindstech.com.br/agendamento/static/...` |
| Media | `http://fourmindstech.com.br/agendamento/media/...` |
| Health Check | `http://fourmindstech.com.br/agendamento/health/` |

---

## 🚀 Como Testar Localmente

### 1. Ativar Ambiente Virtual
```bash
cd /caminho/para/projeto
source venv/bin/activate  # Linux/Mac
# ou
venv\Scripts\activate  # Windows
```

### 2. Configurar Settings
```bash
# Usar settings com subpath configurado
export DJANGO_SETTINGS_MODULE=core.settings
```

### 3. Rodar Servidor de Desenvolvimento
```bash
python manage.py runserver
```

### 4. Acessar Aplicação
```
http://127.0.0.1:8000/agendamento/
http://127.0.0.1:8000/agendamento/admin/
```

---

## 🔧 Configuração em Produção

### Variáveis de Ambiente (.env.production)

```bash
# Subpath configuration
FORCE_SCRIPT_NAME=/agendamento

# Django Settings
DEBUG=False
SECRET_KEY=sua-chave-secreta
DJANGO_SETTINGS_MODULE=core.settings_production

# Database
DB_NAME=agendamentos_db
DB_USER=postgres
DB_PASSWORD=senha_segura
DB_HOST=rds-endpoint.amazonaws.com
DB_PORT=5432

# Hosts
ALLOWED_HOSTS=fourmindstech.com.br,www.fourmindstech.com.br
```

### Deploy com Nginx

1. **Copiar configuração do Nginx:**
```bash
sudo cp nginx-django-fixed.conf /etc/nginx/sites-available/django
sudo ln -sf /etc/nginx/sites-available/django /etc/nginx/sites-enabled/
```

2. **Testar configuração:**
```bash
sudo nginx -t
```

3. **Reiniciar Nginx:**
```bash
sudo systemctl restart nginx
```

4. **Iniciar Gunicorn:**
```bash
cd /home/django/sistema-de-agendamento
source venv/bin/activate
gunicorn --bind 127.0.0.1:8000 core.wsgi:application
```

---

## 🧪 Testes

### Teste 1: Redirecionamento da Raiz
```bash
curl -I http://fourmindstech.com.br/

# Deve retornar:
# HTTP/1.1 301 Moved Permanently
# Location: /agendamento/
```

### Teste 2: Aplicação Principal
```bash
curl -I http://fourmindstech.com.br/agendamento/

# Deve retornar:
# HTTP/1.1 200 OK
```

### Teste 3: Admin
```bash
curl -I http://fourmindstech.com.br/agendamento/admin/

# Deve retornar:
# HTTP/1.1 200 OK ou 302 (redirect para login)
```

### Teste 4: Arquivos Estáticos
```bash
curl -I http://fourmindstech.com.br/agendamento/static/admin/css/base.css

# Deve retornar:
# HTTP/1.1 200 OK
# Content-Type: text/css
```

### Teste 5: Health Check
```bash
curl http://fourmindstech.com.br/agendamento/health/

# Deve retornar:
# healthy
```

---

## 🔐 Segurança

### CSRF Protection
```python
CSRF_TRUSTED_ORIGINS = [
    "http://fourmindstech.com.br",
    "https://fourmindstech.com.br",
    "http://www.fourmindstech.com.br",
    "https://www.fourmindstech.com.br",
]
```

### Nginx Headers
```nginx
proxy_set_header Host $host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
proxy_set_header X-Script-Name /agendamento;  # IMPORTANTE!
```

---

## 📊 Vantagens do Subpath

### ✅ Benefícios

1. **Múltiplas Aplicações**
   - Permite hospedar outras aplicações no mesmo domínio
   - Ex: `fourmindstech.com.br/blog/`, `fourmindstech.com.br/loja/`

2. **Organização**
   - URLs mais organizadas e descritivas
   - Separação clara de funcionalidades

3. **SEO**
   - Melhor estruturação de URLs para motores de busca
   - Contexto claro do conteúdo

4. **Flexibilidade**
   - Fácil adicionar landing page na raiz
   - Redirecionamento automático configurado

### ⚠️ Considerações

1. **Cookies e Sessões**
   - Cookies são compartilhados no domínio inteiro
   - Configurar `SESSION_COOKIE_PATH = '/agendamento/'` se necessário

2. **Links Hardcoded**
   - Sempre usar `{% url %}` nos templates
   - Evitar links absolutos hardcoded

3. **JavaScript**
   - Verificar se há URLs hardcoded no JS
   - Usar configuração dinâmica de baseURL

---

## 🛠️ Troubleshooting

### Problema: CSS/JS não carrega
**Solução:**
1. Verificar STATIC_URL no settings: `/agendamento/static/`
2. Rodar `python manage.py collectstatic`
3. Verificar alias do Nginx: `/home/django/sistema-de-agendamento/staticfiles/`

### Problema: Redirecionamento infinito
**Solução:**
1. Verificar FORCE_SCRIPT_NAME no settings
2. Verificar proxy_set_header X-Script-Name no Nginx
3. Verificar LOGIN_URL e LOGOUT_URL

### Problema: URLs quebradas
**Solução:**
1. Usar sempre `{% url 'nome_da_view' %}` nos templates
2. Não usar URLs hardcoded
3. Verificar se todas as URLs começam com `/agendamento/`

### Problema: API externa não funciona
**Solução:**
1. Verificar CSRF_TRUSTED_ORIGINS
2. Adicionar domínio completo: `http://fourmindstech.com.br`
3. Verificar headers CORS se necessário

---

## 📝 Checklist de Verificação

Após deploy, verificar:

- [ ] Raiz `/` redireciona para `/agendamento/`
- [ ] Home `/agendamento/` carrega corretamente
- [ ] Admin `/agendamento/admin/` acessível
- [ ] CSS e JS carregam sem erros 404
- [ ] Login funciona e redireciona corretamente
- [ ] Logout funciona e redireciona corretamente
- [ ] Upload de arquivos funciona (media)
- [ ] Health check retorna "healthy"
- [ ] SSL funciona após configuração (HTTPS)
- [ ] Redirecionamento HTTP → HTTPS funciona

---

## 🔄 Rollback (Se Necessário)

Para voltar para configuração sem subpath:

1. **Nginx:**
   - Remover redirecionamento da raiz
   - Mudar `location /agendamento/` para `location /`
   - Ajustar paths de static e media

2. **Django:**
   - Remover `FORCE_SCRIPT_NAME`
   - Mudar `STATIC_URL` para `/static/`
   - Mudar `MEDIA_URL` para `/media/`
   - Ajustar LOGIN_URL, LOGOUT_URL, etc.

3. **Reiniciar serviços:**
```bash
sudo systemctl restart nginx
sudo systemctl restart django  # ou pkill gunicorn && gunicorn...
```

---

## 📞 Suporte

**Email:** fourmindsorg@gmail.com  
**Website:** http://fourmindstech.com.br/agendamento/

---

## 📅 Histórico

| Data | Versão | Alteração |
|------|--------|-----------|
| 11/10/2025 | 2.0 | Implementação do subpath /agendamento |
| 11/10/2025 | 1.0 | Configuração inicial domínio raiz |

---

**Status:** ✅ Configurado e testado  
**Última atualização:** 11 de Outubro de 2025

