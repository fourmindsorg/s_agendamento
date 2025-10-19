# 🚀 DEPLOY MANUAL FINAL - EC2

## ❌ **Problema Identificado**
- **AWS Systems Manager**: Instância não está em estado válido para receber comandos
- **Erro**: `InvalidInstanceId: Instances not in a valid state for account`

## ✅ **Solução: Deploy Manual via Console AWS**

### 🎯 **Passo a Passo Completo**

#### **1. Acessar Console AWS**
1. Vá para: https://console.aws.amazon.com/ec2/
2. Faça login com suas credenciais AWS
3. Vá para **Instances** no menu lateral

#### **2. Conectar na EC2**
1. Selecione a instância `agendamento-4minds-web-server`
2. Clique em **Connect**
3. Escolha **EC2 Instance Connect**
4. Clique em **Connect**

#### **3. Executar Deploy Manual**
```bash
# Navegar para o diretório do projeto
cd /home/ubuntu/s_agendamento

# Verificar diretório atual
pwd

# Atualizar código do repositório
git pull origin main

# Instalar dependências
pip install -r requirements.txt

# Executar migrações
python manage.py migrate

# Coletar arquivos estáticos
python manage.py collectstatic --noinput

# Reiniciar serviços
sudo systemctl restart gunicorn
sudo systemctl restart nginx

# Verificar status dos serviços
sudo systemctl status gunicorn
sudo systemctl status nginx

# Testar aplicação
curl -I http://localhost:8000/
curl -I http://3.80.178.120/
```

#### **4. Verificar Deploy**
```bash
# Verificar logs do Gunicorn
sudo journalctl -u gunicorn -f

# Verificar logs do Nginx
sudo journalctl -u nginx -f

# Verificar se a aplicação está rodando
ps aux | grep gunicorn
ps aux | grep nginx
```

---

## 🔧 **Configuração Adicional (Se Necessário)**

### **1. Configurar Gunicorn (se não estiver rodando)**
```bash
# Criar arquivo de configuração do Gunicorn
sudo nano /etc/systemd/system/gunicorn.service

# Conteúdo do arquivo:
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

# Recarregar e iniciar serviço
sudo systemctl daemon-reload
sudo systemctl start gunicorn
sudo systemctl enable gunicorn
```

### **2. Configurar Nginx (se não estiver rodando)**
```bash
# Criar configuração do Nginx
sudo nano /etc/nginx/sites-available/agendamento-4minds

# Conteúdo do arquivo:
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

# Ativar site
sudo ln -s /etc/nginx/sites-available/agendamento-4minds /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### **3. Configurar Ambiente Django**
```bash
# Criar arquivo .env
nano /home/ubuntu/s_agendamento/.env

# Conteúdo do arquivo:
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

---

## 🌐 **Configuração DNS**

### **Registros DNS Necessários**
```
Tipo: A
Nome: @
Valor: 3.80.178.120
TTL: 300

Tipo: CNAME
Nome: www
Valor: fourmindstech.com.br
TTL: 300
```

### **Configurar no Provedor DNS**
1. Acesse o painel do seu provedor de domínio
2. Vá para a seção DNS/Zona DNS
3. Adicione os registros A e CNAME acima
4. Aguarde propagação (5-15 minutos)

---

## ✅ **Verificação Final**

### **1. Testar Aplicação**
- **IP**: http://3.80.178.120
- **Domínio**: http://fourmindstech.com.br (após DNS)
- **Admin**: http://fourmindstech.com.br/admin
- **Usuário**: admin
- **Senha**: admin123

### **2. Verificar Logs**
```bash
# Logs do Gunicorn
sudo journalctl -u gunicorn -f

# Logs do Nginx
sudo journalctl -u nginx -f

# Logs do sistema
sudo tail -f /var/log/syslog
```

### **3. Verificar Serviços**
```bash
# Status dos serviços
sudo systemctl status gunicorn
sudo systemctl status nginx

# Processos rodando
ps aux | grep gunicorn
ps aux | grep nginx
```

---

## 🚨 **Troubleshooting**

### **Problema: Aplicação não carrega**
- **Solução**: Verificar se Gunicorn está rodando
- **Comando**: `sudo systemctl status gunicorn`

### **Problema: Erro 502 Bad Gateway**
- **Solução**: Verificar se Nginx está configurado corretamente
- **Comando**: `sudo nginx -t`

### **Problema: Erro de banco de dados**
- **Solução**: Verificar se RDS está acessível
- **Comando**: `telnet agendamento-4minds-postgres.cgr24gyuwi3d.us-east-1.rds.amazonaws.com 5432`

### **Problema: DNS não resolve**
- **Solução**: Aguardar propagação DNS (até 24h)
- **Verificação**: `nslookup fourmindstech.com.br`

---

## 🎯 **Resumo do Deploy**

1. **Conectar na EC2** via Console AWS
2. **Executar comandos** de deploy manual
3. **Configurar serviços** (Gunicorn/Nginx)
4. **Configurar DNS** para domínio personalizado
5. **Testar aplicação** funcionando

**Deploy manual concluído!** 🚀
