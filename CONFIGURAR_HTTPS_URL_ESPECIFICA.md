# 🔒 CONFIGURAR HTTPS E URL ESPECÍFICA

## ❌ **Problema Identificado:**
- ❌ **Atual**: http://fourmindstech.com.br (HTTP sem SSL)
- ✅ **Deveria ser**: https://fourmindstech.com.br/s_agendamentos (HTTPS com SSL)

## 🎯 **SOLUÇÃO COMPLETA:**

### **PASSO 1: Configurar SSL/HTTPS**

#### **EXECUTE ESTES COMANDOS NA EC2:**

```bash
# 1. Instalar Certbot para SSL
sudo apt update
sudo apt install certbot python3-certbot-nginx -y

# 2. Obter certificado SSL
sudo certbot --nginx -d fourmindstech.com.br -d www.fourmindstech.com.br

# 3. Verificar se o certificado foi criado
sudo certbot certificates

# 4. Testar renovação automática
sudo certbot renew --dry-run
```

### **PASSO 2: Configurar URL Específica**

#### **Atualizar Configuração do Nginx:**

```bash
# 1. Atualizar configuração do Nginx para HTTPS e URL específica
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

    # Certificados SSL (serão configurados pelo Certbot)
    ssl_certificate /etc/letsencrypt/live/fourmindstech.com.br/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/fourmindstech.com.br/privkey.pem;
    
    # Configurações SSL
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Redirecionar para URL específica
    location = / {
        return 301 https://fourmindstech.com.br/s_agendamentos/;
    }

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

# 2. Testar configuração
sudo nginx -t

# 3. Reiniciar Nginx
sudo systemctl restart nginx

# 4. Verificar status
sudo systemctl status nginx --no-pager
```

### **PASSO 3: Configurar Django para HTTPS**

#### **Atualizar Settings do Django:**

```bash
# 1. Atualizar arquivo .env
cd /home/ubuntu/s_agendamento
cat >> .env << 'EOF'

# HTTPS Configuration
SECURE_SSL_REDIRECT=True
SECURE_PROXY_SSL_HEADER=('HTTP_X_FORWARDED_PROTO', 'https')
SECURE_HSTS_SECONDS=31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS=True
SECURE_HSTS_PRELOAD=True
SECURE_CONTENT_TYPE_NOSNIFF=True
SECURE_BROWSER_XSS_FILTER=True
X_FRAME_OPTIONS=DENY
EOF

# 2. Atualizar settings.py para HTTPS
sudo tee -a /home/ubuntu/s_agendamento/core/settings.py > /dev/null << 'EOF'

# HTTPS Settings
SECURE_SSL_REDIRECT = True
SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
SECURE_HSTS_SECONDS = 31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True
SECURE_CONTENT_TYPE_NOSNIFF = True
SECURE_BROWSER_XSS_FILTER = True
X_FRAME_OPTIONS = 'DENY'
EOF

# 3. Reiniciar Gunicorn
sudo systemctl restart gunicorn
```

### **PASSO 4: Configurar URL Específica no Django**

#### **Atualizar URLs:**

```bash
# 1. Verificar URLs atuais
cat /home/ubuntu/s_agendamento/core/urls.py

# 2. Atualizar URLs para incluir s_agendamentos
sudo tee /home/ubuntu/s_agendamento/core/urls.py > /dev/null << 'EOF'
from django.contrib import admin
from django.urls import path, include
from django.shortcuts import redirect

def redirect_to_agendamentos(request):
    return redirect('/s_agendamentos/')

urlpatterns = [
    path('admin/', admin.site.urls),
    path('s_agendamentos/', include('agendamentos.urls')),
    path('', redirect_to_agendamentos),
]
EOF

# 3. Reiniciar Gunicorn
sudo systemctl restart gunicorn
```

---

## 🔍 **VERIFICAÇÃO:**

### **1. Testar HTTPS**
```bash
# Testar HTTPS
curl -I https://fourmindstech.com.br/
curl -I https://fourmindstech.com.br/s_agendamentos/

# Resultado esperado:
# HTTP/2 200 OK
# Server: nginx/1.18.0 (Ubuntu)
```

### **2. Testar Redirecionamento**
```bash
# Testar redirecionamento HTTP para HTTPS
curl -I http://fourmindstech.com.br/

# Resultado esperado:
# HTTP/1.1 301 Moved Permanently
# Location: https://fourmindstech.com.br/
```

### **3. Testar URL Específica**
```bash
# Testar URL específica
curl -I https://fourmindstech.com.br/s_agendamentos/

# Resultado esperado:
# HTTP/2 200 OK
```

---

## 🚨 **TROUBLESHOOTING:**

### **Problema: Certificado SSL não funciona**
```bash
# Verificar se o domínio está apontando para o IP correto
nslookup fourmindstech.com.br

# Verificar se o Nginx está configurado corretamente
sudo nginx -t

# Verificar logs do Certbot
sudo tail -f /var/log/letsencrypt/letsencrypt.log
```

### **Problema: Redirecionamento não funciona**
```bash
# Verificar se o Django está configurado para HTTPS
cd /home/ubuntu/s_agendamento
source .venv/bin/activate
python manage.py shell -c "from django.conf import settings; print('SECURE_SSL_REDIRECT:', settings.SECURE_SSL_REDIRECT)"
```

---

## 🎯 **RESULTADO FINAL:**

Após configuração:
- ✅ **HTTPS**: https://fourmindstech.com.br → Redireciona para /s_agendamentos/
- ✅ **URL Específica**: https://fourmindstech.com.br/s_agendamentos/ → Aplicação Django
- ✅ **Redirecionamento**: http://fourmindstech.com.br → https://fourmindstech.com.br
- ✅ **SSL**: Certificado válido e seguro

---

## 📋 **RESUMO:**

1. **Configurar SSL** com Certbot
2. **Atualizar Nginx** para HTTPS e redirecionamento
3. **Configurar Django** para HTTPS
4. **Configurar URL** específica /s_agendamentos/
5. **Testar** todas as URLs

**Execute os comandos acima para configurar HTTPS e URL específica!** 🚀
