@echo off
echo === EXECUTANDO DEPLOY COMPLETO COM CLONE NO EC2 ===
echo.

set INSTANCE_ID=i-0077873407e4114b1
set IP_ADDRESS=52.91.139.151

echo Servidor: %INSTANCE_ID% (IP: %IP_ADDRESS%)
echo.

echo 1. Verificando conectividade com a instância...
aws ssm describe-instance-information --filters "Key=InstanceIds,Values=%INSTANCE_ID%" --query "InstanceInformationList[0].PingStatus" --output text

if errorlevel 1 (
    echo ERRO: Não foi possível conectar com a instância %INSTANCE_ID%
    echo Verifique se:
    echo - A instância está rodando
    echo - O SSM Agent está instalado e funcionando
    echo - Suas credenciais AWS estão configuradas
    pause
    exit /b 1
)

echo.
echo 2. Enviando script de deploy para o servidor...

rem Enviar o script de deploy
aws ssm send-command ^
    --instance-ids "%INSTANCE_ID%" ^
    --document-name "AWS-RunShellScript" ^
    --comment "Deploy completo do sistema s_agendamento" ^
    --parameters 'commands=["#!/bin/bash","echo \"=== INICIANDO DEPLOY COMPLETO ===\"","# Atualizar sistema","apt update -y","apt upgrade -y","# Instalar dependências","apt install -y python3 python3-pip python3-venv nginx supervisor postgresql-client libpq-dev git curl unzip","# Criar usuário django","adduser --system --group django","# Preparar diretórios","rm -rf /opt/s-agendamento","mkdir -p /opt/s-agendamento/{staticfiles,mediafiles,logs}","chown -R django:django /opt/s-agendamento","echo \"=== DEPENDÊNCIAS INSTALADAS ===\" > /var/log/deploy_progress.log"]' ^
    --output text

if errorlevel 1 (
    echo ERRO: Falha ao enviar comandos iniciais
    pause
    exit /b 1
)

echo.
echo 3. Aguardando instalação das dependências (120 segundos)...
timeout /t 120 /nobreak

echo.
echo 4. Configurando ambiente Python e criando aplicação...

aws ssm send-command ^
    --instance-ids "%INSTANCE_ID%" ^
    --document-name "AWS-RunShellScript" ^
    --comment "Configuração do ambiente Python" ^
    --parameters 'commands=["#!/bin/bash","cd /opt/s-agendamento","# Criar ambiente virtual","sudo -u django python3 -m venv venv","# Criar requirements.txt","sudo -u django tee requirements.txt > /dev/null <<\"EOF\"","Django==5.2.6","psycopg2-binary==2.9.9","gunicorn==21.2.0","whitenoise==6.6.0","python-dotenv==1.0.0","requests==2.31.0","boto3==1.34.0","django-storages==1.14.2","django-ratelimit==4.1.0","django-redis==5.4.0","EOF","# Instalar dependências Python","sudo -u django venv/bin/pip install --upgrade pip","sudo -u django venv/bin/pip install -r requirements.txt","echo \"=== PYTHON CONFIGURADO ===\" >> /var/log/deploy_progress.log"]' ^
    --output text

echo.
echo 5. Aguardando instalação Python (90 segundos)...
timeout /t 90 /nobreak

echo.
echo 6. Criando estrutura Django...

aws ssm send-command ^
    --instance-ids "%INSTANCE_ID%" ^
    --document-name "AWS-RunShellScript" ^
    --comment "Criação da estrutura Django" ^
    --parameters 'commands=["#!/bin/bash","cd /opt/s-agendamento","# Criar manage.py","sudo -u django tee manage.py > /dev/null <<\"EOF\"","#!/usr/bin/env python","import os","import sys","if __name__ == \"__main__\":","    os.environ.setdefault(\"DJANGO_SETTINGS_MODULE\", \"core.settings_production_aws\")","    try:","        from django.core.management import execute_from_command_line","    except ImportError as exc:","        raise ImportError(\"Couldn\"t import Django.\") from exc","    execute_from_command_line(sys.argv)","EOF","# Criar diretório core","sudo -u django mkdir -p core","# Criar __init__.py","sudo -u django touch core/__init__.py","echo \"=== ESTRUTURA DJANGO CRIADA ===\" >> /var/log/deploy_progress.log"]' ^
    --output text

