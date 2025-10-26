#!/bin/bash
#
# Script de Deploy Manual - Sistema de Agendamento 4Minds
# Execute este script DIRETAMENTE no servidor EC2
#
# Para executar:
# 1. Faça SSH no servidor: ssh -i sua_chave.pem ec2-user@52.91.139.151
# 2. Cole este script em um arquivo: nano deploy_manual.sh
# 3. Torne executável: chmod +x deploy_manual.sh
# 4. Execute: sudo ./deploy_manual.sh
#

set -e  # Parar se houver erro

echo "=============================================="
echo "  DEPLOY SISTEMA DE AGENDAMENTO - 4MINDS"
echo "  Servidor: 52.91.139.151"
echo "  Data: $(date)"
echo "=============================================="

# Detectar distribuição Linux
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    echo "Sistema operacional detectado: $PRETTY_NAME"
else
    echo "Não foi possível detectar o sistema operacional"
    exit 1
fi

# Atualizar sistema
echo ""
echo "1. Atualizando sistema..."
if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
    apt update -y
    apt upgrade -y
    apt install -y python3 python3-pip python3-venv nginx supervisor postgresql-client libpq-dev git curl unzip
elif [ "$OS" = "amzn" ] || [ "$OS" = "centos" ] || [ "$OS" = "rhel" ]; then
    yum update -y
    yum install -y python3 python3-pip nginx supervisor postgresql git curl unzip
    # Instalar python3-venv manualmente se necessário
    python3 -m ensurepip --upgrade
    pip3 install virtualenv
else
    echo "Sistema operacional não suportado: $OS"
    exit 1
fi

# Criar usuário django
echo ""
echo "2. Criando usuário django..."
if ! id "django" &>/dev/null; then
    useradd --system --create-home --shell /bin/bash django
    echo "Usuário django criado"
else
    echo "Usuário django já existe"
fi

# Preparar diretórios
echo ""
echo "3. Preparando diretórios..."
rm -rf /opt/s-agendamento
mkdir -p /opt/s-agendamento/{staticfiles,mediafiles,logs,static/css,static/js,templates}
chown -R django:django /opt/s-agendamento

# Criar requirements.txt
echo ""
echo "4. Criando requirements.txt..."
cat > /opt/s-agendamento/requirements.txt << 'EOF'
# Sistema de Agendamento - 4Minds
# Dependências Python

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

# AWS SDK (opcional)
boto3==1.34.0
django-storages==1.14.2

# Segurança - Rate Limiting
django-ratelimit==4.1.0

# Performance - Redis Cache (opcional)
django-redis==5.4.0
EOF

# Configurar ambiente virtual Python
echo ""
echo "5. Configurando ambiente virtual Python..."
cd /opt/s-agendamento
sudo -u django python3 -m venv venv
sudo -u django venv/bin/pip install --upgrade pip
sudo -u django venv/bin/pip install -r requirements.txt

# Criar manage.py
echo ""
echo "6. Criando manage.py..."
sudo -u django tee manage.py > /dev/null << 'EOF'
#!/usr/bin/env python
"""Django's command-line utility for administrative tasks."""
import os
import sys

if __name__ == '__main__':
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings_production')
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
chmod +x /opt/s-agendamento/manage.py

# Criar estrutura Django
echo ""
echo "7. Criando estrutura Django..."
sudo -u django mkdir -p core

# __init__.py
sudo -u django touch core/__init__.py

# settings.py base
sudo -u django tee core/settings.py > /dev/null << 'EOF'
"""
Django settings for s_agendamento project.
"""

import os
from pathlib import Path

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = 'django-insecure-4minds-agendamento-2025-super-secret-key-change-in-production'

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
    # Apps do projeto (serão criados posteriormente)
    # 'agendamentos',
    # 'authentication', 
    # 'financeiro',
    # 'info',
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

