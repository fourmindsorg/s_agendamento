#!/bin/bash
# Script para criar arquivo .env em produção
# Uso: sudo bash criar_env_producao.sh

set -e

echo "=========================================="
echo "  Criar arquivo .env para produção"
echo "=========================================="
echo ""

# Verificar se está rodando como root ou com sudo
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Este script precisa ser executado com sudo"
    echo "   Uso: sudo bash criar_env_producao.sh"
    exit 1
fi

# Diretório do projeto
PROJECT_DIR="/opt/s-agendamento"
ENV_FILE="$PROJECT_DIR/.env"

# Verificar se o diretório existe
if [ ! -d "$PROJECT_DIR" ]; then
    echo "❌ Diretório $PROJECT_DIR não encontrado!"
    exit 1
fi

# Verificar se .env já existe
if [ -f "$ENV_FILE" ]; then
    echo "⚠️  Arquivo .env já existe em $ENV_FILE"
    read -p "Deseja sobrescrever? (s/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        echo "Operação cancelada."
        exit 0
    fi
    # Backup do arquivo existente
    cp "$ENV_FILE" "$ENV_FILE.backup.$(date +%Y%m%d_%H%M%S)"
    echo "✅ Backup criado: $ENV_FILE.backup.$(date +%Y%m%d_%H%M%S)"
fi

# Gerar SECRET_KEY
echo "🔑 Gerando SECRET_KEY..."
SECRET_KEY=$(cd "$PROJECT_DIR" && source venv/bin/activate 2>/dev/null || source .venv/bin/activate 2>/dev/null; python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())" 2>/dev/null || echo "CHANGE_ME_GENERATE_A_SECRET_KEY")

# Detectar usuário do Gunicorn
GUNICORN_USER=$(ps aux | grep -E 'gunicorn.*s-agendamento' | grep -v grep | awk '{print $1}' | head -1)
if [ -z "$GUNICORN_USER" ]; then
    # Tentar detectar do systemd
    if [ -f "/etc/systemd/system/s-agendamento.service" ]; then
        GUNICORN_USER=$(grep "^User=" /etc/systemd/system/s-agendamento.service | cut -d'=' -f2)
    fi
    if [ -z "$GUNICORN_USER" ]; then
        GUNICORN_USER="ubuntu"
    fi
fi

echo "📝 Usuário do Gunicorn detectado: $GUNICORN_USER"
echo ""

# Coletar informações
echo "Por favor, forneça as seguintes informações:"
echo ""

read -p "ASAAS_API_KEY (formato: \$aact_prod_...): " ASAAS_API_KEY
if [ -z "$ASAAS_API_KEY" ]; then
    echo "⚠️  ASAAS_API_KEY não fornecida. Configure manualmente depois."
    ASAAS_API_KEY="CHANGE_ME_ASAAS_API_KEY"
fi

read -p "DB_NAME [s_agendamento]: " DB_NAME
DB_NAME=${DB_NAME:-s_agendamento}

read -p "DB_USER [postgres]: " DB_USER
DB_USER=${DB_USER:-postgres}

read -sp "DB_PASSWORD: " DB_PASSWORD
echo ""
if [ -z "$DB_PASSWORD" ]; then
    echo "⚠️  DB_PASSWORD não fornecida."
    DB_PASSWORD="CHANGE_ME_DB_PASSWORD"
fi

read -p "DB_HOST [localhost]: " DB_HOST
DB_HOST=${DB_HOST:-localhost}

read -p "DB_PORT [5432]: " DB_PORT
DB_PORT=${DB_PORT:-5432}

read -p "ALLOWED_HOSTS [fourmindstech.com.br,www.fourmindstech.com.br]: " ALLOWED_HOSTS
ALLOWED_HOSTS=${ALLOWED_HOSTS:-fourmindstech.com.br,www.fourmindstech.com.br}

# Criar arquivo .env
echo ""
echo "📝 Criando arquivo .env..."

cat > "$ENV_FILE" << EOF
# Django - Configuração de Produção
SECRET_KEY=$SECRET_KEY
DEBUG=False
ALLOWED_HOSTS=$ALLOWED_HOSTS

# Database - PostgreSQL
DB_NAME=$DB_NAME
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
DB_HOST=$DB_HOST
DB_PORT=$DB_PORT

# Asaas - PRODUÇÃO
ASAAS_API_KEY=$ASAAS_API_KEY
ASAAS_ENV=production
ASAAS_ENABLED=True

# Email (configure conforme necessário)
# EMAIL_HOST=smtp.gmail.com
# EMAIL_PORT=587
# EMAIL_USE_TLS=True
# EMAIL_HOST_USER=seu-email@gmail.com
# EMAIL_HOST_PASSWORD=sua-senha-email
EOF

# Ajustar permissões
echo "🔒 Ajustando permissões..."
chown "$GUNICORN_USER:$GUNICORN_USER" "$ENV_FILE"
chmod 640 "$ENV_FILE"

echo ""
echo "✅ Arquivo .env criado com sucesso!"
echo ""
echo "📋 Localização: $ENV_FILE"
echo "👤 Propriedade: $GUNICORN_USER:$GUNICORN_USER"
echo "🔐 Permissões: 640"
echo ""

# Verificar se precisa ajustar DJANGO_SETTINGS_MODULE
echo "🔍 Verificando configuração do Gunicorn..."
if [ -f "/etc/systemd/system/s-agendamento.service" ]; then
    if ! grep -q "DJANGO_SETTINGS_MODULE=core.settings_production" /etc/systemd/system/s-agendamento.service; then
        echo "⚠️  DJANGO_SETTINGS_MODULE não está configurado como 'core.settings_production'"
        echo "   Ajuste manualmente em /etc/systemd/system/s-agendamento.service"
        echo "   Adicione: Environment=DJANGO_SETTINGS_MODULE=core.settings_production"
    else
        echo "✅ DJANGO_SETTINGS_MODULE configurado corretamente"
    fi
fi

echo ""
echo "📝 Próximos passos:"
echo "   1. Verifique o arquivo .env: sudo nano $ENV_FILE"
echo "   2. Ajuste as configurações que estão como 'CHANGE_ME_...'"
echo "   3. Reinicie o Gunicorn: sudo systemctl restart s-agendamento"
echo "   4. Execute o diagnóstico: python manage.py diagnosticar_asaas"
echo ""
echo "=========================================="
echo "  Concluído!"
echo "=========================================="