echo.
echo 7. Aguardando criação da estrutura (30 segundos)...
timeout /t 30 /nobreak

echo.
echo 8. Configurando settings do Django...

aws ssm send-command ^
    --instance-ids "%INSTANCE_ID%" ^
    --document-name "AWS-RunShellScript" ^
    --comment "Configuração do Django settings" ^
    --parameters 'commands=["#!/bin/bash","cd /opt/s-agendamento","# Criar settings base","sudo -u django tee core/settings.py > /dev/null <<\"EOF\"","import os","from pathlib import Path","BASE_DIR = Path(__file__).resolve().parent.parent","SECRET_KEY = \"django-insecure-4minds-agendamento-2025-super-secret-key\"","DEBUG = True","ALLOWED_HOSTS = [\"*\"]","INSTALLED_APPS = [\"django.contrib.admin\", \"django.contrib.auth\", \"django.contrib.contenttypes\", \"django.contrib.sessions\", \"django.contrib.messages\", \"django.contrib.staticfiles\", \"whitenoise.runserver_nostatic\"]","MIDDLEWARE = [\"django.middleware.security.SecurityMiddleware\", \"whitenoise.middleware.WhiteNoiseMiddleware\", \"django.contrib.sessions.middleware.SessionMiddleware\", \"django.middleware.common.CommonMiddleware\", \"django.middleware.csrf.CsrfViewMiddleware\", \"django.contrib.auth.middleware.AuthenticationMiddleware\", \"django.contrib.messages.middleware.MessageMiddleware\", \"django.middleware.clickjacking.XFrameOptionsMiddleware\"]","ROOT_URLCONF = \"core.urls\"","TEMPLATES = [{\"BACKEND\": \"django.template.backends.django.DjangoTemplates\", \"DIRS\": [BASE_DIR / \"templates\"], \"APP_DIRS\": True, \"OPTIONS\": {\"context_processors\": [\"django.template.context_processors.debug\", \"django.template.context_processors.request\", \"django.contrib.auth.context_processors.auth\", \"django.contrib.messages.context_processors.messages\"]}}]","WSGI_APPLICATION = \"core.wsgi.application\"","DATABASES = {\"default\": {\"ENGINE\": \"django.db.backends.sqlite3\", \"NAME\": BASE_DIR / \"db.sqlite3\"}}","AUTH_PASSWORD_VALIDATORS = [{\"NAME\": \"django.contrib.auth.password_validation.UserAttributeSimilarityValidator\"}, {\"NAME\": \"django.contrib.auth.password_validation.MinimumLengthValidator\"}, {\"NAME\": \"django.contrib.auth.password_validation.CommonPasswordValidator\"}, {\"NAME\": \"django.contrib.auth.password_validation.NumericPasswordValidator\"}]","LANGUAGE_CODE = \"pt-br\"","TIME_ZONE = \"America/Sao_Paulo\"","USE_I18N = True","USE_TZ = True","STATIC_URL = \"/static/\"","STATIC_ROOT = BASE_DIR / \"staticfiles\"","STATICFILES_DIRS = [BASE_DIR / \"static\"]","MEDIA_URL = \"/media/\"","MEDIA_ROOT = BASE_DIR / \"mediafiles\"","DEFAULT_AUTO_FIELD = \"django.db.models.BigAutoField\"","LOGGING = {\"version\": 1, \"disable_existing_loggers\": False, \"handlers\": {\"file\": {\"level\": \"INFO\", \"class\": \"logging.FileHandler\", \"filename\": \"/opt/s-agendamento/logs/django.log\"}, \"console\": {\"level\": \"INFO\", \"class\": \"logging.StreamHandler\"}}, \"root\": {\"handlers\": [\"file\", \"console\"], \"level\": \"INFO\"}, \"loggers\": {\"django\": {\"handlers\": [\"file\", \"console\"], \"level\": \"INFO\", \"propagate\": False}}}","EOF","echo \"=== SETTINGS CONFIGURADO ===\" >> /var/log/deploy_progress.log"]' ^
    --output text

