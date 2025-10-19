# 🚀 Guia de Configuração do Django na EC2

## 📋 Pré-requisitos
- ✅ Instância EC2 rodando (3.80.178.120)
- ✅ RDS PostgreSQL disponível
- ✅ S3 Bucket criado
- ✅ SNS e CloudWatch configurados

## 🔑 Credenciais do RDS
- **Endpoint**: agendamento-4minds-postgres.cgr24gyuwi3d.us-east-1.rds.amazonaws.com
- **Porta**: 5432
- **Database**: agendamentos_db
- **Username**: postgres
- **Password**: 4MindsAgendamento2025!SecureDB#Pass

## 📝 Passo a Passo

### 1. Conectar na Instância EC2

```bash
# Opção 1: SSH (se tiver a chave)
ssh -i ~/.ssh/agendamento-4minds-key.pem ubuntu@3.80.178.120

# Opção 2: Console AWS
# Acesse o Console AWS > EC2 > Instâncias > Conectar
```

### 2. Navegar para o Diretório do Projeto

```bash
cd /home/ubuntu/s_agendamento
ls -la
```

### 3. Criar Arquivo .env

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
ALLOWED_HOSTS=3.80.178.120,fourmindstech.com.br,localhost,127.0.0.1
SECRET_KEY=4MindsAgendamento2025!SecretKey#Django
```

Salve e saia: `Ctrl+X`, `Y`, `Enter`

### 4. Instalar Dependências

```bash
# Ativar ambiente virtual (se existir)
source venv/bin/activate

# Instalar dependências
pip install -r requirements.txt

# Instalar dependências específicas para PostgreSQL e AWS
pip install psycopg2-binary boto3 django-storages
```

### 5. Configurar Settings para Produção

```bash
# Editar settings.py
nano core/settings.py
```

Adicione no final do arquivo:

```python
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
```

### 6. Executar Migrações

```bash
# Testar conexão com o banco
python manage.py check --database default

# Executar migrações
python manage.py migrate

# Criar superusuário
python manage.py createsuperuser
# Usuário: admin
# Email: admin@4minds.com.br
# Senha: admin123
```

### 7. Coletar Arquivos Estáticos

```bash
python manage.py collectstatic --noinput
```

### 8. Configurar Gunicorn

```bash
# Editar configuração do Gunicorn
sudo nano /etc/systemd/system/gunicorn.service
```

Conteúdo:

```ini
[Unit]
Description=Gunicorn daemon for Django
After=network.target

[Service]
User=ubuntu
Group=www-data
WorkingDirectory=/home/ubuntu/s_agendamento
ExecStart=/home/ubuntu/s_agendamento/venv/bin/gunicorn --bind unix:/home/ubuntu/s_agendamento/gunicorn.sock core.wsgi:application
ExecReload=/bin/kill -s HUP $MAINPID
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

### 9. Configurar Nginx

```bash
# Editar configuração do Nginx
sudo nano /etc/nginx/sites-available/agendamento-4minds
```

Conteúdo:

```nginx
server {
    listen 80;
    server_name 3.80.178.120 fourmindstech.com.br;

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

### 10. Ativar e Reiniciar Serviços

```bash
# Ativar site no Nginx
sudo ln -s /etc/nginx/sites-available/agendamento-4minds /etc/nginx/sites-enabled

# Testar configuração do Nginx
sudo nginx -t

# Reiniciar serviços
sudo systemctl daemon-reload
sudo systemctl restart gunicorn
sudo systemctl restart nginx

# Habilitar serviços para iniciar automaticamente
sudo systemctl enable gunicorn
sudo systemctl enable nginx
```

### 11. Verificar Status

```bash
# Verificar status dos serviços
sudo systemctl status gunicorn
sudo systemctl status nginx

# Verificar logs
sudo journalctl -u gunicorn -f
sudo tail -f /var/log/nginx/error.log

# Testar aplicação
curl -I http://localhost:8000/
curl -I http://3.80.178.120/
```

## 🎯 URLs de Acesso

- **Aplicação**: http://3.80.178.120
- **Admin**: http://3.80.178.120/admin
- **Usuário**: admin
- **Senha**: admin123

## 🔧 Comandos Úteis

```bash
# Ver logs em tempo real
sudo journalctl -u gunicorn -f

# Reiniciar serviços
sudo systemctl restart gunicorn
sudo systemctl restart nginx

# Verificar status
sudo systemctl status gunicorn
sudo systemctl status nginx

# Testar configuração
python manage.py check
python manage.py check --database default
```

## 🚨 Solução de Problemas

### Erro de Conexão com RDS
```bash
# Verificar se o security group permite conexão
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

## ✅ Checklist Final

- [ ] Arquivo .env criado com credenciais corretas
- [ ] Dependências instaladas (psycopg2-binary, boto3)
- [ ] Migrações executadas com sucesso
- [ ] Superusuário criado
- [ ] Arquivos estáticos coletados
- [ ] Gunicorn configurado e rodando
- [ ] Nginx configurado e rodando
- [ ] Aplicação acessível via http://3.80.178.120
- [ ] Admin acessível via http://3.80.178.120/admin