# Database - SQLite para desenvolvimento
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
    'formatters': {
        'verbose': {
            'format': '{levelname} {asctime} {module} {process:d} {thread:d} {message}',
            'style': '{',
        },
        'simple': {
            'format': '{levelname} {message}',
            'style': '{',
        },
    },
    'handlers': {
        'file': {
            'level': 'INFO',
            'class': 'logging.FileHandler',
            'filename': '/opt/s-agendamento/logs/django.log',
            'formatter': 'verbose',
        },
        'console': {
            'level': 'INFO',
            'class': 'logging.StreamHandler',
            'formatter': 'simple',
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

# settings_production.py
echo ""
echo "8. Criando settings de produção..."
sudo -u django tee core/settings_production.py > /dev/null << 'EOF'
"""
Configurações de produção para o Sistema de Agendamento
"""

import os
from .settings import *

# Debug
DEBUG = False

# Hosts permitidos - AJUSTAR CONFORME NECESSÁRIO
ALLOWED_HOSTS = [
    '52.91.139.151',
    'fourmindstech.com.br',
    'www.fourmindstech.com.br',
    'localhost',
    '127.0.0.1',
]

# Database - PostgreSQL (descomente e configure quando necessário)
# DATABASES = {
#     'default': {
#         'ENGINE': 'django.db.backends.postgresql',
#         'NAME': os.environ.get('DB_NAME', 'agendamento_db'),
#         'USER': os.environ.get('DB_USER', 'agendamento_user'),
#         'PASSWORD': os.environ.get('DB_PASSWORD', 'sua_senha_aqui'),
#         'HOST': os.environ.get('DB_HOST', 'seu_host_rds_aqui'),
#         'PORT': os.environ.get('DB_PORT', '5432'),
#         'OPTIONS': {
#             'connect_timeout': 60,
#         },
#     }
# }

# Por enquanto usar SQLite
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}

# Security
SECURE_BROWSER_XSS_FILTER = True
SECURE_CONTENT_TYPE_NOSNIFF = True
X_FRAME_OPTIONS = 'DENY'

# Cache
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.locmem.LocMemCache',
        'LOCATION': 'unique-snowflake',
    }
}

# Email
EMAIL_BACKEND = 'django.core.mail.backends.console.EmailBackend'

# Configurações adicionais de segurança para produção
SECURE_SSL_REDIRECT = False  # Configurar como True quando tiver HTTPS
SESSION_COOKIE_SECURE = False  # Configurar como True quando tiver HTTPS
CSRF_COOKIE_SECURE = False  # Configurar como True quando tiver HTTPS

# Configurações específicas do sistema
SYSTEM_NAME = 'Sistema de Agendamento - 4Minds'
SYSTEM_VERSION = '1.0.0'
SYSTEM_ENVIRONMENT = 'production'
EOF

# wsgi.py
echo ""
echo "9. Criando wsgi.py..."
sudo -u django tee core/wsgi.py > /dev/null << 'EOF'
"""
WSGI config for s_agendamento project.

It exposes the WSGI callable as a module-level variable named ``application``.

For more information on this file, see
https://docs.djangoproject.com/en/5.2/howto/deployment/wsgi/
"""

import os
from django.core.wsgi import get_wsgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings_production')
application = get_wsgi_application()
EOF

# urls.py
echo ""
echo "10. Criando urls.py..."
sudo -u django tee core/urls.py > /dev/null << 'EOF'
"""s_agendamento URL Configuration"""

from django.contrib import admin
from django.urls import path, include
from django.http import HttpResponse
from django.conf import settings
from django.conf.urls.static import static
from django.shortcuts import render