echo.
echo 9. Aguardando configuração settings (30 segundos)...
timeout /t 30 /nobreak

echo.
echo 10. Criando settings de produção...

aws ssm send-command ^
    --instance-ids "%INSTANCE_ID%" ^
    --document-name "AWS-RunShellScript" ^
    --comment "Settings de produção" ^
    --parameters 'commands=["#!/bin/bash","cd /opt/s-agendamento","# Criar settings de produção","sudo -u django tee core/settings_production_aws.py > /dev/null <<\"EOF\"","from .settings import *","DEBUG = False","ALLOWED_HOSTS = [\"52.91.139.151\", \"fourmindstech.com.br\", \"www.fourmindstech.com.br\", \"localhost\", \"127.0.0.1\"]","DATABASES = {\"default\": {\"ENGINE\": \"django.db.backends.postgresql\", \"NAME\": \"agendamento_db\", \"USER\": \"agendamento_user\", \"PASSWORD\": \"4MindsAgendamento2025!SecureDB#Pass\", \"HOST\": \"s-agendamento-db.cgr24gyuwi3d.us-east-1.rds.amazonaws.com\", \"PORT\": \"5432\", \"OPTIONS\": {\"connect_timeout\": 60}}}","SECURE_BROWSER_XSS_FILTER = True","SECURE_CONTENT_TYPE_NOSNIFF = True","X_FRAME_OPTIONS = \"DENY\"","CACHES = {\"default\": {\"BACKEND\": \"django.core.cache.backends.locmem.LocMemCache\", \"LOCATION\": \"unique-snowflake\"}}","EMAIL_BACKEND = \"django.core.mail.backends.console.EmailBackend\"","EOF","echo \"=== PRODUÇÃO CONFIGURADA ===\" >> /var/log/deploy_progress.log"]' ^
    --output text

echo.
echo 11. Criando WSGI e URLs...

aws ssm send-command ^
    --instance-ids "%INSTANCE_ID%" ^
    --document-name "AWS-RunShellScript" ^
    --comment "WSGI e URLs" ^
    --parameters 'commands=["#!/bin/bash","cd /opt/s-agendamento","# Criar wsgi.py","sudo -u django tee core/wsgi.py > /dev/null <<\"EOF\"","import os","from django.core.wsgi import get_wsgi_application","os.environ.setdefault(\"DJANGO_SETTINGS_MODULE\", \"core.settings_production_aws\")","application = get_wsgi_application()","EOF","# Criar urls.py","sudo -u django tee core/urls.py > /dev/null <<\"EOF\"","from django.contrib import admin","from django.urls import path","from django.http import HttpResponse","def home(request):","    return HttpResponse(\"\"\"<!DOCTYPE html><html><head><title>Sistema de Agendamento - 4Minds</title><meta charset=\"utf-8\"><style>body{font-family:Arial,sans-serif;margin:40px;background:#f5f5f5}.container{background:white;padding:30px;border-radius:8px;box-shadow:0 2px 10px rgba(0,0,0,0.1)}h1{color:#2c3e50}.links a{display:inline-block;margin:10px 15px 10px 0;padding:10px 20px;background:#3498db;color:white;text-decoration:none;border-radius:5px}.status{background:#2ecc71;color:white;padding:10px;border-radius:5px;margin:20px 0}</style></head><body><div class=\"container\"><h1>🚀 Sistema de Agendamento - 4Minds</h1><div class=\"status\">✅ Sistema funcionando em produção!</div><p>Bem-vindo ao sistema de agendamento da 4Minds!</p><div class=\"links\"><a href=\"/admin/\">🔧 Admin Django</a></div><p><small>IP do servidor: 52.91.139.151</small></p></div></body></html>\"\"\")","urlpatterns = [path(\"admin/\", admin.site.urls), path(\"\", home, name=\"home\")]","EOF","echo \"=== WSGI E URLS CRIADOS ===\" >> /var/log/deploy_progress.log"]' ^
    --output text

