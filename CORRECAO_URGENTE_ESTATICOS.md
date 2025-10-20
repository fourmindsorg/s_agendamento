# 🚨 CORREÇÃO URGENTE - ARQUIVOS ESTÁTICOS 403 FORBIDDEN

## ❌ **Problema Confirmado:**
```
http://3.80.178.120/static/css/bootstrap.min.css
403 Forbidden
nginx/1.18.0 (Ubuntu)
```

## 🎯 **CORREÇÃO IMEDIATA - EXECUTE NA EC2:**

### **COMANDOS PARA EXECUTAR AGORA:**

```bash
# 1. Verificar estrutura atual
ls -la /home/ubuntu/s_agendamento/
ls -la /home/ubuntu/s_agendamento/static/
ls -la /home/ubuntu/s_agendamento/staticfiles/

# 2. Coletar arquivos estáticos
cd /home/ubuntu/s_agendamento
source .venv/bin/activate
python manage.py collectstatic --noinput --clear

# 3. Verificar se os arquivos foram coletados
ls -la /home/ubuntu/s_agendamento/staticfiles/
ls -la /home/ubuntu/s_agendamento/staticfiles/css/

# 4. Corrigir permissões COMPLETAMENTE
sudo chown -R ubuntu:www-data /home/ubuntu/s_agendamento/
sudo chmod -R 755 /home/ubuntu/s_agendamento/
sudo chmod -R 755 /home/ubuntu/s_agendamento/staticfiles/

# 5. Verificar se o nginx consegue acessar
sudo -u www-data ls -la /home/ubuntu/s_agendamento/staticfiles/css/

# 6. Atualizar configuração do Nginx
sudo tee /etc/nginx/sites-available/agendamento-4minds > /dev/null << 'EOF'
server {
    listen 80;
    server_name fourmindstech.com.br www.fourmindstech.com.br 3.80.178.120;

    location = /favicon.ico { 
        access_log off; 
        log_not_found off; 
        root /home/ubuntu/s_agendamento/staticfiles;
    }
    
    location /static/ {
        alias /home/ubuntu/s_agendamento/staticfiles/;
        expires 1y;
        add_header Cache-Control "public, immutable";
        add_header Access-Control-Allow-Origin "*";
        
        # Permitir acesso a todos os tipos de arquivo
        location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
    
    location /media/ {
        alias /home/ubuntu/s_agendamento/media/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    location / {
        include proxy_params;
        proxy_pass http://127.0.0.1:8000;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
EOF

# 7. Testar configuração
sudo nginx -t

# 8. Reiniciar Nginx
sudo systemctl restart nginx

# 9. Verificar status
sudo systemctl status nginx --no-pager

# 10. TESTAR ARQUIVOS ESTÁTICOS
curl -I http://3.80.178.120/static/css/bootstrap.min.css
curl -I http://3.80.178.120/static/js/bootstrap.min.js
curl -I http://3.80.178.120/static/css/style.css
```

### **SE AINDA NÃO FUNCIONAR:**

```bash
# Verificar logs do Nginx para erro específico
sudo tail -20 /var/log/nginx/error.log

# Verificar se o arquivo existe exatamente onde esperado
find /home/ubuntu/s_agendamento -name "bootstrap.min.css" -type f

# Verificar permissões específicas do arquivo
ls -la /home/ubuntu/s_agendamento/staticfiles/css/bootstrap.min.css

# Tentar acesso direto como usuário nginx
sudo -u www-data cat /home/ubuntu/s_agendamento/staticfiles/css/bootstrap.min.css | head -5
```

### **CORREÇÃO ALTERNATIVA:**

```bash
# Se ainda não funcionar, usar configuração mais permissiva
sudo tee /etc/nginx/sites-available/agendamento-4minds > /dev/null << 'EOF'
server {
    listen 80;
    server_name fourmindstech.com.br www.fourmindstech.com.br 3.80.178.120;

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
    }
    
    location /media/ {
        root /home/ubuntu/s_agendamento;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    location / {
        include proxy_params;
        proxy_pass http://127.0.0.1:8000;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
EOF

# Reiniciar Nginx
sudo systemctl restart nginx

# Testar
curl -I http://3.80.178.120/static/css/bootstrap.min.css
```

---

## 🔍 **VERIFICAÇÃO FINAL:**

```bash
# Verificar se funcionou
curl -I http://3.80.178.120/static/css/bootstrap.min.css

# Resultado esperado:
# HTTP/1.1 200 OK
# Content-Type: text/css
```

---

## 🎯 **EXECUTE AGORA:**

**Execute os comandos acima na EC2 para corrigir o problema dos arquivos estáticos!**

**O problema é de permissões e configuração do Nginx!** 🚀
