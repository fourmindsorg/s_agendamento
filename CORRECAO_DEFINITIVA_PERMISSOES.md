# 🔧 CORREÇÃO DEFINITIVA - PERMISSION DENIED

## ❌ **Problema Identificado nos Logs:**
```
open() "/home/ubuntu/s_agendamento/staticfiles/css/bootstrap.min.css" failed (13: Permission denied)
```

**Causa**: O usuário `www-data` (nginx) não tem permissão para acessar os arquivos estáticos.

## 🎯 **CORREÇÃO DEFINITIVA - EXECUTE NA EC2:**

### **COMANDOS PARA EXECUTAR AGORA:**

```bash
# 1. Verificar usuário atual do nginx
ps aux | grep nginx

# 2. Verificar permissões atuais
ls -la /home/ubuntu/s_agendamento/
ls -la /home/ubuntu/s_agendamento/staticfiles/

# 3. CORRIGIR PERMISSÕES COMPLETAMENTE
sudo chown -R ubuntu:www-data /home/ubuntu/s_agendamento/
sudo chmod -R 755 /home/ubuntu/s_agendamento/
sudo chmod -R 755 /home/ubuntu/s_agendamento/staticfiles/

# 4. Verificar se o usuário www-data consegue acessar
sudo -u www-data ls -la /home/ubuntu/s_agendamento/staticfiles/css/

# 5. Se ainda não conseguir, ajustar permissões do diretório pai
sudo chmod 755 /home/ubuntu/
sudo chmod 755 /home/ubuntu/s_agendamento/

# 6. Verificar novamente
sudo -u www-data ls -la /home/ubuntu/s_agendamento/staticfiles/css/

# 7. Testar acesso direto ao arquivo
sudo -u www-data cat /home/ubuntu/s_agendamento/staticfiles/css/bootstrap.min.css | head -5

# 8. Reiniciar Nginx
sudo systemctl restart nginx

# 9. Testar arquivos estáticos
curl -I http://3.80.178.120/static/css/bootstrap.min.css
```

### **SE AINDA NÃO FUNCIONAR:**

```bash
# Verificar se há problemas com SELinux ou AppArmor
sudo aa-status 2>/dev/null || echo "AppArmor não ativo"
sudo sestatus 2>/dev/null || echo "SELinux não ativo"

# Verificar se o diretório está montado corretamente
df -h /home/ubuntu/s_agendamento/

# Tentar configuração alternativa do Nginx
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
        
        # Permitir acesso a todos os tipos de arquivo
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

    location / {
        include proxy_params;
        proxy_pass http://127.0.0.1:8000;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
EOF

# Testar configuração
sudo nginx -t

# Reiniciar Nginx
sudo systemctl restart nginx

# Testar
curl -I http://3.80.178.120/static/css/bootstrap.min.css
```

### **VERIFICAÇÃO FINAL:**

```bash
# Verificar se funcionou
curl -I http://3.80.178.120/static/css/bootstrap.min.css

# Resultado esperado:
# HTTP/1.1 200 OK
# Content-Type: text/css

# Verificar logs para confirmar que não há mais erros
sudo tail -5 /var/log/nginx/error.log
```

---

## 🔍 **DIAGNÓSTICO ADICIONAL:**

### **Se ainda não funcionar:**

```bash
# Verificar se o arquivo existe e tem o conteúdo correto
ls -la /home/ubuntu/s_agendamento/staticfiles/css/bootstrap.min.css
file /home/ubuntu/s_agendamento/staticfiles/css/bootstrap.min.css

# Verificar se o arquivo não está vazio
wc -l /home/ubuntu/s_agendamento/staticfiles/css/bootstrap.min.css

# Verificar se o arquivo tem conteúdo válido
head -5 /home/ubuntu/s_agendamento/staticfiles/css/bootstrap.min.css
```

---

## 🎯 **EXECUTE AGORA:**

**Execute os comandos acima na EC2 para corrigir definitivamente o problema de permissões!**

**O problema é que o usuário www-data não consegue acessar os arquivos estáticos!** 🚀
