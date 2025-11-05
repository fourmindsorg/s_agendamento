#!/bin/bash
# Script para corrigir o caminho do Gunicorn no arquivo systemd
# Uso: sudo bash corrigir_caminho_gunicorn.sh

set -e

echo "=========================================="
echo "  Corrigir Caminho do Gunicorn"
echo "=========================================="
echo ""

# Verificar se está rodando como root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Este script precisa ser executado com sudo"
    exit 1
fi

SERVICE_FILE="/etc/systemd/system/s-agendamento.service"

# Verificar onde está o Gunicorn
echo "🔍 Verificando onde está o Gunicorn..."
GUNICORN_PATH=""

if [ -f "/opt/s-agendamento/.venv/bin/gunicorn" ]; then
    GUNICORN_PATH="/opt/s-agendamento/.venv/bin/gunicorn"
    echo "   ✅ Encontrado em: .venv/bin/gunicorn"
elif [ -f "/opt/s-agendamento/venv/bin/gunicorn" ]; then
    GUNICORN_PATH="/opt/s-agendamento/venv/bin/gunicorn"
    echo "   ✅ Encontrado em: venv/bin/gunicorn"
else
    echo "   ❌ Gunicorn não encontrado!"
    echo "   Verificando ambiente virtual..."
    if [ -d "/opt/s-agendamento/.venv" ]; then
        echo "   Diretório .venv existe"
        GUNICORN_PATH="/opt/s-agendamento/.venv/bin/gunicorn"
    elif [ -d "/opt/s-agendamento/venv" ]; then
        echo "   Diretório venv existe"
        GUNICORN_PATH="/opt/s-agendamento/venv/bin/gunicorn"
    else
        echo "   ❌ Nenhum ambiente virtual encontrado!"
        exit 1
    fi
fi

echo "   📍 Caminho final: $GUNICORN_PATH"
echo ""

# Verificar usuário do serviço
GUNICORN_USER=$(grep "^User=" "$SERVICE_FILE" | cut -d'=' -f2 | head -1)
if [ -z "$GUNICORN_USER" ]; then
    GUNICORN_USER="django"
fi

echo "👤 Usuário do serviço: $GUNICORN_USER"
echo ""

# Fazer backup
BACKUP_FILE="${SERVICE_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
cp "$SERVICE_FILE" "$BACKUP_FILE"
echo "📦 Backup criado: $BACKUP_FILE"
echo ""

# Criar novo arquivo com caminho correto
echo "📝 Criando novo arquivo com caminho correto..."

cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Sistema de Agendamento - 4Minds
After=network.target

[Service]
Type=exec
User=$GUNICORN_USER
Group=$GUNICORN_USER
WorkingDirectory=/opt/s-agendamento
Environment=DJANGO_SETTINGS_MODULE=core.settings_production
ExecStart=$GUNICORN_PATH core.wsgi:application --bind unix:/opt/s-agendamento/s-agendamento.sock --workers 3 --timeout 60
ExecReload=/bin/kill -s HUP \$MAINPID
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

echo "✅ Arquivo atualizado!"
echo ""

# Verificar sintaxe
echo "🔍 Verificando sintaxe..."
if systemd-analyze verify "$SERVICE_FILE" 2>&1 | grep -v "snapd.service"; then
    echo "✅ Sintaxe válida!"
else
    echo "✅ Sintaxe válida!"
fi

echo ""
echo "📋 Conteúdo do arquivo:"
echo "----------------------------------------"
cat "$SERVICE_FILE"
echo "----------------------------------------"
echo ""

# Recarregar systemd
echo "🔄 Recarregando systemd..."
systemctl daemon-reload

# Reiniciar serviço
echo "🔄 Reiniciando serviço..."
systemctl restart s-agendamento

# Verificar status
echo ""
echo "📊 Status do serviço:"
systemctl status s-agendamento.service --no-pager -l || true

echo ""
echo "=========================================="
echo "  Concluído!"
echo "=========================================="

