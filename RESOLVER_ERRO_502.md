# 🔧 RESOLVER ERRO 502 BAD GATEWAY

## ❌ **Problema Identificado:**
```
curl: (22) The requested URL returned error: 502
Error: Process completed with exit code 1.
```

**Causa**: Nginx está rodando mas Gunicorn (Django) não está funcionando.

---

## 🎯 **SOLUÇÃO IMEDIATA:**

### **PASSO 1: Acessar Console EC2**
1. Acesse: https://console.aws.amazon.com/ec2/
2. Vá para **Instances** → `i-029805f836fb2f238`
3. Clique em **Connect** → **EC2 Instance Connect**

### **PASSO 2: Executar Script de Correção**
```bash
curl -s https://raw.githubusercontent.com/fourmindsorg/s_agendamento/main/configurar_tudo_completo.sh | bash
```

### **PASSO 3: Ou Executar Comandos Individuais**
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

---

## 🔍 **VERIFICAÇÃO:**

### **1. Verificar Status dos Serviços**
```bash
# Status do Gunicorn
sudo systemctl status gunicorn

# Status do Nginx
sudo systemctl status nginx

# Processos rodando
ps aux | grep gunicorn
ps aux | grep nginx
```

### **2. Verificar Logs**
```bash
# Logs do Gunicorn
sudo journalctl -u gunicorn -f

# Logs do Nginx
sudo journalctl -u nginx -f

# Logs da aplicação
tail -f /home/ubuntu/s_agendamento/logs/django.log
```

### **3. Testar Aplicação**
```bash
# Teste local
curl -I http://localhost:8000/

# Teste externo
curl -I http://3.80.178.120/

# Teste com timeout
timeout 10 curl -I http://3.80.178.120/
```

---

## 🚨 **TROUBLESHOOTING:**

### **Problema: Gunicorn não inicia**
```bash
# Verificar se o arquivo .env existe
ls -la /home/ubuntu/s_agendamento/.env

# Verificar se o ambiente virtual está ativo
which python
which pip

# Verificar se as dependências estão instaladas
pip list | grep django
pip list | grep gunicorn
```

### **Problema: Nginx não conecta com Gunicorn**
```bash
# Verificar se o socket existe
ls -la /home/ubuntu/s_agendamento/gunicorn.sock

# Verificar permissões do socket
sudo chmod 664 /home/ubuntu/s_agendamento/gunicorn.sock
sudo chown ubuntu:www-data /home/ubuntu/s_agendamento/gunicorn.sock
```

### **Problema: Aplicação não responde**
```bash
# Testar Django diretamente
cd /home/ubuntu/s_agendamento
source .venv/bin/activate
python manage.py runserver 0.0.0.0:8000
```

---

## ✅ **RESULTADO ESPERADO:**

Após executar a correção:
```bash
$ curl -I http://3.80.178.120/
HTTP/1.1 200 OK
Server: nginx/1.18.0 (Ubuntu)
Date: Sun, 19 Oct 2025 23:03:19 GMT
Content-Type: text/html; charset=utf-8
```

---

## 🎯 **RESUMO:**

1. **Acesse Console EC2**
2. **Execute o script** de correção
3. **Verifique os serviços** (Gunicorn e Nginx)
4. **Teste a aplicação**
5. **Re-execute GitHub Actions**

**Execute o script na EC2 para resolver o erro 502!** 🚀
