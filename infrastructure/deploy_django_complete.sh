#!/bin/bash
# Script completo para deploy da aplicação Django no servidor EC2

echo "=== DEPLOY COMPLETO DA APLICAÇÃO DJANGO ==="

# Atualizar sistema
echo "1. Atualizando sistema..."
sudo apt update -y
sudo apt upgrade -y

# Instalar dependências
echo "2. Instalando dependências..."
sudo apt install -y python3 python3-pip python3-venv nginx supervisor postgresql-client libpq-dev git curl

# Criar usuário para a aplicação
echo "3. Criando usuário 'django'..."
sudo adduser --system --group django

# Criar diretório para a aplicação
echo "4. Criando diretório da aplicação..."
sudo mkdir -p /opt/s-agendamento
sudo chown django:django /opt/s-agendamento

# Configurar ambiente virtual
echo "5. Configurando ambiente virtual Python..."
sudo -u django python3 -m venv /opt/s-agendamento/venv

# Ativar ambiente virtual e instalar dependências
echo "6. Instalando dependências Python..."
sudo -u django /opt/s-agendamento/venv/bin/pip install --upgrade pip
sudo -u django /opt/s-agendamento/venv/bin/pip install django==5.0.1
sudo -u django /opt/s-agendamento/venv/bin/pip install psycopg2-binary==2.9.9
sudo -u django /opt/s-agendamento/venv/bin/pip install gunicorn==21.2.0
sudo -u django /opt/s-agendamento/venv/bin/pip install whitenoise==6.6.0
sudo -u django /opt/s-agendamento/venv/bin/pip install python-dotenv==1.0.0
sudo -u django /opt/s-agendamento/venv/bin/pip install requests==2.31.0
sudo -u django /opt/s-agendamento/venv/bin/pip install django-ratelimit==4.1.0
sudo -u django /opt/s-agendamento/venv/bin/pip install django-redis==5.4.0
sudo -u django /opt/s-agendamento/venv/bin/pip install boto3==1.34.0
sudo -u django /opt/s-agendamento/venv/bin/pip install django-storages==1.14.2

# Criar estrutura básica do Django
echo "7. Criando estrutura do Django..."
sudo -u django mkdir -p /opt/s-agendamento/{staticfiles,mediafiles,logs}

# Criar arquivo de configuração Django
echo "8. Criando configuração Django..."
sudo -u django tee /opt/s-agendamento/manage.py > /dev/null <<'EOF'
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

# Criar diretório core
sudo -u django mkdir -p /opt/s-agendamento/core

# Criar settings de produção
echo "9. Criando settings de produção..."
sudo -u django tee /opt/s-agendamento/core/__init__.py > /dev/null <<'EOF'
# Django settings
EOF

sudo -u django tee /opt/s-agendamento/core/settings_production_aws.py > /dev/null <<'EOF'
import os
from pathlib import Path

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = 'django-insecure-4minds-agendamento-2025-super-secret-key'

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = False

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
        'DIRS': [],
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
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'agendamento_db',
        'USER': 'agendamento_user',
        'PASSWORD': '4MindsAgendamento2025!SecureDB#Pass',
        'HOST': 's-agendamento-db.cgr24gyuwi3d.us-east-1.rds.amazonaws.com',
        'PORT': '5432',
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

# Criar wsgi.py
sudo -u django tee /opt/s-agendamento/core/wsgi.py > /dev/null <<'EOF'
import os
from django.core.wsgi import get_wsgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings_production_aws')
application = get_wsgi_application()
EOF

# Criar urls.py
sudo -u django tee /opt/s-agendamento/core/urls.py > /dev/null <<'EOF'
from django.contrib import admin
from django.urls import path
from django.http import HttpResponse

def home(request):
    return HttpResponse("""
    <html>
    <head><title>Sistema de Agendamento - 4Minds</title></head>
    <body>
        <h1>🚀 Sistema de Agendamento</h1>
        <p>Bem-vindo ao sistema de agendamento da 4Minds!</p>
        <p><a href="/admin/">Admin Django</a></p>
        <p><a href="/s_agendamentos/">Sistema de Agendamentos</a></p>
    </body>
    </html>
    """)

def s_agendamentos(request):
    return HttpResponse("""
    <html>
    <head><title>Sistema de Agendamentos</title></head>
    <body>
        <h1>📅 Sistema de Agendamentos</h1>
        <p>Funcionalidades do sistema de agendamento:</p>
        <ul>
            <li>Agendamento de consultas</li>
            <li>Gestão de clientes</li>
            <li>Controle financeiro</li>
            <li>Relatórios</li>
        </ul>
        <p><a href="/">Voltar ao início</a></p>
    </body>
    </html>
    """)

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', home, name='home'),
    path('s_agendamentos/', s_agendamentos, name='s_agendamentos'),
]
EOF

# Configurar Nginx
echo "10. Configurando Nginx..."
sudo tee /etc/nginx/sites-available/s-agendamento > /dev/null <<'EOF'
server {
    listen 80;
    server_name fourmindstech.com.br www.fourmindstech.com.br 34.202.149.24;

    # Redirecionar raiz para /s_agendamentos
    location = / {
        return 301 http://$server_name/s_agendamentos/;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    
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
    }
}
EOF

# Habilitar site
sudo ln -sf /etc/nginx/sites-available/s-agendamento /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Testar configuração Nginx
sudo nginx -t

# Configurar Supervisor
echo "11. Configurando Supervisor..."
sudo tee /etc/supervisor/conf.d/s-agendamento.conf > /dev/null <<'EOF'
[program:s-agendamento]
command=/opt/s-agendamento/venv/bin/gunicorn core.wsgi:application --bind unix:/opt/s-agendamento/s-agendamento.sock
directory=/opt/s-agendamento
user=django
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/opt/s-agendamento/logs/gunicorn.log
environment=DJANGO_SETTINGS_MODULE="core.settings_production_aws"
EOF

# Inicializar Django
echo "12. Inicializando Django..."
cd /opt/s-agendamento
sudo -u django /opt/s-agendamento/venv/bin/python manage.py migrate
sudo -u django /opt/s-agendamento/venv/bin/python manage.py collectstatic --noinput

# Criar superusuário
echo "13. Criando superusuário..."
echo "from django.contrib.auth import get_user_model; User = get_user_model(); User.objects.create_superuser('admin', 'admin@fourmindstech.com.br', 'admin123')" | sudo -u django /opt/s-agendamento/venv/bin/python manage.py shell

# Reiniciar serviços
echo "14. Reiniciando serviços..."
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start s-agendamento
sudo systemctl restart nginx

# Verificar status
echo "15. Verificando status dos serviços..."
sudo systemctl status nginx --no-pager
sudo supervisorctl status s-agendamento

echo ""
echo "=== DEPLOY CONCLUÍDO ==="
echo ""
echo "URLs para testar:"
echo "- http://34.202.149.24"
echo "- http://34.202.149.24/s_agendamentos/"
echo "- http://34.202.149.24/admin/"
echo "- http://fourmindstech.com.br"
echo ""
echo "Credenciais admin:"
echo "- Usuário: admin"
echo "- Senha: admin123"
echo ""