echo.
echo 12. Aguardando criação WSGI/URLs (30 segundos)...
timeout /t 30 /nobreak

echo.
echo 13. Inicializando Django...

aws ssm send-command ^
    --instance-ids "%INSTANCE_ID%" ^
    --document-name "AWS-RunShellScript" ^
    --comment "Inicialização do Django" ^
    --parameters 'commands=["#!/bin/bash","cd /opt/s-agendamento","# Criar diretório static","sudo -u django mkdir -p static/css","sudo -u django echo \"body{font-family:Arial,sans-serif;margin:0;padding:0;background-color:#f8f9fa}\" > static/css/style.css","# Fazer migrações","sudo -u django venv/bin/python manage.py makemigrations","sudo -u django venv/bin/python manage.py migrate","# Coletar arquivos estáticos","sudo -u django venv/bin/python manage.py collectstatic --noinput","# Criar superusuário","echo \"from django.contrib.auth import get_user_model; User = get_user_model(); User.objects.filter(username=\"admin\").delete(); User.objects.create_superuser(\"admin\", \"admin@fourmindstech.com.br\", \"admin123\")\" | sudo -u django venv/bin/python manage.py shell","# Ajustar permissões","chown -R django:django /opt/s-agendamento","chmod -R 755 /opt/s-agendamento","chmod +x manage.py","echo \"=== DJANGO INICIALIZADO ===\" >> /var/log/deploy_progress.log"]' ^
    --output text

echo.
echo 14. Aguardando inicialização Django (60 segundos)...
timeout /t 60 /nobreak

echo.
echo 15. Configurando Nginx...

aws ssm send-command ^
    --instance-ids "%INSTANCE_ID%" ^
    --document-name "AWS-RunShellScript" ^
    --comment "Configuração do Nginx" ^
    --parameters 'commands=["#!/bin/bash","# Configurar Nginx","tee /etc/nginx/sites-available/s-agendamento > /dev/null <<\"EOF\"","server {","    listen 80;","    server_name 52.91.139.151 fourmindstech.com.br www.fourmindstech.com.br;","    client_max_body_size 4G;","    location = /favicon.ico { access_log off; log_not_found off; }","    location /static/ {","        alias /opt/s-agendamento/staticfiles/;","        expires 1y;","        add_header Cache-Control \"public, immutable\";","    }","    location /media/ {","        alias /opt/s-agendamento/mediafiles/;","        expires 1y;","        add_header Cache-Control \"public, immutable\";","    }","    location / {","        include proxy_params;","        proxy_pass http://unix:/opt/s-agendamento/s-agendamento.sock;","        proxy_set_header Host $host;","        proxy_set_header X-Real-IP $remote_addr;","        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;","        proxy_set_header X-Forwarded-Proto $scheme;","        proxy_connect_timeout 60s;","        proxy_send_timeout 60s;","        proxy_read_timeout 60s;","    }","}","EOF","# Habilitar site","ln -sf /etc/nginx/sites-available/s-agendamento /etc/nginx/sites-enabled/","rm -f /etc/nginx/sites-enabled/default","# Testar configuração","nginx -t","echo \"=== NGINX CONFIGURADO ===\" >> /var/log/deploy_progress.log"]' ^
    --output text

echo.
echo 16. Configurando Supervisor...

aws ssm send-command ^
    --instance-ids "%INSTANCE_ID%" ^
    --document-name "AWS-RunShellScript" ^
    --comment "Configuração do Supervisor" ^
    --parameters 'commands=["#!/bin/bash","# Configurar Supervisor","tee /etc/supervisor/conf.d/s-agendamento.conf > /dev/null <<\"EOF\"","[program:s-agendamento]","command=/opt/s-agendamento/venv/bin/gunicorn core.wsgi:application --bind unix:/opt/s-agendamento/s-agendamento.sock --workers 3 --timeout 60","directory=/opt/s-agendamento","user=django","autostart=true","autorestart=true","redirect_stderr=true","stdout_logfile=/opt/s-agendamento/logs/gunicorn.log","stderr_logfile=/opt/s-agendamento/logs/gunicorn_error.log","environment=DJANGO_SETTINGS_MODULE=\"core.settings_production_aws\"","EOF","echo \"=== SUPERVISOR CONFIGURADO ===\" >> /var/log/deploy_progress.log"]' ^
    --output text