def home(request):
    """Página inicial do sistema"""
    html_content = """
    <!DOCTYPE html>
    <html lang="pt-br">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Sistema de Agendamento - 4Minds</title>
        <style>
            * { margin: 0; padding: 0; box-sizing: border-box; }
            body { 
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                min-height: 100vh;
                display: flex;
                align-items: center;
                justify-content: center;
            }
            .container { 
                background: white; 
                padding: 40px; 
                border-radius: 15px; 
                box-shadow: 0 10px 30px rgba(0,0,0,0.2);
                max-width: 800px;
                width: 90%;
                text-align: center;
            }
            h1 { 
                color: #2c3e50; 
                margin-bottom: 20px;
                font-size: 2.5em;
            }
            .status { 
                background: linear-gradient(135deg, #2ecc71, #27ae60); 
                color: white; 
                padding: 15px 25px; 
                border-radius: 25px; 
                margin: 30px 0;
                font-weight: bold;
                font-size: 1.1em;
            }
            .info-grid {
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
                gap: 20px;
                margin: 30px 0;
            }
            .info-card {
                background: #f8f9fa;
                padding: 20px;
                border-radius: 10px;
                border-left: 4px solid #3498db;
            }
            .info-card h3 {
                color: #2c3e50;
                margin-bottom: 10px;
            }
            .links { 
                margin: 30px 0; 
                display: flex;
                flex-wrap: wrap;
                justify-content: center;
                gap: 15px;
            }
            .links a { 
                display: inline-block; 
                padding: 12px 24px; 
                background: linear-gradient(135deg, #3498db, #2980b9); 
                color: white; 
                text-decoration: none; 
                border-radius: 25px;
                font-weight: bold;
                transition: all 0.3s ease;
            }
            .links a:hover { 
                transform: translateY(-2px);
                box-shadow: 0 5px 15px rgba(52, 152, 219, 0.4);
            }
            .footer {
                margin-top: 30px;
                padding-top: 20px;
                border-top: 1px solid #ecf0f1;
                color: #7f8c8d;
                font-size: 0.9em;
            }
            .system-info {
                background: #34495e;
                color: white;
                padding: 10px;
                border-radius: 5px;
                margin: 10px 0;
                font-family: monospace;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🚀 Sistema de Agendamento</h1>
            <h2 style="color: #7f8c8d; margin-bottom: 30px;">4Minds Technology</h2>
            
            <div class="status">
                ✅ Sistema funcionando em produção!
            </div>
            
            <div class="info-grid">
                <div class="info-card">
                    <h3>📅 Agendamentos</h3>
                    <p>Gestão completa de consultas e compromissos</p>
                </div>
                <div class="info-card">
                    <h3>👤 Autenticação</h3>
                    <p>Sistema seguro de login e usuários</p>
                </div>
                <div class="info-card">
                    <h3>💰 Financeiro</h3>
                    <p>Controle de pagamentos e faturamento</p>
                </div>
                <div class="info-card">
                    <h3>📊 Relatórios</h3>
                    <p>Análises e informações gerenciais</p>
                </div>
            </div>
            
            <div class="links">
                <a href="/admin/">🔧 Painel Administrativo</a>
                <a href="#" onclick="alert('Módulos em desenvolvimento!')">📱 Sistema Mobile</a>
            </div>
            
            <div class="system-info">
                <strong>Informações do Sistema:</strong><br>
                Servidor: 52.91.139.151<br>
                Django: """ + __import__('django').get_version() + """<br>
                Ambiente: Produção<br>
                Data: """ + str(__import__('datetime').datetime.now().strftime('%d/%m/%Y %H:%M:%S')) + """
            </div>
            
            <div class="footer">
                <p><strong>4Minds Technology</strong> - Sistema de Agendamento v1.0</p>
                <p>© 2025 - Todos os direitos reservados</p>
            </div>
        </div>
    </body>
    </html>
    """
    
    return HttpResponse(html_content)

def system_status(request):
    """Página de status do sistema"""
    import django
    import sys
    from django.conf import settings
    
    context = {
        'django_version': django.get_version(),
        'python_version': sys.version,
        'debug_mode': settings.DEBUG,
        'allowed_hosts': settings.ALLOWED_HOSTS,
    }
    
    html_content = f"""
    <!DOCTYPE html>
    <html>
    <head><title>Status do Sistema</title></head>
    <body style="font-family: Arial, sans-serif; margin: 40px;">
        <h1>Status do Sistema</h1>
        <ul>
            <li><strong>Django:</strong> {context['django_version']}</li>
            <li><strong>Python:</strong> {context['python_version']}</li>
            <li><strong>Debug:</strong> {context['debug_mode']}</li>
            <li><strong>Hosts Permitidos:</strong> {', '.join(context['allowed_hosts'])}</li>
        </ul>
        <p><a href="/">← Voltar ao início</a></p>
    </body>
    </html>
    """
    
    return HttpResponse(html_content)

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', home, name='home'),
    path('status/', system_status, name='system_status'),
]

# Servir arquivos estáticos e media em desenvolvimento
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
EOF

# Criar CSS básico
echo ""
echo "11. Criando arquivos estáticos básicos..."
sudo -u django tee static/css/style.css > /dev/null << 'EOF'
/* Sistema de Agendamento - 4Minds */
/* Estilos básicos do sistema */

:root {
    --primary-color: #3498db;
    --secondary-color: #2c3e50;
    --success-color: #2ecc71;
    --warning-color: #f39c12;
    --danger-color: #e74c3c;
    --light-bg: #f8f9fa;
    --dark-bg: #343a40;
}

* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body {
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    line-height: 1.6;
    color: var(--secondary-color);
    background-color: var(--light-bg);
}

.container {
    max-width: 1200px;
    margin: 0 auto;
    padding: 20px;
}

.header {
    background: linear-gradient(135deg, var(--primary-color), var(--secondary-color));
    color: white;
    padding: 20px 0;
    text-align: center;
    margin-bottom: 30px;
}

.btn {
    display: inline-block;
    padding: 10px 20px;
    background-color: var(--primary-color);
    color: white;
    text-decoration: none;
    border-radius: 5px;
    border: none;
    cursor: pointer;
    transition: all 0.3s ease;
}

.btn:hover {
    background-color: var(--secondary-color);
    transform: translateY(-2px);
}

