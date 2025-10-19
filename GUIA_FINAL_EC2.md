# 🚀 GUIA FINAL PARA EC2 - EXECUTE MANUALMENTE

## ❌ **Problemas Identificados:**
- **SSH**: Chave não funciona (`Permission denied`)
- **AWS Systems Manager**: Instância não aceita comandos (`InvalidInstanceId`)
- **Solução**: Execute comandos manualmente via Console AWS

## 🎯 **EXECUTE ESTES COMANDOS NA EC2 VIA CONSOLE AWS:**

### **1. Conectar na EC2**
1. Acesse: https://console.aws.amazon.com/ec2/
2. Vá para **Instances**
3. Selecione a instância `agendamento-4minds-web-server`
4. Clique em **Connect** → **EC2 Instance Connect**

### **2. Diagnóstico Básico**
```bash
# Verificar diretório atual
pwd
whoami

# Verificar conteúdo do diretório home
cd /home/ubuntu
ls -la

# Verificar se s_agendamento existe
if [ -d "s_agendamento" ]; then
    echo "✅ Diretório s_agendamento existe"
    cd s_agendamento
    ls -la
else
    echo "❌ Diretório s_agendamento não existe"
fi
```

### **3. Se s_agendamento NÃO existe, clonar repositório:**
```bash
cd /home/ubuntu
git clone https://github.com/fourmindsorg/s_agendamento.git
cd s_agendamento
ls -la
```

### **4. Instalar dependências:**
```bash
# Atualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar dependências
sudo apt install -y python3 python3-pip python3-venv python3-dev postgresql-client nginx git libpq-dev build-essential

# Configurar ambiente virtual
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

### **5. Configurar arquivo .env:**
```bash
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
```

### **6. Executar migrações:**
```bash
# Executar migrações
python manage.py migrate

# Criar superusuário
echo "from django.contrib.auth import get_user_model; User = get_user_model(); User.objects.create_superuser('admin', 'admin@fourmindstech.com.br', 'admin123') if not User.objects.filter(username='admin').exists() else print('Superusuário já existe')" | python manage.py shell

# Coletar arquivos estáticos
python manage.py collectstatic --noinput
```

### **7. Instalar e configurar Gunicorn:**
```bash
# Instalar Gunicorn
pip install gunicorn

# Configurar serviço Gunicorn
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
```

### **8. Configurar Nginx:**
```bash
# Configurar Nginx
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

# Ativar configuração
sudo ln -sf /etc/nginx/sites-available/agendamento-4minds /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
```

### **9. Corrigir permissões e iniciar serviços:**
```bash
# Corrigir permissões
sudo chown -R ubuntu:www-data /home/ubuntu/s_agendamento
sudo chmod -R 755 /home/ubuntu/s_agendamento

# Testar configuração do Nginx
sudo nginx -t

# Iniciar serviços
sudo systemctl daemon-reload
sudo systemctl start gunicorn
sudo systemctl enable gunicorn
sudo systemctl restart nginx
```

### **10. Verificar status:**
```bash
# Verificar status dos serviços
sudo systemctl status gunicorn
sudo systemctl status nginx

# Testar aplicação
curl -I http://localhost:8000/
curl -I http://3.80.178.120/

# Verificar logs se houver problemas
sudo journalctl -u gunicorn -f
sudo journalctl -u nginx -f
```

---

## 🎯 **URLs de Acesso Após Configuração:**

- **IP**: http://3.80.178.120
- **Domínio**: http://fourmindstech.com.br (após configurar DNS)
- **Admin**: http://3.80.178.120/admin
- **Usuário**: admin
- **Senha**: admin123

---

## 🚨 **Troubleshooting:**

### **Problema: Gunicorn não inicia**
```bash
sudo journalctl -u gunicorn -f
sudo systemctl restart gunicorn
```

### **Problema: Nginx erro 502**
```bash
sudo systemctl status gunicorn
ls -la /home/ubuntu/s_agendamento/gunicorn.sock
```

### **Problema: Erro de permissão**
```bash
sudo chown -R ubuntu:www-data /home/ubuntu/s_agendamento
sudo chmod -R 755 /home/ubuntu/s_agendamento
```

---

## ✅ **Checklist Final:**

- [ ] Conectado na EC2 via Console AWS
- [ ] Repositório clonado
- [ ] Dependências instaladas
- [ ] Ambiente virtual configurado
- [ ] Arquivo .env criado
- [ ] Migrações executadas
- [ ] Superusuário criado
- [ ] Gunicorn configurado e rodando
- [ ] Nginx configurado e rodando
- [ ] Aplicação testada e funcionando

**Execute estes comandos na EC2 e me informe o resultado!** 🚀
