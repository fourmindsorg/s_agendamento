#!/bin/bash
set -e

# Log de inicialização
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "🚀 Iniciando configuração robusta da instância EC2"
echo "Data: $(date)"

# Atualizar sistema
echo "📦 Atualizando sistema..."
apt-get update
apt-get upgrade -y

# Instalar dependências essenciais
echo "📦 Instalando dependências essenciais..."
apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    nginx \
    git \
    curl \
    wget \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release

# Instalar Node.js para build de assets
echo "📦 Instalando Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

# Instalar PostgreSQL client
echo "📦 Instalando PostgreSQL client..."
apt-get install -y postgresql-client

# Criar usuário para aplicação
echo "👤 Configurando usuário da aplicação..."
useradd -m -s /bin/bash django || true
usermod -aG www-data django

# Criar diretórios necessários
echo "📁 Criando diretórios..."
mkdir -p /var/www/agendamento
mkdir -p /var/log/django
mkdir -p /var/log/nginx
mkdir -p /etc/nginx/sites-available
mkdir -p /etc/nginx/sites-enabled

# Configurar permissões
chown -R django:django /var/www/agendamento
chown -R django:django /var/log/django

# Baixar código da aplicação
echo "📥 Baixando código da aplicação..."
cd /var/www/agendamento

# Tentar clonar o repositório
if ! git clone https://github.com/fourmindsorg/s_agendamento.git . 2>/dev/null; then
    echo "⚠️ Repositório não encontrado, criando estrutura básica..."
    mkdir -p agendamentos authentication core financeiro info static templates
    cat > manage.py << 'EOF'
#!/usr/bin/env python
"""Django's command-line utility for administrative tasks."""
import os
import sys

if __name__ == '__main__':
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
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
fi

# Criar ambiente virtual Python
echo "🐍 Criando ambiente virtual Python..."
python3 -m venv venv
source venv/bin/activate

# Atualizar pip
echo "📦 Atualizando pip..."
pip install --upgrade pip setuptools wheel

# Instalar dependências Python
echo "📦 Instalando dependências Python..."
pip install \
    django==4.2.7 \
    gunicorn==21.2.0 \
    psycopg2-binary==2.9.7 \
    python-decouple==3.8 \
    django-storages==1.14.2 \
    boto3==1.34.0 \
    pillow==10.1.0 \
    whitenoise==6.6.0

# Criar requirements.txt se não existir
if [ ! -f requirements.txt ]; then
    pip freeze > requirements.txt
fi

# Configurar variáveis de ambiente
echo "⚙️ Configurando variáveis de ambiente..."
cat > .env << EOF
DEBUG=False
SECRET_KEY=${secret_key}
ALLOWED_HOSTS=${domain_name},www.${domain_name},api.${domain_name},admin.${domain_name},44.205.204.166
DATABASE_URL=postgresql://${db_username}:${db_password}@${db_endpoint}/${db_name}
AWS_STORAGE_BUCKET_NAME=${static_bucket}
AWS_S3_REGION_NAME=us-east-1
STATIC_URL=/static/
MEDIA_URL=/media/
EOF

# Criar settings.py básico se não existir
if [ ! -f core/settings.py ]; then
    mkdir -p core
    cat > core/settings.py << 'EOF'
import os
from pathlib import Path
from decouple import config

BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = config('SECRET_KEY', default='django-insecure-default-key')

DEBUG = config('DEBUG', default=False, cast=bool)

ALLOWED_HOSTS = config('ALLOWED_HOSTS', default='localhost').split(',')

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'agendamentos',
    'authentication',
    'financeiro',
    'info',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
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

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': config('DATABASE_URL').split('/')[-1],
        'USER': config('DATABASE_URL').split('://')[1].split(':')[0],
        'PASSWORD': config('DATABASE_URL').split(':')[2].split('@')[0],
        'HOST': config('DATABASE_URL').split('@')[1].split(':')[0],
        'PORT': config('DATABASE_URL').split(':')[-1].split('/')[0],
    }
}

STATIC_URL = '/static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'

MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'
EOF
fi

# Criar urls.py básico se não existir
if [ ! -f core/urls.py ]; then
    cat > core/urls.py << 'EOF'
from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', include('agendamentos.urls')),
    path('auth/', include('authentication.urls')),
    path('financeiro/', include('financeiro.urls')),
    path('info/', include('info.urls')),
] + static(settings.STATIC_URL, document_root=settings.STATIC_ROOT) + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
EOF
fi

# Criar wsgi.py básico se não existir
if [ ! -f core/wsgi.py ]; then
    cat > core/wsgi.py << 'EOF'
import os
from django.core.wsgi import get_wsgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
application = get_wsgi_application()
EOF
fi

# Executar migrações do banco
echo "🗄️ Executando migrações do banco..."
python manage.py makemigrations
python manage.py migrate

# Criar superusuário
echo "👤 Criando superusuário..."
python manage.py shell << 'PYEOF'
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser('admin', 'admin@fourmindstech.com.br', 'admin123')
    print("Superusuário criado com sucesso!")
else:
    print("Superusuário já existe!")
PYEOF

# Coletar arquivos estáticos
echo "📦 Coletando arquivos estáticos..."
python manage.py collectstatic --noinput

# Configurar Nginx
echo "🌐 Configurando Nginx..."
cat > /etc/nginx/sites-available/agendamento << EOF
server {
    listen 80;
    server_name ${domain_name} www.${domain_name} api.${domain_name} admin.${domain_name} 44.205.204.166;
    
    client_max_body_size 20M;
    
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_read_timeout 300s;
        proxy_connect_timeout 300s;
    }
    
    location /static/ {
        alias /var/www/agendamento/staticfiles/;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
    
    location /media/ {
        alias /var/www/agendamento/media/;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
    
    # Logs
    access_log /var/log/nginx/agendamento_access.log;
    error_log /var/log/nginx/agendamento_error.log;
}
EOF

# Ativar site Nginx
ln -sf /etc/nginx/sites-available/agendamento /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Testar configuração Nginx
echo "🔍 Testando configuração Nginx..."
nginx -t

# Configurar Gunicorn como serviço
echo "🔧 Configurando Gunicorn como serviço..."
cat > /etc/systemd/system/gunicorn.service << EOF
[Unit]
Description=Gunicorn daemon for Django Agendamento
After=network.target

[Service]
User=ubuntu
Group=www-data
WorkingDirectory=/var/www/agendamento
Environment="PATH=/var/www/agendamento/venv/bin"
Environment="DJANGO_SETTINGS_MODULE=core.settings"
ExecStart=/var/www/agendamento/venv/bin/gunicorn --workers 3 --bind 127.0.0.1:8000 core.wsgi:application --timeout 120 --max-requests 1000 --max-requests-jitter 100
ExecReload=/bin/kill -s HUP \$MAINPID
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Recarregar systemd
systemctl daemon-reload

# Habilitar e iniciar serviços
echo "🚀 Iniciando serviços..."
systemctl enable nginx
systemctl enable gunicorn

systemctl restart nginx
systemctl start gunicorn

# Verificar status dos serviços
echo "📊 Verificando status dos serviços..."
systemctl status nginx --no-pager -l
systemctl status gunicorn --no-pager -l

# Log de conclusão
echo "✅ Configuração robusta concluída com sucesso!"
echo "🌐 Website disponível em: http://${domain_name}"
echo "🌐 Website via IP: http://44.205.204.166"
echo "👤 Admin disponível em: http://${domain_name}/admin/"
echo "📝 Usuário: admin | Senha: admin123"
echo "Data de conclusão: $(date)"


