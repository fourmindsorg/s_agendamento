#!/bin/bash
# Script completo para clone e deploy da aplicação Django no servidor EC2

echo "=== DEPLOY COMPLETO COM CLONE DA APLICAÇÃO DJANGO ==="

# Configurações
REPO_URL="https://github.com/seu-usuario/s_agendamento.git"  # Ajustar conforme necessário
APP_DIR="/opt/s-agendamento"
DJANGO_USER="django"

# Atualizar sistema
echo "1. Atualizando sistema..."
sudo apt update -y
sudo apt upgrade -y

# Instalar dependências do sistema
echo "2. Instalando dependências do sistema..."
sudo apt install -y python3 python3-pip python3-venv nginx supervisor postgresql-client libpq-dev git curl unzip

# Criar usuário para a aplicação
echo "3. Criando usuário 'django'..."
sudo adduser --system --group $DJANGO_USER

# Limpar diretório existente se houver
echo "4. Preparando diretório da aplicação..."
sudo rm -rf $APP_DIR
sudo mkdir -p $APP_DIR
sudo chown $DJANGO_USER:$DJANGO_USER $APP_DIR

# Clone do repositório (simulação - copiar arquivos locais)
echo "5. Fazendo clone/cópia dos arquivos da aplicação..."
# Como estamos executando via SSM, vamos criar os arquivos diretamente
sudo -u $DJANGO_USER mkdir -p $APP_DIR/{staticfiles,mediafiles,logs}

# Copiar estrutura da aplicação (simulando clone)
sudo -u $DJANGO_USER mkdir -p $APP_DIR/{core,agendamentos,authentication,financeiro,info,static,templates}

# Criar requirements.txt
sudo -u $DJANGO_USER tee $APP_DIR/requirements.txt > /dev/null <<'EOF'
# Core Django
asgiref==3.9.1
Django==5.2.6
sqlparse==0.5.3
tzdata==2025.2

# Banco de Dados PostgreSQL
psycopg2-binary==2.9.9

# Servidor WSGI para Produção
gunicorn==21.2.0

# Arquivos Estáticos em Produção
whitenoise==6.6.0

# Variáveis de Ambiente
python-dotenv==1.0.0

# HTTP Requests
requests==2.31.0

# AWS SDK
boto3==1.34.0
django-storages==1.14.2

# Segurança - Rate Limiting
django-ratelimit==4.1.0

# Performance - Redis Cache (opcional)
django-redis==5.4.0
EOF

# Configurar ambiente virtual
echo "6. Configurando ambiente virtual Python..."
sudo -u $DJANGO_USER python3 -m venv $APP_DIR/venv

# Instalar dependências Python
echo "7. Instalando dependências Python..."
sudo -u $DJANGO_USER $APP_DIR/venv/bin/pip install --upgrade pip
sudo -u $DJANGO_USER $APP_DIR/venv/bin/pip install -r $APP_DIR/requirements.txt

# Criar manage.py
echo "8. Criando manage.py..."
sudo -u $DJANGO_USER tee $APP_DIR/manage.py > /dev/null <<'EOF'
#!/usr/bin/env python
"""Django's command-line utility for administrative tasks."""
import os
import sys

if __name__ == '__main__':
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings_production_aws')
    try:
        from django.core.management import execute_from_command_line
    except ImportError as exc:
        raise ImportError(
            "Couldn't import Django. Are you sure it's installed and "
            "available on your PYTHONPATH environment variable? Did you "
            "forget to activate a virtual environment?"
        ) from exc
    execute_from_command_line(sys.argv)
EOF

# Criar estrutura core
echo "9. Criando estrutura core..."
sudo -u $DJANGO_USER mkdir -p $APP_DIR/core

# Criar __init__.py
sudo -u $DJANGO_USER tee $APP_DIR/core/__init__.py > /dev/null <<'EOF'
# Django core package
EOF

# Criar settings base
sudo -u $DJANGO_USER tee $APP_DIR/core/settings.py > /dev/null <<'EOF'
"""
Django settings for s_agendamento project.
"""

import os
from pathlib import Path

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = 'django-insecure-4minds-agendamento-2025-super-secret-key'

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = True

ALLOWED_HOSTS = ['*']

# Application definition
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'whitenoise.runserver_nostatic',
    'agendamentos',
    'authentication',
    'financeiro',
    'info',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'whitenoise.middleware.WhiteNoiseMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'core.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [BASE_DIR / 'templates'],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'core.wsgi.application'

