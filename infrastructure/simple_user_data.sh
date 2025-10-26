#!/bin/bash
# User-data básico para testar

echo "=== INICIANDO DEPLOY SIMPLES ===" > /var/log/simple_deploy.log

# Atualizar sistema
apt update -y >> /var/log/simple_deploy.log 2>&1
apt install -y python3 python3-pip nginx >> /var/log/simple_deploy.log 2>&1

# Instalar Django
pip3 install django >> /var/log/simple_deploy.log 2>&1

# Criar projeto Django simples
mkdir -p /opt/django-app
cd /opt/django-app

# Criar manage.py
cat > manage.py << 'EOF'
#!/usr/bin/env python
import os
import sys
if __name__ == '__main__':
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'mysite.settings')
    from django.core.management import execute_from_command_line
    execute_from_command_line(sys.argv)
EOF

# Criar estrutura do projeto
mkdir -p mysite
cd mysite

# Criar __init__.py
touch __init__.py

# Criar settings.py
cat > settings.py << 'EOF'
import os
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SECRET_KEY = 'django-insecure-key'
DEBUG = False
ALLOWED_HOSTS = ['*']
INSTALLED_APPS = ['django.contrib.admin', 'django.contrib.auth', 'django.contrib.contenttypes', 'django.contrib.sessions', 'django.contrib.messages', 'django.contrib.staticfiles']
MIDDLEWARE = ['django.middleware.security.SecurityMiddleware', 'django.contrib.sessions.middleware.SessionMiddleware', 'django.middleware.common.CommonMiddleware', 'django.middleware.csrf.CsrfViewMiddleware', 'django.contrib.auth.middleware.AuthenticationMiddleware', 'django.contrib.messages.middleware.MessageMiddleware', 'django.middleware.clickjacking.XFrameOptionsMiddleware']
ROOT_URLCONF = 'mysite.urls'
TEMPLATES = [{'BACKEND': 'django.template.backends.django.DjangoTemplates', 'DIRS': [], 'APP_DIRS': True, 'OPTIONS': {'context_processors': ['django.template.context_processors.debug', 'django.template.context_processors.request', 'django.contrib.auth.context_processors.auth', 'django.contrib.messages.context_processors.messages']}}]
WSGI_APPLICATION = 'mysite.wsgi.application'
DATABASES = {'default': {'ENGINE': 'django.db.backends.sqlite3', 'NAME': os.path.join(BASE_DIR, 'db.sqlite3')}}
AUTH_PASSWORD_VALIDATORS = [{'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'}, {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'}, {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'}, {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'}]
LANGUAGE_CODE = 'pt-br'
TIME_ZONE = 'America/Sao_Paulo'
USE_I18N = True
USE_TZ = True
STATIC_URL = '/static/'
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'
EOF

# Criar urls.py
cat > urls.py << 'EOF'
from django.contrib import admin
from django.urls import path
from django.http import HttpResponse

def home(request):
    return HttpResponse("""
    <html><head><title>Sistema de Agendamento</title></head>
    <body>
        <h1>🚀 Sistema de Agendamento - 4Minds</h1>
        <p>Bem-vindo ao sistema de agendamento!</p>
        <p><a href="/admin/">Admin Django</a></p>
        <p><strong>Status:</strong> Sistema funcionando!</p>
    </body></html>
    """)

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', home),
]
EOF

# Criar wsgi.py
cat > wsgi.py << 'EOF'
import os
from django.core.wsgi import get_wsgi_application
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'mysite.settings')
application = get_wsgi_application()
EOF

# Inicializar Django
cd /opt/django-app
python3 manage.py migrate >> /var/log/simple_deploy.log 2>&1
echo "from django.contrib.auth import get_user_model; User = get_user_model(); User.objects.create_superuser('admin', 'admin@test.com', 'admin123')" | python3 manage.py shell >> /var/log/simple_deploy.log 2>&1

# Configurar Nginx
cat > /etc/nginx/sites-available/django << 'EOF'
server {
    listen 80;
    server_name _;
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

ln -sf /etc/nginx/sites-available/django /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Iniciar Django em background
cd /opt/django-app
nohup python3 manage.py runserver 0.0.0.0:8000 > /var/log/django.log 2>&1 &

# Reiniciar Nginx
systemctl restart nginx

# Testar
sleep 5
curl -I http://localhost >> /var/log/simple_deploy.log 2>&1

echo "=== DEPLOY SIMPLES CONCLUÍDO ===" >> /var/log/simple_deploy.log
echo "Sistema disponível em: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)" >> /var/log/simple_deploy.log