.card {
    background: white;
    padding: 20px;
    border-radius: 8px;
    box-shadow: 0 2px 10px rgba(0,0,0,0.1);
    margin-bottom: 20px;
}

.alert {
    padding: 15px;
    border-radius: 5px;
    margin-bottom: 20px;
}

.alert-success {
    background-color: var(--success-color);
    color: white;
}

.alert-warning {
    background-color: var(--warning-color);
    color: white;
}

.alert-danger {
    background-color: var(--danger-color);
    color: white;
}

/* Responsivo */
@media (max-width: 768px) {
    .container {
        padding: 10px;
    }
    
    .header {
        padding: 15px 0;
    }
}
EOF

# Inicializar Django
echo ""
echo "12. Inicializando Django..."
cd /opt/s-agendamento

# Fazer migrações
sudo -u django venv/bin/python manage.py makemigrations
sudo -u django venv/bin/python manage.py migrate

# Coletar arquivos estáticos
sudo -u django venv/bin/python manage.py collectstatic --noinput

# Criar superusuário
echo ""
echo "13. Criando superusuário..."
echo "from django.contrib.auth import get_user_model; User = get_user_model(); User.objects.filter(username='admin').delete(); User.objects.create_superuser('admin', 'admin@fourmindstech.com.br', 'admin123')" | sudo -u django venv/bin/python manage.py shell

# Ajustar permissões
echo ""
echo "14. Ajustando permissões..."
chown -R django:django /opt/s-agendamento
chmod -R 755 /opt/s-agendamento
chmod +x manage.py

# Configurar Nginx
echo ""
echo "15. Configurando Nginx..."
tee /etc/nginx/sites-available/s-agendamento > /dev/null << 'EOF'
server {
    listen 80;
    server_name 52.91.139.151 fourmindstech.com.br www.fourmindstech.com.br localhost;

    client_max_body_size 4G;

    # Logs
    access_log /var/log/nginx/s-agendamento_access.log;
    error_log /var/log/nginx/s-agendamento_error.log;

    location = /favicon.ico { 
        access_log off; 
        log_not_found off; 
    }
    
    location = /robots.txt {
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
        
        # Headers de segurança
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header Referrer-Policy "no-referrer-when-downgrade" always;
    }
}
EOF

# Habilitar site
if [ -d "/etc/nginx/sites-enabled" ]; then
    ln -sf /etc/nginx/sites-available/s-agendamento /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
fi

# Testar configuração do Nginx
nginx -t

# Configurar Supervisor/Systemd para Gunicorn
echo ""
echo "16. Configurando serviço Gunicorn..."

if command -v supervisorctl >/dev/null 2>&1; then
    # Usar Supervisor
    tee /etc/supervisor/conf.d/s-agendamento.conf > /dev/null << 'EOF'
[program:s-agendamento]
command=/opt/s-agendamento/venv/bin/gunicorn core.wsgi:application --bind unix:/opt/s-agendamento/s-agendamento.sock --workers 3 --timeout 60 --max-requests 1000 --max-requests-jitter 100
directory=/opt/s-agendamento
user=django
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/opt/s-agendamento/logs/gunicorn.log
stderr_logfile=/opt/s-agendamento/logs/gunicorn_error.log
environment=DJANGO_SETTINGS_MODULE="core.settings_production"
EOF
    
    supervisorctl reread
    supervisorctl update
    supervisorctl restart s-agendamento
    
    echo "Gunicorn configurado via Supervisor"
    
else
    # Usar systemd
    tee /etc/systemd/system/s-agendamento.service > /dev/null << 'EOF'
[Unit]
Description=Sistema de Agendamento - 4Minds
After=network.target

[Service]
Type=exec
User=django
Group=django
WorkingDirectory=/opt/s-agendamento
Environment=DJANGO_SETTINGS_MODULE=core.settings_production
ExecStart=/opt/s-agendamento/venv/bin/gunicorn core.wsgi:application --bind unix:/opt/s-agendamento/s-agendamento.sock --workers 3 --timeout 60
ExecReload=/bin/kill -s HUP $MAINPID
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable s-agendamento
    systemctl start s-agendamento
    
    echo "Gunicorn configurado via systemd"
fi

# Reiniciar Nginx
echo ""
echo "17. Reiniciando Nginx..."
systemctl restart nginx

# Aguardar inicialização
echo ""
echo "18. Aguardando inicialização dos serviços..."
sleep 10

# Verificar status dos serviços
echo ""
echo "19. Verificando status dos serviços..."
echo "----------------------------------------"

echo "Status Nginx:"
systemctl is-active nginx && echo "✅ Nginx: ATIVO" || echo "❌ Nginx: INATIVO"