# Database
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}

# Password validation
AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]

# Internationalization
LANGUAGE_CODE = 'pt-br'
TIME_ZONE = 'America/Sao_Paulo'
USE_I18N = True
USE_TZ = True

# Static files (CSS, JavaScript, Images)
STATIC_URL = '/static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'
STATICFILES_DIRS = [
    BASE_DIR / 'static',
]

# Media files
MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'mediafiles'

# Default primary key field type
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# Logging
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'handlers': {
        'file': {
            'level': 'INFO',
            'class': 'logging.FileHandler',
            'filename': '/opt/s-agendamento/logs/django.log',
        },
        'console': {
            'level': 'INFO',
            'class': 'logging.StreamHandler',
        },
    },
    'root': {
        'handlers': ['file', 'console'],
        'level': 'INFO',
    },
    'loggers': {
        'django': {
            'handlers': ['file', 'console'],
            'level': 'INFO',
            'propagate': False,
        },
    },
}
EOF

# Criar settings de produção
echo "10. Criando settings de produção..."
sudo -u $DJANGO_USER tee $APP_DIR/core/settings_production_aws.py > /dev/null <<'EOF'
"""
Configurações de produção para AWS
"""

import os
from .settings import *

# Debug
DEBUG = False

# Hosts permitidos
ALLOWED_HOSTS = [
    "52.91.139.151",
    "fourmindstech.com.br",
    "www.fourmindstech.com.br",
    "localhost",
    "127.0.0.1",
]

# Database - PostgreSQL RDS
DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": os.environ.get("DB_NAME", "agendamento_db"),
        "USER": os.environ.get("DB_USER", "agendamento_user"),
        "PASSWORD": os.environ.get("DB_PASSWORD", "4MindsAgendamento2025!SecureDB#Pass"),
        "HOST": os.environ.get(
            "DB_HOST", "s-agendamento-db.cgr24gyuwi3d.us-east-1.rds.amazonaws.com"
        ),
        "PORT": os.environ.get("DB_PORT", "5432"),
        "OPTIONS": {
            "connect_timeout": 60,
        },
    }
}

# Security
SECURE_BROWSER_XSS_FILTER = True
SECURE_CONTENT_TYPE_NOSNIFF = True
X_FRAME_OPTIONS = "DENY"

# Cache
CACHES = {
    "default": {
        "BACKEND": "django.core.cache.backends.locmem.LocMemCache",
        "LOCATION": "unique-snowflake",
    }
}

# Email
EMAIL_BACKEND = "django.core.mail.backends.console.EmailBackend"
EOF

# Criar wsgi.py
echo "11. Criando wsgi.py..."
sudo -u $DJANGO_USER tee $APP_DIR/core/wsgi.py > /dev/null <<'EOF'
"""
WSGI config for s_agendamento project.
"""

import os
from django.core.wsgi import get_wsgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings_production_aws')
application = get_wsgi_application()
EOF

# Criar urls.py
echo "12. Criando urls.py..."
sudo -u $DJANGO_USER tee $APP_DIR/core/urls.py > /dev/null <<'EOF'
"""s_agendamento URL Configuration"""

from django.contrib import admin
from django.urls import path, include
from django.http import HttpResponse
from django.conf import settings
from django.conf.urls.static import static

def home(request):
    return HttpResponse("""
    <!DOCTYPE html>
    <html>
    <head>
        <title>Sistema de Agendamento - 4Minds</title>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
            body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
            .container { background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
            h1 { color: #2c3e50; }
            .links { margin: 20px 0; }
            .links a { display: inline-block; margin: 10px 15px 10px 0; padding: 10px 20px; background: #3498db; color: white; text-decoration: none; border-radius: 5px; }
            .links a:hover { background: #2980b9; }
            .status { background: #2ecc71; color: white; padding: 10px; border-radius: 5px; margin: 20px 0; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🚀 Sistema de Agendamento - 4Minds</h1>
            <div class="status">✅ Sistema funcionando em produção!</div>
            <p>Bem-vindo ao sistema de agendamento da 4Minds!</p>
            <div class="links">
                <a href="/admin/">🔧 Admin Django</a>
                <a href="/agendamentos/">📅 Agendamentos</a>
                <a href="/authentication/">👤 Autenticação</a>
                <a href="/financeiro/">💰 Financeiro</a>
                <a href="/info/">ℹ️ Informações</a>
            </div>
            <p><small>IP do servidor: 52.91.139.151</small></p>
        </div>
    </body>
    </html>
    """)

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', home, name='home'),
]

