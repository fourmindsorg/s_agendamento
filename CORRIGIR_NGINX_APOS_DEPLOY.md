# 🔧 CORRIGIR NGINX APÓS DEPLOY GITHUB ACTIONS

## ❌ **Problema:**
- ✅ Gunicorn funcionando: `http://localhost:8000/` → 200 OK
- ❌ Nginx com erro 502: `http://3.80.178.120/` → 502 Bad Gateway

**Causa**: Nginx foi reconfigurado incorretamente durante o deploy do GitHub Actions.

## 🎯 **SOLUÇÃO:**

### **EXECUTE ESTES COMANDOS NA EC2:**

```bash
# 1. Verificar configuração atual do Nginx
cat /etc/nginx/sites-available/agendamento-4minds

# 2. Verificar se está usando socket ou TCP
sudo systemctl status gunicorn --no-pager

# 3. Corrigir configuração do Nginx para TCP (já que Gunicorn está na porta 8000)
sudo tee /etc/nginx/sites-available/agendamento-4minds > /dev/null << 'EOF'
server {
    listen 80;
    server_name fourmindstech.com.br www.fourmindstech.com.br 3.80.178.120;

    location = /favicon.ico { access_log off; log_not_found off; }
    
    location /static/ {
        root /home/ubuntu/s_agendamento;
        expires 1y;
        add_header Cache-Control "public, immutable";
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

# 4. Testar configuração do Nginx
sudo nginx -t

# 5. Reiniciar Nginx
sudo systemctl restart nginx

# 6. Verificar status
sudo systemctl status nginx --no-pager

# 7. Testar aplicação
curl -I http://localhost:8000/
curl -I http://3.80.178.120/
```

### **SE AINDA NÃO FUNCIONAR:**

```bash
# Verificar se proxy_params existe
ls -la /etc/nginx/proxy_params

# Criar proxy_params se não existir
sudo tee /etc/nginx/proxy_params > /dev/null << 'EOF'
proxy_set_header Host $http_host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
proxy_redirect off;
proxy_buffering off;
EOF

# Reiniciar Nginx novamente
sudo systemctl restart nginx

# Testar
curl -I http://3.80.178.120/
```

### **VERIFICAÇÃO FINAL:**

```bash
# Verificar se os serviços estão rodando
sudo systemctl is-active gunicorn
sudo systemctl is-active nginx

# Verificar processos
ps aux | grep gunicorn
ps aux | grep nginx

# Testar aplicação
curl -I http://3.80.178.120/

# Resultado esperado:
# HTTP/1.1 200 OK
```

---

## 🎯 **EXECUTE AGORA:**

**Execute os comandos de correção do Nginx!**

**O problema é que o Nginx está tentando conectar no socket, mas o Gunicorn está rodando na porta 8000!** 🚀
