# 🚀 EXECUTAR CORREÇÃO 502 NA EC2

## ✅ **Você está conectado na EC2!**

Agora execute o script de correção:

### **OPÇÃO 1: Script Completo (RECOMENDADO)**
```bash
curl -s https://raw.githubusercontent.com/fourmindsorg/s_agendamento/main/corrigir_502_rapido.sh | bash
```

### **OPÇÃO 2: Comandos Individuais**
```bash
# 1. Navegar para o projeto
cd /home/ubuntu/s_agendamento

# 2. Ativar ambiente virtual
source .venv/bin/activate

# 3. Instalar dependências
pip install -r requirements.txt

# 4. Executar migrações
python manage.py migrate

# 5. Coletar arquivos estáticos
python manage.py collectstatic --noinput

# 6. Parar serviços existentes
sudo systemctl stop gunicorn
sudo systemctl stop nginx

# 7. Instalar Gunicorn
pip install gunicorn

# 8. Configurar Gunicorn
sudo tee /etc/systemd/system/gunicorn.service > /dev/null << 'EOF'
[Unit]
Description=Gunicorn daemon for Django
After=network.target

[Service]
User=ubuntu
Group=www-data
WorkingDirectory=/home/ubuntu/s_agendamento
ExecStart=/home/ubuntu/s_agendamento/.venv/bin/gunicorn --workers 3 --bind unix:/home/ubuntu/s_agendamento/gunicorn.sock core.wsgi:application
ExecReload=/bin/kill -s HUP $MAINPID
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# 9. Configurar Nginx
sudo tee /etc/nginx/sites-available/agendamento-4minds > /dev/null << 'EOF'
server {
    listen 80;
    server_name fourmindstech.com.br www.fourmindstech.com.br 3.80.178.120;

    location = /favicon.ico { access_log off; log_not_found off; }
    
    location /static/ {
        root /home/ubuntu/s_agendamento;
    }
    
    location /media/ {
        root /home/ubuntu/s_agendamento;
    }

    location / {
        include proxy_params;
        proxy_pass http://unix:/home/ubuntu/s_agendamento/gunicorn.sock;
    }
}
EOF

# 10. Ativar configurações
sudo ln -sf /etc/nginx/sites-available/agendamento-4minds /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# 11. Corrigir permissões
sudo chown -R ubuntu:www-data /home/ubuntu/s_agendamento
sudo chmod -R 755 /home/ubuntu/s_agendamento

# 12. Testar configuração do Nginx
sudo nginx -t

# 13. Iniciar serviços
sudo systemctl daemon-reload
sudo systemctl start gunicorn
sudo systemctl enable gunicorn
sudo systemctl restart nginx

# 14. Aguardar serviços iniciarem
sleep 10

# 15. Verificar status
sudo systemctl status gunicorn --no-pager
sudo systemctl status nginx --no-pager

# 16. Testar aplicação
curl -I http://localhost:8000/
curl -I http://3.80.178.120/
```

### **OPÇÃO 3: Correção Rápida**
```bash
# Parar tudo
sudo systemctl stop gunicorn
sudo systemctl stop nginx

# Navegar para projeto
cd /home/ubuntu/s_agendamento

# Ativar ambiente virtual
source .venv/bin/activate

# Instalar Gunicorn
pip install gunicorn

# Iniciar Gunicorn manualmente
gunicorn --bind 0.0.0.0:8000 core.wsgi:application &

# Testar
curl -I http://localhost:8000/
```

---

## 🔍 **VERIFICAÇÃO:**

Após executar qualquer opção:

```bash
# Verificar status
sudo systemctl status gunicorn
sudo systemctl status nginx

# Testar aplicação
curl -I http://3.80.178.120/

# Resultado esperado:
# HTTP/1.1 200 OK
```

---

## 🎯 **EXECUTE AGORA:**

**Recomendo a OPÇÃO 1 (Script Completo)** - é mais rápido e completo!

```bash
curl -s https://raw.githubusercontent.com/fourmindsorg/s_agendamento/main/corrigir_502_rapido.sh | bash
```

**Execute o comando acima na EC2!** 🚀