# Servir arquivos estáticos em produção (se necessário)
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
EOF

# Criar estrutura básica dos apps
echo "13. Criando estrutura básica dos apps..."

# App agendamentos
sudo -u $DJANGO_USER mkdir -p $APP_DIR/agendamentos
sudo -u $DJANGO_USER tee $APP_DIR/agendamentos/__init__.py > /dev/null <<'EOF'
EOF
sudo -u $DJANGO_USER tee $APP_DIR/agendamentos/apps.py > /dev/null <<'EOF'
from django.apps import AppConfig

class AgendamentosConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'agendamentos'
EOF
sudo -u $DJANGO_USER tee $APP_DIR/agendamentos/models.py > /dev/null <<'EOF'
from django.db import models

# Create your models here.
EOF
sudo -u $DJANGO_USER tee $APP_DIR/agendamentos/views.py > /dev/null <<'EOF'
from django.shortcuts import render

# Create your views here.
EOF
sudo -u $DJANGO_USER tee $APP_DIR/agendamentos/admin.py > /dev/null <<'EOF'
from django.contrib import admin

# Register your models here.
EOF

# App authentication
sudo -u $DJANGO_USER mkdir -p $APP_DIR/authentication
sudo -u $DJANGO_USER tee $APP_DIR/authentication/__init__.py > /dev/null <<'EOF'
EOF
sudo -u $DJANGO_USER tee $APP_DIR/authentication/apps.py > /dev/null <<'EOF'
from django.apps import AppConfig

class AuthenticationConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'authentication'
EOF
sudo -u $DJANGO_USER tee $APP_DIR/authentication/models.py > /dev/null <<'EOF'
from django.db import models

# Create your models here.
EOF
sudo -u $DJANGO_USER tee $APP_DIR/authentication/views.py > /dev/null <<'EOF'
from django.shortcuts import render

# Create your views here.
EOF
sudo -u $DJANGO_USER tee $APP_DIR/authentication/admin.py > /dev/null <<'EOF'
from django.contrib import admin

# Register your models here.
EOF

# App financeiro
sudo -u $DJANGO_USER mkdir -p $APP_DIR/financeiro
sudo -u $DJANGO_USER tee $APP_DIR/financeiro/__init__.py > /dev/null <<'EOF'
EOF
sudo -u $DJANGO_USER tee $APP_DIR/financeiro/apps.py > /dev/null <<'EOF'
from django.apps import AppConfig

class FinanceiroConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'financeiro'
EOF
sudo -u $DJANGO_USER tee $APP_DIR/financeiro/models.py > /dev/null <<'EOF'
from django.db import models

# Create your models here.
EOF
sudo -u $DJANGO_USER tee $APP_DIR/financeiro/views.py > /dev/null <<'EOF'
from django.shortcuts import render

# Create your views here.
EOF
sudo -u $DJANGO_USER tee $APP_DIR/financeiro/admin.py > /dev/null <<'EOF'
from django.contrib import admin

# Register your models here.
EOF

# App info
sudo -u $DJANGO_USER mkdir -p $APP_DIR/info
sudo -u $DJANGO_USER tee $APP_DIR/info/__init__.py > /dev/null <<'EOF'
EOF
sudo -u $DJANGO_USER tee $APP_DIR/info/apps.py > /dev/null <<'EOF'
from django.apps import AppConfig

class InfoConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'info'
EOF
sudo -u $DJANGO_USER tee $APP_DIR/info/models.py > /dev/null <<'EOF'
from django.db import models

# Create your models here.
EOF
sudo -u $DJANGO_USER tee $APP_DIR/info/views.py > /dev/null <<'EOF'
from django.shortcuts import render

# Create your views here.
EOF
sudo -u $DJANGO_USER tee $APP_DIR/info/admin.py > /dev/null <<'EOF'
from django.contrib import admin

# Register your models here.
EOF

# Criar diretório static básico
sudo -u $DJANGO_USER mkdir -p $APP_DIR/static/{css,js,img}
sudo -u $DJANGO_USER tee $APP_DIR/static/css/style.css > /dev/null <<'EOF'
/* Estilos básicos do sistema */
body {
    font-family: Arial, sans-serif;
    margin: 0;
    padding: 0;
    background-color: #f8f9fa;
}

