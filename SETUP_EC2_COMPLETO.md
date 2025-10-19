# 🚀 SETUP COMPLETO NA EC2 - PASSO A PASSO

## 📍 **Situação Atual**
- ✅ Conectado na EC2 via Console AWS
- ❌ Diretório `/home/ubuntu/s_agendamento` não existe
- ✅ Arquivo `deploy_django_ec2.sh` presente

## 🎯 **Comandos para Executar na EC2**

### **1. Clonar Repositório**
```bash
# Clonar o repositório do GitHub
git clone https://github.com/fourmindsorg/s_agendamento.git

# Navegar para o diretório
cd s_agendamento

# Verificar se clonou corretamente
ls -la
```

### **2. Instalar Dependências do Sistema**
```bash
# Atualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar Python e dependências
sudo apt install -y python3 python3-pip python3-venv python3-dev
sudo apt install -y postgresql-client
sudo apt install -y nginx
sudo apt install -y git

# Instalar dependências Python adicionais
sudo apt install -y libpq-dev build-essential
```

### **3. Configurar Ambiente Virtual**
```bash
# Criar ambiente virtual
python3 -m venv .venv

# Ativar ambiente virtual
source .venv/bin/activate

# Instalar dependências Python
pip install --upgrade pip
pip install -r requirements.txt
```

### **4. Configurar Variáveis de Ambiente**
```bash
# Criar arquivo .env
nano .env
```

**Conteúdo do arquivo .env:**
```bash
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
```

### **5. Executar Migrações e Configurações**
```bash
# Executar migrações
python manage.py migrate

# Criar superusuário
python manage.py createsuperuser
# Usuário: admin
# Email: admin@fourmindstech.com.br
# Senha: admin123

# Coletar arquivos estáticos
python manage.py collectstatic --noinput
```

### **6. Configurar Gunicorn**
```bash
# Instalar Gunicorn
pip install gunicorn

# Criar arquivo de configuração do Gunicorn
sudo nano /etc/systemd/system/gunicorn.service
```

**Conteúdo do arquivo gunicorn.service:**
```ini
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
```

### **7. Configurar Nginx**
```bash
# Criar configuração do Nginx
sudo nano /etc/nginx/sites-available/agendamento-4minds
```

**Conteúdo do arquivo nginx:**
```nginx
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
```

### **8. Ativar Configurações**
```bash
# Ativar site do Nginx
sudo ln -s /etc/nginx/sites-available/agendamento-4minds /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default

# Testar configuração do Nginx
sudo nginx -t

# Recarregar e iniciar serviços
sudo systemctl daemon-reload
sudo systemctl start gunicorn
sudo systemctl enable gunicorn
sudo systemctl restart nginx

# Verificar status
sudo systemctl status gunicorn
sudo systemctl status nginx
```

### **9. Testar Aplicação**
```bash
# Testar localmente
curl -I http://localhost:8000/

# Testar externamente
curl -I http://3.80.178.120/

# Verificar logs se houver problemas
sudo journalctl -u gunicorn -f
sudo journalctl -u nginx -f
```

---

## 🔧 **Comandos de Verificação**

### **Verificar Status dos Serviços**
```bash
# Status do Gunicorn
sudo systemctl status gunicorn

# Status do Nginx
sudo systemctl status nginx

# Processos rodando
ps aux | grep gunicorn
ps aux | grep nginx
```

### **Verificar Logs**
```bash
# Logs do Gunicorn
sudo journalctl -u gunicorn -f

# Logs do Nginx
sudo journalctl -u nginx -f

# Logs do sistema
sudo tail -f /var/log/syslog
```

### **Testar Conectividade**
```bash
# Testar RDS
telnet agendamento-4minds-postgres.cgr24gyuwi3d.us-east-1.rds.amazonaws.com 5432

# Testar aplicação
curl -v http://localhost:8000/
curl -v http://3.80.178.120/
```

---

## 🚨 **Troubleshooting**

### **Problema: Erro de permissão**
```bash
# Corrigir permissões
sudo chown -R ubuntu:www-data /home/ubuntu/s_agendamento
sudo chmod -R 755 /home/ubuntu/s_agendamento
```

### **Problema: Gunicorn não inicia**
```bash
# Verificar logs
sudo journalctl -u gunicorn -f

# Reiniciar serviço
sudo systemctl restart gunicorn
```

### **Problema: Nginx erro 502**
```bash
# Verificar se Gunicorn está rodando
sudo systemctl status gunicorn

# Verificar socket
ls -la /home/ubuntu/s_agendamento/gunicorn.sock
```

---

## 🎯 **URLs de Acesso**

Após configuração completa:
- **IP**: http://3.80.178.120
- **Domínio**: http://fourmindstech.com.br (após configurar DNS)
- **Admin**: http://fourmindstech.com.br/admin
- **Usuário**: admin
- **Senha**: admin123

---

## ✅ **Checklist de Configuração**

- [ ] Repositório clonado
- [ ] Dependências do sistema instaladas
- [ ] Ambiente virtual criado e ativado
- [ ] Dependências Python instaladas
- [ ] Arquivo .env configurado
- [ ] Migrações executadas
- [ ] Superusuário criado
- [ ] Arquivos estáticos coletados
- [ ] Gunicorn configurado e rodando
- [ ] Nginx configurado e rodando
- [ ] Aplicação testada e funcionando

**Setup completo na EC2!** 🚀
