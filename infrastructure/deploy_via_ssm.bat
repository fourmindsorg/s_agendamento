@echo off
echo === DEPLOY VIA AWS SSM ===

echo 1. Executando script de deploy no servidor...
aws ssm send-command --instance-ids "i-000e6aecf9ad53679" --document-name "AWS-RunShellScript" --parameters 'commands=["#!/bin/bash", "apt update -y", "apt install -y python3 python3-pip python3-venv nginx supervisor postgresql-client libpq-dev", "mkdir -p /opt/s-agendamento/{staticfiles,mediafiles,logs}", "adduser --system --group django", "chown -R django:django /opt/s-agendamento", "sudo -u django python3 -m venv /opt/s-agendamento/venv", "sudo -u django /opt/s-agendamento/venv/bin/pip install django gunicorn psycopg2-binary", "sudo -u django mkdir -p /opt/s-agendamento/core"]'

echo.
echo 2. Aguardando 60 segundos para instalação...
timeout /t 60 /nobreak

echo.
echo 3. Criando estrutura Django...
aws ssm send-command --instance-ids "i-000e6aecf9ad53679" --document-name "AWS-RunShellScript" --parameters 'commands=["#!/bin/bash", "sudo -u django tee /opt/s-agendamento/core/__init__.py > /dev/null <<EOF", "EOF", "sudo -u django tee /opt/s-agendamento/core/settings.py > /dev/null <<EOF", "import os", "BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))", "SECRET_KEY = \"django-insecure-key\"", "DEBUG = False", "ALLOWED_HOSTS = [\"*\"]", "INSTALLED_APPS = [\"django.contrib.admin\", \"django.contrib.auth\", \"django.contrib.contenttypes\", \"django.contrib.sessions\", \"django.contrib.messages\", \"django.contrib.staticfiles\"]", "MIDDLEWARE = [\"django.middleware.security.SecurityMiddleware\", \"django.contrib.sessions.middleware.SessionMiddleware\", \"django.middleware.common.CommonMiddleware\", \"django.middleware.csrf.CsrfViewMiddleware\", \"django.contrib.auth.middleware.AuthenticationMiddleware\", \"django.contrib.messages.middleware.MessageMiddleware\", \"django.middleware.clickjacking.XFrameOptionsMiddleware\"]", "ROOT_URLCONF = \"core.urls\"", "TEMPLATES = [{\"BACKEND\": \"django.template.backends.django.DjangoTemplates\", \"DIRS\": [], \"APP_DIRS\": True, \"OPTIONS\": {\"context_processors\": [\"django.template.context_processors.debug\", \"django.template.context_processors.request\", \"django.contrib.auth.context_processors.auth\", \"django.contrib.messages.context_processors.messages\"]}}]", "WSGI_APPLICATION = \"core.wsgi.application\"", "DATABASES = {\"default\": {\"ENGINE\": \"django.db.backends.sqlite3\", \"NAME\": os.path.join(BASE_DIR, \"db.sqlite3\")}}", "AUTH_PASSWORD_VALIDATORS = [{\"NAME\": \"django.contrib.auth.password_validation.UserAttributeSimilarityValidator\"}, {\"NAME\": \"django.contrib.auth.password_validation.MinimumLengthValidator\"}, {\"NAME\": \"django.contrib.auth.password_validation.CommonPasswordValidator\"}, {\"NAME\": \"django.contrib.auth.password_validation.NumericPasswordValidator\"}]", "LANGUAGE_CODE = \"pt-br\"", "TIME_ZONE = \"America/Sao_Paulo\"", "USE_I18N = True", "USE_TZ = True", "STATIC_URL = \"/static/\"", "STATIC_ROOT = os.path.join(BASE_DIR, \"staticfiles\")", "DEFAULT_AUTO_FIELD = \"django.db.models.BigAutoField\"", "EOF"]'

echo.
echo 4. Aguardando 30 segundos...
timeout /t 30 /nobreak

