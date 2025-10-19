# 🚀 INSTRUÇÕES PARA DEPLOY MANUAL NA EC2

## ⚠️ IMPORTANTE: Execute estes comandos na instância EC2

### 📋 Pré-requisitos
- ✅ Instância EC2 rodando (3.80.178.120)
- ✅ RDS PostgreSQL disponível
- ✅ S3 Bucket criado
- ✅ SNS e CloudWatch configurados

---

## 🔑 Conectar na EC2

### Opção 1: Console AWS (Recomendado)
1. Acesse o [Console AWS](https://console.aws.amazon.com)
2. Vá para **EC2** > **Instâncias**
3. Selecione a instância `i-029805f836fb2f238`
4. Clique em **Conectar**
5. Escolha **Session Manager** ou **EC2 Instance Connect**

### Opção 2: SSH (se tiver a chave)
```bash
ssh -i ~/.ssh/sua-chave.pem ubuntu@3.80.178.120
```

---

## 🚀 DEPLOY AUTOMÁTICO

### 1. Navegar para o Diretório
```bash
cd /home/ubuntu/s_agendamento
pwd
ls -la
```

### 2. Criar Arquivo .env
```bash
nano .env
```

Cole o seguinte conteúdo:
```env
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

Salve: `Ctrl+X`, `Y`, `Enter`

### 3. Instalar Dependências
```bash
pip install --upgrade pip
pip install psycopg2-binary boto3 django-storages watchtower

# Se existir requirements.txt
if [ -f "requirements.txt" ]; then
    pip install -r requirements.txt
fi
```

### 4. Configurar Settings para Produção
```bash
# Backup do settings original
cp core/settings.py core/settings.py.backup

# Adicionar configurações de produção
cat >> core/settings.py << 'EOF'

# Configurações de produção
import os

# Database
DATABASES = {
    'default': {
        'ENGINE': os.getenv('DB_ENGINE', 'django.db.backends.sqlite3'),
        'NAME': os.getenv('DB_NAME', 'db.sqlite3'),
        'USER': os.getenv('DB_USER', ''),
        'PASSWORD': os.getenv('DB_PASSWORD', ''),
        'HOST': os.getenv('DB_HOST', 'localhost'),
        'PORT': os.getenv('DB_PORT', '5432'),
    }
}

# AWS S3 para arquivos estáticos
if os.getenv('USE_S3', 'False').lower() == 'true':
    AWS_STORAGE_BUCKET_NAME = os.getenv('AWS_STORAGE_BUCKET_NAME')
    AWS_S3_REGION_NAME = os.getenv('AWS_S3_REGION_NAME')
    AWS_S3_CUSTOM_DOMAIN = f'{AWS_STORAGE_BUCKET_NAME}.s3.amazonaws.com'
    
    # Configurações de armazenamento
    STATICFILES_STORAGE = 'storages.backends.s3boto3.S3Boto3Storage'
    DEFAULT_FILE_STORAGE = 'storages.backends.s3boto3.S3Boto3Storage'
    
    # URLs estáticas
    STATIC_URL = f'https://{AWS_S3_CUSTOM_DOMAIN}/static/'
    MEDIA_URL = f'https://{AWS_S3_CUSTOM_DOMAIN}/media/'

# CloudWatch Logs
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'handlers': {
        'cloudwatch': {
            'level': 'INFO',
            'class': 'watchtower.CloudWatchLogsHandler',
            'log_group': os.getenv('CLOUDWATCH_LOG_GROUP', '/aws/ec2/agendamento-4minds/django'),
            'stream_name': 'django-app',
        },
    },
    'loggers': {
        'django': {
            'handlers': ['cloudwatch'],
            'level': 'INFO',
            'propagate': True,
        },
    },
}
EOF
```

### 5. Testar Conexão com RDS
```bash
python manage.py check --database default
```

### 6. Executar Migrações
```bash
python manage.py migrate
```

### 7. Criar Superusuário
```bash
python manage.py createsuperuser
# Usuário: admin
# Email: admin@4minds.com.br
# Senha: admin123
```

### 8. Coletar Arquivos Estáticos
```bash
python manage.py collectstatic --noinput
```

### 9. Configurar Gunicorn
```bash
sudo nano /etc/systemd/system/gunicorn.service
```

Cole o seguinte conteúdo:
```ini
[Unit]
Description=Gunicorn daemon for Django
After=network.target