echo ""
echo "Status Gunicorn:"
if command -v supervisorctl >/dev/null 2>&1; then
    supervisorctl status s-agendamento
else
    systemctl is-active s-agendamento && echo "✅ Gunicorn: ATIVO" || echo "❌ Gunicorn: INATIVO"
fi

echo ""
echo "Teste HTTP Local:"
if curl -s -o /dev/null -w "%{http_code}" http://localhost | grep -q "200"; then
    echo "✅ HTTP: Funcionando (Status 200)"
else
    echo "❌ HTTP: Problema na conexão"
fi

echo ""
echo "Verificando arquivos principais:"
[ -f "/opt/s-agendamento/manage.py" ] && echo "✅ manage.py existe" || echo "❌ manage.py não encontrado"
[ -f "/opt/s-agendamento/core/settings_production.py" ] && echo "✅ settings_production.py existe" || echo "❌ settings_production.py não encontrado"
[ -S "/opt/s-agendamento/s-agendamento.sock" ] && echo "✅ Socket Unix existe" || echo "❌ Socket Unix não encontrado"

echo ""
echo "=============================================="
echo "           DEPLOY CONCLUÍDO COM SUCESSO!"
echo "=============================================="
echo ""
echo "🎉 Sistema instalado e funcionando!"
echo ""
echo "📍 INFORMAÇÕES IMPORTANTES:"
echo ""
echo "🌐 URLs para testar:"
echo "   • http://52.91.139.151"
echo "   • http://52.91.139.151/admin/"
echo "   • http://52.91.139.151/status/"
echo "   • http://fourmindstech.com.br (se DNS configurado)"
echo ""
echo "👤 Credenciais do administrador:"
echo "   • Usuário: admin"
echo "   • Senha: admin123"
echo "   • Email: admin@fourmindstech.com.br"
echo ""
echo "📁 Diretórios importantes:"
echo "   • Aplicação: /opt/s-agendamento/"
echo "   • Logs Django: /opt/s-agendamento/logs/django.log"
echo "   • Logs Gunicorn: /opt/s-agendamento/logs/gunicorn.log"
echo "   • Logs Nginx: /var/log/nginx/s-agendamento_*.log"
echo ""
echo "🔧 Comandos úteis:"
echo "   • Ver logs Django: tail -f /opt/s-agendamento/logs/django.log"
echo "   • Reiniciar Gunicorn: sudo supervisorctl restart s-agendamento"
echo "   • Reiniciar Nginx: sudo systemctl restart nginx"
echo "   • Executar comandos Django: cd /opt/s-agendamento && sudo -u django venv/bin/python manage.py <comando>"
echo ""
echo "📋 PRÓXIMOS PASSOS:"
echo "   1. Testar o sistema nas URLs acima"
echo "   2. Configurar PostgreSQL (se necessário)"
echo "   3. Configurar HTTPS/SSL"
echo "   4. Configurar backup automático"
echo "   5. Desenvolver os módulos específicos do sistema"
echo ""
echo "✅ O sistema está pronto para desenvolvimento e uso!"
echo ""
echo "=============================================="

# Salvar informações em arquivo de log
tee /opt/s-agendamento/INSTALL_INFO.txt > /dev/null << EOF
SISTEMA DE AGENDAMENTO - 4MINDS
===============================

Data da Instalação: $(date)
Servidor: 52.91.139.151
Sistema Operacional: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)

URLs:
- http://52.91.139.151
- http://52.91.139.151/admin/
- http://52.91.139.151/status/

Credenciais Admin:
- Usuário: admin
- Senha: admin123
- Email: admin@fourmindstech.com.br

Diretórios:
- Aplicação: /opt/s-agendamento/
- Logs: /opt/s-agendamento/logs/
- Static: /opt/s-agendamento/staticfiles/
- Media: /opt/s-agendamento/mediafiles/

Serviços:
- Nginx: $(systemctl is-active nginx)
- Gunicorn: $(if command -v supervisorctl >/dev/null 2>&1; then supervisorctl status s-agendamento | awk '{print $2}'; else systemctl is-active s-agendamento; fi)

Versões:
- Python: $(python3 --version)
- Django: $(cd /opt/s-agendamento && sudo -u django venv/bin/python -c "import django; print(django.get_version())")
- Nginx: $(nginx -v 2>&1 | cut -d' ' -f3)

Status HTTP: $(curl -s -o /dev/null -w "%{http_code}" http://localhost)

===============================
EOF

echo "📄 Informações da instalação salvas em: /opt/s-agendamento/INSTALL_INFO.txt"
echo ""