echo.
echo 17. Aguardando configuração serviços (30 segundos)...
timeout /t 30 /nobreak

echo.
echo 18. Iniciando serviços...

aws ssm send-command ^
    --instance-ids "%INSTANCE_ID%" ^
    --document-name "AWS-RunShellScript" ^
    --comment "Inicialização dos serviços" ^
    --parameters 'commands=["#!/bin/bash","# Reiniciar serviços","supervisorctl reread","supervisorctl update","supervisorctl restart s-agendamento","systemctl restart nginx","# Aguardar inicialização","sleep 10","# Verificar status","echo \"=== STATUS DOS SERVIÇOS ===\" >> /var/log/deploy_progress.log","systemctl status nginx --no-pager --lines=5 >> /var/log/deploy_progress.log","supervisorctl status s-agendamento >> /var/log/deploy_progress.log","# Teste HTTP","curl -I http://localhost >> /var/log/deploy_progress.log 2>&1","echo \"=== DEPLOY CONCLUÍDO ===\" >> /var/log/deploy_progress.log"]' ^
    --output text

echo.
echo 19. Aguardando inicialização final (45 segundos)...
timeout /t 45 /nobreak

echo.
echo 20. Verificando resultado final...

aws ssm send-command ^
    --instance-ids "%INSTANCE_ID%" ^
    --document-name "AWS-RunShellScript" ^
    --comment "Verificação final" ^
    --parameters 'commands=["#!/bin/bash","echo \"=== RELATÓRIO FINAL ===\"","echo \"Data/Hora: $(date)\"","echo \"Servidor: 52.91.139.151\"","echo \"\"","echo \"Status Nginx:\"","systemctl is-active nginx","echo \"\"","echo \"Status Gunicorn:\"","supervisorctl status s-agendamento","echo \"\"","echo \"Teste HTTP:\"","curl -s -o /dev/null -w \"HTTP Status: %{http_code}\\nTempo resposta: %{time_total}s\\n\" http://localhost","echo \"\"","echo \"Arquivos principais:\"","ls -la /opt/s-agendamento/manage.py","ls -la /opt/s-agendamento/core/settings_production_aws.py","echo \"\"","echo \"URLs para testar:\"","echo \"- http://52.91.139.151\"","echo \"- http://52.91.139.151/admin/\"","echo \"- http://fourmindstech.com.br\"","echo \"\"","echo \"Credenciais admin:\"","echo \"- Usuário: admin\"","echo \"- Senha: admin123\"","echo \"\"","echo \"Logs importantes:\"","echo \"- Django: /opt/s-agendamento/logs/django.log\"","echo \"- Gunicorn: /opt/s-agendamento/logs/gunicorn.log\"","echo \"- Deploy: /var/log/deploy_progress.log\"","echo \"\"","echo \"=== FIM DO RELATÓRIO ===\""]' ^
    --output text

echo.
echo =====================================================
echo           DEPLOY EXECUTADO COM SUCESSO!
echo =====================================================
echo.
echo Servidor: %IP_ADDRESS% (%INSTANCE_ID%)
echo.
echo URLs para testar:
echo - http://%IP_ADDRESS%
echo - http://%IP_ADDRESS%/admin/
echo - http://fourmindstech.com.br
echo.
echo Credenciais do admin:
echo - Usuario: admin
echo - Senha: admin123
echo.
echo Para verificar o status completo, execute:
echo aws ssm start-session --target %INSTANCE_ID%
echo.
echo Para ver os logs de deploy:
echo aws ssm send-command --instance-ids %INSTANCE_ID% --document-name "AWS-RunShellScript" --parameters 'commands=["cat /var/log/deploy_progress.log"]'
echo.
pause

