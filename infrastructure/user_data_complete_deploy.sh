#!/bin/bash
# User-data script completo para deploy automático da aplicação Django

echo "=== INICIANDO DEPLOY AUTOMÁTICO COMPLETO ===" > /var/log/deploy.log

# Atualizar sistema
apt update -y >> /var/log/deploy.log 2>&1
apt install -y python3 python3-pip python3-venv nginx supervisor postgresql-client libpq-dev >> /var/log/deploy.log 2>&1

# Criar estrutura
mkdir -p /opt/s-agendamento/{staticfiles,mediafiles,logs}
adduser --system --group django >> /var/log/deploy.log 2>&1
chown -R django:django /opt/s-agendamento

# Ambiente virtual
sudo -u django python3 -m venv /opt/s-agendamento/venv
sudo -u django /opt/s-agendamento/venv/bin/pip install django gunicorn psycopg2-binary >> /var/log/deploy.log 2>&1

# Criar estrutura Django
sudo -u django mkdir -p /opt/s-agendamento/core

# Settings com PostgreSQL
sudo -u django tee /opt/s-agendamento/core/__init__.py > /dev/null <<'EOF'
EOF

sudo -u django tee /opt/s-agendamento/core/settings.py > /dev/null <<'EOF'
import os
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SECRET_KEY = 'django-insecure-4minds-agendamento-2025-super-secret-key'
DEBUG = False
ALLOWED_HOSTS = ['*']
INSTALLED_APPS = ['django.contrib.admin', 'django.contrib.auth', 'django.contrib.contenttypes', 'django.contrib.sessions', 'django.contrib.messages', 'django.contrib.staticfiles']
MIDDLEWARE = ['django.middleware.security.SecurityMiddleware', 'django.contrib.sessions.middleware.SessionMiddleware', 'django.middleware.common.CommonMiddleware', 'django.middleware.csrf.CsrfViewMiddleware', 'django.contrib.auth.middleware.AuthenticationMiddleware', 'django.contrib.messages.middleware.MessageMiddleware', 'django.middleware.clickjacking.XFrameOptionsMiddleware']
ROOT_URLCONF = 'core.urls'
TEMPLATES = [{'BACKEND': 'django.template.backends.django.DjangoTemplates', 'DIRS': [], 'APP_DIRS': True, 'OPTIONS': {'context_processors': ['django.template.context_processors.debug', 'django.template.context_processors.request', 'django.contrib.auth.context_processors.auth', 'django.contrib.messages.context_processors.messages']}}]
WSGI_APPLICATION = 'core.wsgi.application'
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
AUTH_PASSWORD_VALIDATORS = [{'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'}, {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'}, {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'}, {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'}]
LANGUAGE_CODE = 'pt-br'
TIME_ZONE = 'America/Sao_Paulo'
USE_I18N = True
USE_TZ = True
STATIC_URL = '/static/'
STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles')
MEDIA_URL = '/media/'
MEDIA_ROOT = os.path.join(BASE_DIR, 'mediafiles')
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'
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

# WSGI
sudo -u django tee /opt/s-agendamento/core/wsgi.py > /dev/null <<'EOF'
import os
from django.core.wsgi import get_wsgi_application
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
application = get_wsgi_application()
EOF

# URLs
sudo -u django tee /opt/s-agendamento/core/urls.py > /dev/null <<'EOF'
from django.contrib import admin
from django.urls import path
from django.http import HttpResponse

def home(request):
    return HttpResponse("""
    <html><head><title>Sistema de Agendamento - 4Minds</title></head>
    <body>
        <h1>🚀 Sistema de Agendamento - 4Minds</h1>
        <p>Bem-vindo ao sistema de agendamento da 4Minds!</p>
        <p><a href="/admin/">Admin Django</a></p>
        <p><a href="/s_agendamentos/">Sistema de Agendamentos</a></p>
        <p><strong>Status:</strong> Sistema funcionando em produção!</p>
    </body></html>
    """)

def s_agendamentos(request):
    return HttpResponse("""
    <html><head><title>Sistema de Agendamentos</title></head>
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
    </body></html>
    """)

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', home),
    path('s_agendamentos/', s_agendamentos),
]
EOF

# Manage.py
sudo -u django tee /opt/s-agendamento/manage.py > /dev/null <<'EOF'
#!/usr/bin/env python
import os
import sys
if __name__ == '__main__':
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
    from django.core.management import execute_from_command_line
    execute_from_command_line(sys.argv)
EOF

# Inicializar Django
cd /opt/s-agendamento
sudo -u django /opt/s-agendamento/venv/bin/python manage.py migrate >> /var/log/deploy.log 2>&1
sudo -u django /opt/s-agendamento/venv/bin/python manage.py collectstatic --noinput >> /var/log/deploy.log 2>&1
echo "from django.contrib.auth import get_user_model; User = get_user_model(); User.objects.create_superuser('admin', 'admin@fourmindstech.com.br', 'admin123')" | sudo -u django /opt/s-agendamento/venv/bin/python manage.py shell >> /var/log/deploy.log 2>&1

# Configurar Nginx
tee /etc/nginx/sites-available/s-agendamento > /dev/null <<'EOF'
server {
    listen 80;
    server_name fourmindstech.com.br www.fourmindstech.com.br _;

    # Redirecionar raiz para /s_agendamentos
    location = / {
        return 301 http://$server_name/s_agendamentos/;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location /static/ { alias /opt/s-agendamento/staticfiles/; }
    location /media/ { alias /opt/s-agendamento/mediafiles/; }
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

ln -sf /etc/nginx/sites-available/s-agendamento /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Configurar Gunicorn
tee /etc/supervisor/conf.d/s-agendamento.conf > /dev/null <<'EOF'
[program:s-agendamento]
command=/opt/s-agendamento/venv/bin/gunicorn core.wsgi:application --bind unix:/opt/s-agendamento/s-agendamento.sock
directory=/opt/s-agendamento
user=django
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/opt/s-agendamento/logs/gunicorn.log
environment=DJANGO_SETTINGS_MODULE="core.settings"
EOF

# Iniciar serviços
nginx -t && systemctl restart nginx >> /var/log/deploy.log 2>&1
supervisorctl reread >> /var/log/deploy.log 2>&1
supervisorctl update >> /var/log/deploy.log 2>&1
supervisorctl start s-agendamento >> /var/log/deploy.log 2>&1

# Testar se está funcionando
sleep 10
curl -I http://localhost >> /var/log/deploy.log 2>&1

echo "=== DEPLOY AUTOMÁTICO CONCLUÍDO ===" >> /var/log/deploy.log
echo "Sistema disponível em:" >> /var/log/deploy.log
echo "- http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)" >> /var/log/deploy.log
echo "- http://fourmindstech.com.br" >> /var/log/deploy.log
echo "Admin: admin/admin123" >> /var/log/deploy.log
