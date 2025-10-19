# 🔧 CORRIGIR CONFIGURAÇÃO NGINX PARA SOCKET

## ✅ **Diagnóstico:**
- ✅ Socket existe: `/home/ubuntu/s_agendamento/gunicorn.sock`
- ✅ Gunicorn está rodando com workers
- ❌ Nginx não consegue conectar no socket

## 🎯 **SOLUÇÃO:**

### **EXECUTE ESTES COMANDOS NA EC2:**

```bash
# 1. Verificar configuração atual do Nginx
cat /etc/nginx/sites-available/agendamento-4minds

# 2. Verificar se proxy_params existe
ls -la /etc/nginx/proxy_params

# 3. Criar proxy_params se não existir
sudo tee /etc/nginx/proxy_params > /dev/null << 'EOF'
proxy_set_header Host $http_host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
proxy_redirect off;
proxy_buffering off;
EOF

# 4. Atualizar configuração do Nginx
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
        proxy_pass http://unix:/home/ubuntu/s_agendamento/gunicorn.sock;
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

# 8. Testar aplicação
curl -I http://localhost:8000/
curl -I http://3.80.178.120/
```

### **SE AINDA NÃO FUNCIONAR, EXECUTE:**

```bash
# Correção alternativa - usar TCP em vez de socket
sudo systemctl stop gunicorn

# Configurar Gunicorn para usar TCP
sudo tee /etc/systemd/system/gunicorn.service > /dev/null << 'EOF'
[Unit]
Description=Gunicorn daemon for Django
After=network.target

[Service]
User=ubuntu
Group=www-data
WorkingDirectory=/home/ubuntu/s_agendamento
Environment=PATH=/home/ubuntu/s_agendamento/.venv/bin
ExecStart=/home/ubuntu/s_agendamento/.venv/bin/gunicorn --workers 3 --bind 127.0.0.1:8000 core.wsgi:application
ExecReload=/bin/kill -s HUP $MAINPID
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Atualizar configuração do Nginx para TCP
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

# Testar configuração
sudo nginx -t

# Reiniciar serviços
sudo systemctl daemon-reload
sudo systemctl start gunicorn
sudo systemctl enable gunicorn
sudo systemctl restart nginx

# Aguardar
sleep 10

# Verificar status
sudo systemctl status gunicorn --no-pager
sudo systemctl status nginx --no-pager

# Testar aplicação
curl -I http://localhost:8000/
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

**Execute os comandos de correção do Nginx primeiro!**

**Se não funcionar, execute a correção alternativa com TCP!** 🚀