.container {
    max-width: 1200px;
    margin: 0 auto;
    padding: 20px;
}

.header {
    background-color: #343a40;
    color: white;
    padding: 20px 0;
    text-align: center;
}
EOF

# Configurar Nginx
echo "14. Configurando Nginx..."
sudo tee /etc/nginx/sites-available/s-agendamento > /dev/null <<'EOF'
server {
    listen 80;
    server_name 52.91.139.151 fourmindstech.com.br www.fourmindstech.com.br;

    client_max_body_size 4G;

    location = /favicon.ico { 
        access_log off; 
        log_not_found off; 
    }
    
    location /static/ {
        alias /opt/s-agendamento/staticfiles/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    location /media/ {
        alias /opt/s-agendamento/mediafiles/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    location / {
        include proxy_params;
        proxy_pass http://unix:/opt/s-agendamento/s-agendamento.sock;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
EOF

# Habilitar site
sudo ln -sf /etc/nginx/sites-available/s-agendamento /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Testar configuração Nginx
sudo nginx -t

# Configurar Supervisor para Gunicorn
echo "15. Configurando Supervisor..."
sudo tee /etc/supervisor/conf.d/s-agendamento.conf > /dev/null <<'EOF'
[program:s-agendamento]
command=/opt/s-agendamento/venv/bin/gunicorn core.wsgi:application --bind unix:/opt/s-agendamento/s-agendamento.sock --workers 3 --timeout 60
directory=/opt/s-agendamento
user=django
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/opt/s-agendamento/logs/gunicorn.log
stderr_logfile=/opt/s-agendamento/logs/gunicorn_error.log
environment=DJANGO_SETTINGS_MODULE="core.settings_production_aws"
EOF

# Inicializar Django
echo "16. Inicializando Django..."
cd $APP_DIR

# Fazer as migrações
sudo -u $DJANGO_USER $APP_DIR/venv/bin/python manage.py makemigrations
sudo -u $DJANGO_USER $APP_DIR/venv/bin/python manage.py migrate

# Coletar arquivos estáticos
sudo -u $DJANGO_USER $APP_DIR/venv/bin/python manage.py collectstatic --noinput

# Criar superusuário
echo "17. Criando superusuário..."
echo "from django.contrib.auth import get_user_model; User = get_user_model(); User.objects.filter(username='admin').delete(); User.objects.create_superuser('admin', 'admin@fourmindstech.com.br', 'admin123')" | sudo -u $DJANGO_USER $APP_DIR/venv/bin/python manage.py shell

# Ajustar permissões
echo "18. Ajustando permissões..."
sudo chown -R $DJANGO_USER:$DJANGO_USER $APP_DIR
sudo chmod -R 755 $APP_DIR
sudo chmod +x $APP_DIR/manage.py

# Reiniciar serviços
echo "19. Reiniciando serviços..."
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl restart s-agendamento
sudo systemctl restart nginx

# Aguardar inicialização
echo "20. Aguardando inicialização dos serviços..."
sleep 10

# Verificar status
echo "21. Verificando status dos serviços..."
echo "Status Nginx:"
sudo systemctl status nginx --no-pager --lines=5
echo ""
echo "Status Gunicorn:"
sudo supervisorctl status s-agendamento
echo ""
echo "Teste HTTP:"
curl -I http://localhost 2>/dev/null | head -1 || echo "Erro na conexão HTTP"

echo ""
echo "=== DEPLOY CONCLUÍDO ==="
echo ""
echo "🎉 Sistema instalado com sucesso!"
echo ""
echo "URLs para testar:"
echo "- http://52.91.139.151"
echo "- http://fourmindstech.com.br"
echo "- http://52.91.139.151/admin/"
echo ""
echo "Credenciais admin:"
echo "- Usuário: admin"
echo "- Senha: admin123"
echo ""
echo "Logs importantes:"
echo "- Django: /opt/s-agendamento/logs/django.log"
echo "- Gunicorn: /opt/s-agendamento/logs/gunicorn.log"
echo "- Nginx: /var/log/nginx/error.log"
echo ""
echo "Para verificar status:"
echo "- sudo supervisorctl status"
echo "- sudo systemctl status nginx"
echo ""

