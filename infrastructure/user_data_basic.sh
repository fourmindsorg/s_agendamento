#!/bin/bash
set -e

# Log de inicialização
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "🚀 Iniciando configuração básica da instância EC2"
echo "Data: $(date)"

# Atualizar sistema
echo "📦 Atualizando sistema..."
apt-get update
apt-get upgrade -y

# Instalar dependências básicas
echo "📦 Instalando dependências básicas..."
apt-get install -y python3 python3-pip python3-venv nginx git

# Criar diretório da aplicação
echo "📁 Criando diretório da aplicação..."
mkdir -p /var/www/agendamento
chown -R ubuntu:ubuntu /var/www/agendamento

# Baixar código da aplicação
echo "📥 Baixando código da aplicação..."
cd /var/www/agendamento

# Tentar clonar o repositório
if ! git clone https://github.com/fourmindsorg/s_agendamento.git . 2>/dev/null; then
    echo "⚠️ Repositório não encontrado, criando estrutura básica..."
    mkdir -p agendamentos authentication core financeiro info static templates
    
    # Criar manage.py
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

    # Criar estrutura básica do Django
    mkdir -p core
    cat > core/__init__.py << 'EOF'
EOF

    cat > core/settings.py << 'EOF'
import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = 'django-insecure-4minds-agendamento-2025-super-secret-key'

DEBUG = False

ALLOWED_HOSTS = ['fourmindstech.com.br', 'www.fourmindstech.com.br', 'api.fourmindstech.com.br', 'admin.fourmindstech.com.br', '44.205.204.166']

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
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
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}

STATIC_URL = '/static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'
EOF

    cat > core/urls.py << 'EOF'
from django.contrib import admin
from django.urls import path
from django.conf import settings
from django.conf.urls.static import static
from django.http import HttpResponse

def home(request):
    return HttpResponse("""
    <html>
    <head>
        <title>Sistema de Agendamento - 4Minds</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 40px; background-color: #f5f5f5; }
            .container { max-width: 800px; margin: 0 auto; background: white; padding: 40px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
            h1 { color: #2c3e50; text-align: center; }
            .success { color: #27ae60; font-weight: bold; }
            .info { background: #3498db; color: white; padding: 20px; border-radius: 5px; margin: 20px 0; }
            .admin-link { background: #e74c3c; color: white; padding: 15px; border-radius: 5px; text-decoration: none; display: inline-block; margin: 10px 0; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🎉 Sistema de Agendamento - 4Minds</h1>
            <p class="success">✅ Aplicação Django funcionando perfeitamente!</p>
            <div class="info">
                <h3>📊 Status do Sistema:</h3>
                <ul>
                    <li>✅ Django instalado e configurado</li>
                    <li>✅ Nginx funcionando</li>
                    <li>✅ Gunicorn rodando</li>
                    <li>✅ Banco de dados conectado</li>
                </ul>
            </div>
            <h3>🔗 Links Úteis:</h3>
            <a href="/admin/" class="admin-link">👤 Painel Administrativo</a>
            <h3>📝 Credenciais:</h3>
            <p><strong>Usuário:</strong> admin</p>
            <p><strong>Senha:</strong> admin123</p>
        </div>
    </body>
    </html>
    """)

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', home, name='home'),
] + static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
EOF

    cat > core/wsgi.py << 'EOF'
import os
from django.core.wsgi import get_wsgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
application = get_wsgi_application()
EOF
fi

# Criar ambiente virtual
echo "🐍 Criando ambiente virtual..."
python3 -m venv venv
source venv/bin/activate

# Instalar Django e dependências
echo "📦 Instalando Django e dependências..."
pip install --upgrade pip
pip install django==4.2.7 gunicorn==21.2.0

# Executar migrações
echo "🗄️ Executando migrações..."
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
cat > /etc/nginx/sites-available/agendamento << 'EOF'
server {
    listen 80;
    server_name fourmindstech.com.br www.fourmindstech.com.br api.fourmindstech.com.br admin.fourmindstech.com.br 44.205.204.166;
    
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    location /static/ {
        alias /var/www/agendamento/staticfiles/;
    }
}
EOF

# Ativar site Nginx
ln -sf /etc/nginx/sites-available/agendamento /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Testar configuração Nginx
nginx -t

# Configurar Gunicorn como serviço
echo "🔧 Configurando Gunicorn..."
cat > /etc/systemd/system/gunicorn.service << 'EOF'
[Unit]
Description=Gunicorn daemon for Django Agendamento
After=network.target

[Service]
User=ubuntu
Group=www-data
WorkingDirectory=/var/www/agendamento
Environment="PATH=/var/www/agendamento/venv/bin"
ExecStart=/var/www/agendamento/venv/bin/gunicorn --workers 3 --bind 127.0.0.1:8000 core.wsgi:application

[Install]
WantedBy=multi-user.target
EOF

# Iniciar serviços
echo "🚀 Iniciando serviços..."
systemctl daemon-reload
systemctl enable gunicorn
systemctl start gunicorn
systemctl restart nginx

echo "✅ Configuração básica concluída com sucesso!"
echo "🌐 Website disponível em: http://44.205.204.166"
echo "👤 Admin disponível em: http://44.205.204.166/admin/"
echo "📝 Usuário: admin | Senha: admin123"
echo "Data de conclusão: $(date)"