[Service]
User=ubuntu
Group=www-data
WorkingDirectory=/home/ubuntu/s_agendamento
ExecStart=/usr/bin/python3 -m gunicorn --bind unix:/home/ubuntu/s_agendamento/gunicorn.sock core.wsgi:application
ExecReload=/bin/kill -s HUP $MAINPID
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

### 10. Configurar Nginx
```bash
sudo nano /etc/nginx/sites-available/agendamento-4minds
```

Cole o seguinte conteúdo:
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

### 11. Ativar Site e Reiniciar Serviços
```bash
# Ativar site
sudo ln -sf /etc/nginx/sites-available/agendamento-4minds /etc/nginx/sites-enabled
sudo rm -f /etc/nginx/sites-enabled/default

# Testar configuração
sudo nginx -t

# Configurar permissões
sudo chown -R ubuntu:www-data /home/ubuntu/s_agendamento
sudo chmod -R 755 /home/ubuntu/s_agendamento

# Reiniciar serviços
sudo systemctl daemon-reload
sudo systemctl restart gunicorn
sudo systemctl restart nginx
sudo systemctl enable gunicorn
sudo systemctl enable nginx
```

### 12. Verificar Status
```bash
# Verificar status dos serviços
sudo systemctl status gunicorn
sudo systemctl status nginx

# Testar aplicação
curl -I http://localhost:8000/
curl -I http://fourmindstech.com.br/
```

---

## 🎯 URLs de Acesso

- **Aplicação**: http://fourmindstech.com.br
- **Admin**: http://fourmindstech.com.br/admin
- **Usuário**: admin
- **Senha**: admin123

---

## 🔧 Comandos Úteis

```bash
# Ver logs em tempo real
sudo journalctl -u gunicorn -f

# Reiniciar serviços
sudo systemctl restart gunicorn nginx

# Verificar status
sudo systemctl status gunicorn nginx

# Testar configuração
python manage.py check
python manage.py check --database default
```

---

## 🚨 Solução de Problemas

### Erro de Conexão com RDS
```bash
# Verificar se o RDS está acessível
telnet agendamento-4minds-postgres.cgr24gyuwi3d.us-east-1.rds.amazonaws.com 5432
```

### Erro de Arquivos Estáticos
```bash
# Verificar permissões
sudo chown -R ubuntu:www-data /home/ubuntu/s_agendamento
sudo chmod -R 755 /home/ubuntu/s_agendamento
```

### Erro de Gunicorn
```bash
# Verificar logs
sudo journalctl -u gunicorn -n 50
```

---

## ✅ Checklist Final

- [ ] Conectado na EC2
- [ ] Arquivo .env criado
- [ ] Dependências instaladas
- [ ] Settings configurado
- [ ] Conexão com RDS testada
- [ ] Migrações executadas
- [ ] Superusuário criado
- [ ] Arquivos estáticos coletados
- [ ] Gunicorn configurado
- [ ] Nginx configurado
- [ ] Serviços reiniciados
- [ ] Aplicação acessível

---

## 🎉 Resultado Final

Após executar todos os passos, sua aplicação Django estará rodando em:
- **URL**: http://fourmindstech.com.br
- **Admin**: http://fourmindstech.com.br/admin
- **Banco**: RDS PostgreSQL
- **Arquivos**: S3
- **Logs**: CloudWatch
- **Alertas**: SNS

**Tudo configurado e funcionando!** 🚀