echo.
echo 5. Configurando Nginx e Gunicorn...
aws ssm send-command --instance-ids "i-000e6aecf9ad53679" --document-name "AWS-RunShellScript" --parameters 'commands=["#!/bin/bash", "sudo -u django tee /opt/s-agendamento/core/wsgi.py > /dev/null <<EOF", "import os", "from django.core.wsgi import get_wsgi_application", "os.environ.setdefault(\"DJANGO_SETTINGS_MODULE\", \"core.settings\")", "application = get_wsgi_application()", "EOF", "sudo -u django tee /opt/s-agendamento/core/urls.py > /dev/null <<EOF", "from django.contrib import admin", "from django.urls import path", "from django.http import HttpResponse", "def home(request):", "    return HttpResponse(\"<html><head><title>Sistema de Agendamento</title></head><body><h1>🚀 Sistema de Agendamento - 4Minds</h1><p>Bem-vindo!</p><p><a href=\"/admin/\">Admin Django</a></p><p><a href=\"/s_agendamentos/\">Sistema de Agendamentos</a></p></body></html>\")", "def s_agendamentos(request):", "    return HttpResponse(\"<html><head><title>Sistema de Agendamentos</title></head><body><h1>📅 Sistema de Agendamentos</h1><p>Funcionalidades:</p><ul><li>Agendamento de consultas</li><li>Gestão de clientes</li><li>Controle financeiro</li></ul><p><a href=\"/\">Voltar</a></p></body></html>\")", "urlpatterns = [", "    path(\"admin/\", admin.site.urls),", "    path(\"\", home),", "    path(\"s_agendamentos/\", s_agendamentos),", "]", "EOF", "sudo -u django tee /opt/s-agendamento/manage.py > /dev/null <<EOF", "#!/usr/bin/env python", "import os", "import sys", "if __name__ == \"__main__\":", "    os.environ.setdefault(\"DJANGO_SETTINGS_MODULE\", \"core.settings\")", "    from django.core.management import execute_from_command_line", "    execute_from_command_line(sys.argv)", "EOF"]'

echo.
echo 6. Aguardando 30 segundos...
timeout /t 30 /nobreak

echo.
echo 7. Inicializando Django e configurando serviços...
aws ssm send-command --instance-ids "i-000e6aecf9ad53679" --document-name "AWS-RunShellScript" --parameters 'commands=["#!/bin/bash", "cd /opt/s-agendamento", "sudo -u django /opt/s-agendamento/venv/bin/python manage.py migrate", "sudo -u django /opt/s-agendamento/venv/bin/python manage.py collectstatic --noinput", "echo \"from django.contrib.auth import get_user_model; User = get_user_model(); User.objects.create_superuser(\"admin\", \"admin@test.com\", \"admin123\")\" | sudo -u django /opt/s-agendamento/venv/bin/python manage.py shell", "tee /etc/nginx/sites-available/s-agendamento > /dev/null <<EOF", "server {", "    listen 80;", "    server_name _;", "    location = /favicon.ico { access_log off; log_not_found off; }", "    location /static/ { alias /opt/s-agendamento/staticfiles/; }", "    location /media/ { alias /opt/s-agendamento/mediafiles/; }", "    location / {", "        include proxy_params;", "        proxy_pass http://unix:/opt/s-agendamento/s-agendamento.sock;", "    }", "}", "EOF", "ln -sf /etc/nginx/sites-available/s-agendamento /etc/nginx/sites-enabled/", "rm -f /etc/nginx/sites-enabled/default", "tee /etc/supervisor/conf.d/s-agendamento.conf > /dev/null <<EOF", "[program:s-agendamento]", "command=/opt/s-agendamento/venv/bin/gunicorn core.wsgi:application --bind unix:/opt/s-agendamento/s-agendamento.sock", "directory=/opt/s-agendamento", "user=django", "autostart=true", "autorestart=true", "redirect_stderr=true", "stdout_logfile=/opt/s-agendamento/logs/gunicorn.log", "EOF", "nginx -t && systemctl restart nginx", "supervisorctl reread", "supervisorctl update", "supervisorctl start s-agendamento"]'

echo.
echo 8. Aguardando 60 segundos para finalizar...
timeout /t 60 /nobreak

echo.
echo 9. Verificando status dos serviços...
aws ssm send-command --instance-ids "i-000e6aecf9ad53679" --document-name "AWS-RunShellScript" --parameters 'commands=["systemctl status nginx --no-pager", "supervisorctl status s-agendamento", "curl -I http://localhost"]'

echo.
echo === DEPLOY VIA SSM CONCLUÍDO ===
echo.
echo Teste o sistema em:
echo - http://34.202.149.24
echo - http://34.202.149.24/admin (admin/admin123)
echo - http://fourmindstech.com.br
echo.
pause
