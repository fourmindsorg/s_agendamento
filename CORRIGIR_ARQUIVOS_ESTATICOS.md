# 🔧 CORRIGIR ARQUIVOS ESTÁTICOS (CSS, BOOTSTRAP)

## ❌ **Problema Identificado:**
```
curl -I http://3.80.178.120/static/css/bootstrap.min.css
HTTP/1.1 403 Forbidden
```

**Causa**: Arquivos estáticos não estão sendo servidos corretamente pelo Nginx.

## 🎯 **SOLUÇÃO:**

### **EXECUTE ESTES COMANDOS NA EC2:**

```bash
# 1. Verificar se os arquivos estáticos existem
ls -la /home/ubuntu/s_agendamento/static/
ls -la /home/ubuntu/s_agendamento/staticfiles/

# 2. Verificar permissões dos arquivos estáticos
sudo chown -R ubuntu:www-data /home/ubuntu/s_agendamento/static/
sudo chown -R ubuntu:www-data /home/ubuntu/s_agendamento/staticfiles/
sudo chmod -R 755 /home/ubuntu/s_agendamento/static/
sudo chmod -R 755 /home/ubuntu/s_agendamento/staticfiles/

# 3. Verificar configuração atual do Nginx
cat /etc/nginx/sites-available/agendamento-4minds

# 4. Atualizar configuração do Nginx para arquivos estáticos
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

# 5. Testar configuração do Nginx
sudo nginx -t

# 6. Reiniciar Nginx
sudo systemctl restart nginx

# 7. Verificar status
sudo systemctl status nginx --no-pager

# 8. Testar arquivos estáticos
curl -I http://3.80.178.120/static/css/bootstrap.min.css
curl -I http://3.80.178.120/static/js/bootstrap.min.js
```

### **SE AINDA NÃO FUNCIONAR:**

```bash
# Verificar se o diretório staticfiles existe
ls -la /home/ubuntu/s_agendamento/staticfiles/

# Se não existir, coletar arquivos estáticos
cd /home/ubuntu/s_agendamento
source .venv/bin/activate
python manage.py collectstatic --noinput

# Verificar se os arquivos foram coletados
ls -la /home/ubuntu/s_agendamento/staticfiles/

# Corrigir permissões novamente
sudo chown -R ubuntu:www-data /home/ubuntu/s_agendamento/staticfiles/
sudo chmod -R 755 /home/ubuntu/s_agendamento/staticfiles/

# Reiniciar Nginx
sudo systemctl restart nginx

# Testar
curl -I http://3.80.178.120/static/css/bootstrap.min.css
```

### **VERIFICAÇÃO FINAL:**

```bash
# Verificar se os arquivos estáticos estão acessíveis
curl -I http://3.80.178.120/static/css/bootstrap.min.css
curl -I http://3.80.178.120/static/js/bootstrap.min.js
curl -I http://3.80.178.120/static/css/style.css

# Resultado esperado:
# HTTP/1.1 200 OK
# Content-Type: text/css
```

---

## 🔍 **DIAGNÓSTICO ADICIONAL:**

### **1. Verificar Estrutura de Arquivos**
```bash
# Verificar estrutura do projeto
find /home/ubuntu/s_agendamento -name "*.css" -type f
find /home/ubuntu/s_agendamento -name "*.js" -type f
```

### **2. Verificar Configuração Django**
```bash
# Verificar settings.py
cd /home/ubuntu/s_agendamento
source .venv/bin/activate
python manage.py shell -c "from django.conf import settings; print('STATIC_URL:', settings.STATIC_URL); print('STATIC_ROOT:', settings.STATIC_ROOT)"
```

### **3. Verificar Logs do Nginx**
```bash
# Verificar logs de erro
sudo tail -f /var/log/nginx/error.log
```

---

## 🚨 **TROUBLESHOOTING:**

### **Problema: Ainda 403 Forbidden**
```bash
# Verificar se o usuário nginx tem acesso
sudo -u www-data ls -la /home/ubuntu/s_agendamento/staticfiles/

# Se não tiver acesso, ajustar permissões
sudo chmod 755 /home/ubuntu/s_agendamento/
sudo chmod 755 /home/ubuntu/s_agendamento/staticfiles/
```

### **Problema: Arquivos não encontrados**
```bash
# Verificar se os arquivos foram coletados corretamente
cd /home/ubuntu/s_agendamento
source .venv/bin/activate
python manage.py collectstatic --noinput --verbosity=2
```

### **Problema: CSS não carrega no navegador**
- Verifique o console do navegador (F12)
- Verifique se há erros de CORS
- Confirme se o caminho está correto

---

## 🎯 **RESULTADO ESPERADO:**

Após correção:
- ✅ **Arquivos estáticos**: http://3.80.178.120/static/css/bootstrap.min.css → 200 OK
- ✅ **CSS funcionando**: Páginas com estilo correto
- ✅ **Bootstrap funcionando**: Componentes visuais corretos
- ✅ **JavaScript funcionando**: Interações funcionando

---

## 📋 **RESUMO:**

1. **Verificar** se os arquivos estáticos existem
2. **Corrigir** permissões dos arquivos
3. **Atualizar** configuração do Nginx
4. **Coletar** arquivos estáticos se necessário
5. **Testar** acesso aos arquivos

**Execute os comandos de correção e os arquivos estáticos funcionarão!** 🚀
