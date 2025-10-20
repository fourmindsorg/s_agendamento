# 🔧 CORRIGIR ERRO 500 - URL /s_agendamentos/

## ✅ **Status Atual:**
- ✅ **HTTPS funcionando**: https://fourmindstech.com.br/ → Redireciona para /s_agendamentos/
- ❌ **Erro 500**: https://fourmindstech.com.br/s_agendamentos/ → HTTP/2 500

**Causa**: A URL `/s_agendamentos/` não existe no Django ou há erro na aplicação.

## 🎯 **SOLUÇÃO:**

### **EXECUTE ESTES COMANDOS NA EC2:**

```bash
# 1. Verificar URLs atuais do Django
cd /home/ubuntu/s_agendamento
source .venv/bin/activate
python manage.py show_urls 2>/dev/null || echo "Comando show_urls não disponível"

# 2. Verificar se o app agendamentos tem URLs
ls -la /home/ubuntu/s_agendamento/agendamentos/urls.py

# 3. Verificar conteúdo do urls.py do app agendamentos
cat /home/ubuntu/s_agendamento/agendamentos/urls.py

# 4. Verificar se o app agendamentos está no INSTALLED_APPS
python manage.py shell -c "from django.conf import settings; print('INSTALLED_APPS:', [app for app in settings.INSTALLED_APPS if 'agendamento' in app])"

# 5. Verificar logs do Django para erro específico
sudo journalctl -u gunicorn --no-pager -n 20

# 6. Testar URL raiz do Django
curl -I https://fourmindstech.com.br/admin/

# 7. Verificar se há erros no Django
python manage.py check
```

### **SE O APP AGENDAMENTOS NÃO EXISTIR:**

```bash
# 1. Verificar apps disponíveis
ls -la /home/ubuntu/s_agendamento/
ls -la /home/ubuntu/s_agendamento/*/urls.py

# 2. Atualizar URLs para usar app correto
sudo tee /home/ubuntu/s_agendamento/core/urls.py > /dev/null << 'EOF'
from django.contrib import admin
from django.urls import path, include
from django.shortcuts import redirect

def redirect_to_agendamentos(request):
    return redirect('/admin/')

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', redirect_to_agendamentos),
]
EOF

# 3. Reiniciar Gunicorn
sudo systemctl restart gunicorn

# 4. Testar
curl -I https://fourmindstech.com.br/
curl -I https://fourmindstech.com.br/admin/
```

### **SE O APP AGENDAMENTOS EXISTIR MAS TIVER ERRO:**

```bash
# 1. Verificar se há erros de importação
python manage.py shell -c "import agendamentos.urls"

# 2. Verificar se há erros de views
python manage.py shell -c "from agendamentos import views"

# 3. Verificar se há erros de models
python manage.py shell -c "from agendamentos import models"

# 4. Executar migrações se necessário
python manage.py migrate

# 5. Verificar se há erros de configuração
python manage.py check --deploy
```

### **CORREÇÃO ALTERNATIVA - USAR URL RAIZ:**

```bash
# 1. Atualizar URLs para usar URL raiz
sudo tee /home/ubuntu/s_agendamento/core/urls.py > /dev/null << 'EOF'
from django.contrib import admin
from django.urls import path, include
from django.shortcuts import redirect

def redirect_to_admin(request):
    return redirect('/admin/')

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', redirect_to_admin),
]
EOF

# 2. Atualizar configuração do Nginx
sudo tee /etc/nginx/sites-available/agendamento-4minds > /dev/null << 'EOF'
# Redirecionar HTTP para HTTPS
server {
    listen 80;
    server_name fourmindstech.com.br www.fourmindstech.com.br 3.80.178.120;
    return 301 https://$server_name$request_uri;
}

# Configuração HTTPS
server {
    listen 443 ssl http2;
    server_name fourmindstech.com.br www.fourmindstech.com.br 3.80.178.120;

    # Certificados SSL
    ssl_certificate /etc/letsencrypt/live/fourmindstech.com.br/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/fourmindstech.com.br/privkey.pem;
    
    # Configurações SSL
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Arquivos estáticos
    location = /favicon.ico { 
        access_log off; 
        log_not_found off; 
        root /home/ubuntu/s_agendamento/staticfiles;
    }
    
    location /static/ {
        root /home/ubuntu/s_agendamento;
        expires 1y;
        add_header Cache-Control "public, immutable";
        add_header Access-Control-Allow-Origin "*";
        
        location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
    
    location /media/ {
        root /home/ubuntu/s_agendamento;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Aplicação Django
    location / {
        include proxy_params;
        proxy_pass http://127.0.0.1:8000;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # Headers para HTTPS
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Host $server_name;
    }
}
EOF

# 3. Testar configuração
sudo nginx -t

# 4. Reiniciar serviços
sudo systemctl restart nginx
sudo systemctl restart gunicorn

# 5. Testar
curl -I https://fourmindstech.com.br/
curl -I https://fourmindstech.com.br/admin/
```

---

## 🔍 **VERIFICAÇÃO:**

### **1. Testar URLs**
```bash
# Testar URL raiz
curl -I https://fourmindstech.com.br/

# Testar admin
curl -I https://fourmindstech.com.br/admin/

# Resultado esperado:
# HTTP/2 200 OK
```

### **2. Verificar Logs**
```bash
# Verificar logs do Gunicorn
sudo journalctl -u gunicorn --no-pager -n 10

# Verificar logs do Nginx
sudo tail -5 /var/log/nginx/error.log
```

---

## 🎯 **RESULTADO ESPERADO:**

Após correção:
- ✅ **HTTPS**: https://fourmindstech.com.br/ → Funciona (200 OK)
- ✅ **Admin**: https://fourmindstech.com.br/admin/ → Funciona (200 OK)
- ✅ **SSL**: Certificado válido e seguro
- ✅ **Redirecionamento**: HTTP → HTTPS funcionando

---

## 📋 **RESUMO:**

1. **Diagnosticar** o erro 500 na URL /s_agendamentos/
2. **Verificar** se o app agendamentos existe e funciona
3. **Corrigir** URLs ou usar URL raiz
4. **Testar** todas as URLs

**Execute os comandos de diagnóstico primeiro para identificar o problema!** 🚀
