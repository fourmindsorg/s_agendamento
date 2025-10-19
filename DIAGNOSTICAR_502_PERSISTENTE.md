# 🔍 DIAGNOSTICAR PROBLEMA 502 PERSISTENTE

## ✅ **Script Executado com Sucesso!**

O script rodou, mas ainda temos erro 502. Vamos diagnosticar:

### **EXECUTE ESTES COMANDOS NA EC2:**

```bash
# 1. Verificar se o socket do Gunicorn existe
ls -la /home/ubuntu/s_agendamento/gunicorn.sock

# 2. Verificar permissões do socket
sudo chmod 664 /home/ubuntu/s_agendamento/gunicorn.sock
sudo chown ubuntu:www-data /home/ubuntu/s_agendamento/gunicorn.sock

# 3. Verificar se o arquivo .env existe
ls -la /home/ubuntu/s_agendamento/.env

# 4. Testar Django diretamente
cd /home/ubuntu/s_agendamento
source .venv/bin/activate
python manage.py runserver 0.0.0.0:8000 &
sleep 5
curl -I http://localhost:8000/
pkill -f "python manage.py runserver"

# 5. Verificar logs detalhados do Gunicorn
sudo journalctl -u gunicorn -f --no-pager

# 6. Reiniciar Gunicorn com debug
sudo systemctl stop gunicorn
cd /home/ubuntu/s_agendamento
source .venv/bin/activate
gunicorn --bind 0.0.0.0:8000 --log-level debug core.wsgi:application &
sleep 5
curl -I http://localhost:8000/
pkill -f gunicorn

# 7. Verificar configuração do Nginx
sudo nginx -t
cat /etc/nginx/sites-available/agendamento-4minds

# 8. Testar socket diretamente
cd /home/ubuntu/s_agendamento
source .venv/bin/activate
gunicorn --bind unix:/home/ubuntu/s_agendamento/gunicorn.sock core.wsgi:application &
sleep 5
curl -I http://localhost:8000/
pkill -f gunicorn
```

### **SE O PROBLEMA PERSISTIR, EXECUTE:**

```bash
# Correção manual completa
cd /home/ubuntu/s_agendamento

# Fazer commit das mudanças locais
git add .
git commit -m "fix: Local changes"
git pull origin main

# Ativar ambiente virtual
source .venv/bin/activate

# Criar arquivo .env se não existir
cat > .env << 'EOF'
# Database (RDS PostgreSQL)
DB_ENGINE=django.db.backends.postgresql
DB_NAME=agendamentos_db
DB_USER=postgres
DB_PASSWORD=4MindsAgendamento2025!SecureDB#Pass
DB_HOST=agendamento-4minds-postgres.cgr24gyuwi3d.us-east-1.rds.amazonaws.com
DB_PORT=5432

# AWS S3
AWS_STORAGE_BUCKET_NAME=agendamento-4minds-static-abc123
AWS_S3_REGION_NAME=us-east-1
USE_S3=True

# CloudWatch Logs
CLOUDWATCH_LOG_GROUP=/aws/ec2/agendamento-4minds/django
AWS_REGION_NAME=us-east-1

# SNS Alerts
SNS_TOPIC_ARN=arn:aws:sns:us-east-1:295748148791:agendamento-4minds-alerts

# Django
DEBUG=False
ALLOWED_HOSTS=fourmindstech.com.br,www.fourmindstech.com.br,3.80.178.120,localhost,127.0.0.1
SECRET_KEY=4MindsAgendamento2025!SecretKey#Django
EOF

# Executar migrações
python manage.py migrate

# Coletar arquivos estáticos
python manage.py collectstatic --noinput

# Parar todos os serviços
sudo systemctl stop gunicorn
sudo systemctl stop nginx
sudo pkill -f gunicorn

# Configurar Gunicorn corretamente
sudo tee /etc/systemd/system/gunicorn.service > /dev/null << 'EOF'
[Unit]
Description=Gunicorn daemon for Django
After=network.target

[Service]
User=ubuntu
Group=www-data
WorkingDirectory=/home/ubuntu/s_agendamento
Environment=PATH=/home/ubuntu/s_agendamento/.venv/bin
ExecStart=/home/ubuntu/s_agendamento/.venv/bin/gunicorn --workers 3 --bind unix:/home/ubuntu/s_agendamento/gunicorn.sock core.wsgi:application
ExecReload=/bin/kill -s HUP $MAINPID
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Configurar Nginx corretamente
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
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Ativar configurações
sudo ln -sf /etc/nginx/sites-available/agendamento-4minds /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Corrigir permissões
sudo chown -R ubuntu:www-data /home/ubuntu/s_agendamento
sudo chmod -R 755 /home/ubuntu/s_agendamento

# Testar configuração
sudo nginx -t

# Iniciar serviços
sudo systemctl daemon-reload
sudo systemctl start gunicorn
sudo systemctl enable gunicorn
sudo systemctl restart nginx

# Aguardar
sleep 15

# Verificar status
sudo systemctl status gunicorn --no-pager
sudo systemctl status nginx --no-pager

# Testar aplicação
curl -I http://localhost:8000/
curl -I http://3.80.178.120/
```

---

## 🔍 **VERIFICAÇÃO:**

Após executar os comandos:

```bash
# Verificar se o socket existe
ls -la /home/ubuntu/s_agendamento/gunicorn.sock

# Verificar logs
sudo journalctl -u gunicorn --no-pager -n 20

# Testar aplicação
curl -I http://3.80.178.120/

# Resultado esperado:
# HTTP/1.1 200 OK
```

---

## 🎯 **EXECUTE AGORA:**

**Execute os comandos de diagnóstico primeiro** para identificar o problema!

**Depois execute a correção manual completa!** 🚀
