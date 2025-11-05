#!/bin/bash
# Script para recriar o arquivo systemd do zero
# Uso: sudo bash recriar_systemd.sh

set -e

echo "=========================================="
echo "  Recriar arquivo systemd s-agendamento"
echo "=========================================="
echo ""

# Verificar se está rodando como root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Este script precisa ser executado com sudo"
    echo "   Uso: sudo bash recriar_systemd.sh"
    exit 1
fi

SERVICE_FILE="/etc/systemd/system/s-agendamento.service"
BACKUP_FILE="${SERVICE_FILE}.backup.$(date +%Y%m%d_%H%M%S)"

# Fazer backup do arquivo atual
if [ -f "$SERVICE_FILE" ]; then
    echo "📦 Fazendo backup do arquivo atual..."
    cp "$SERVICE_FILE" "$BACKUP_FILE"
    echo "✅ Backup criado: $BACKUP_FILE"
fi

# Detectar usuário do Gunicorn
echo "🔍 Detectando usuário do Gunicorn..."
GUNICORN_USER=$(ps aux | grep -E 'gunicorn.*s-agendamento' | grep -v grep | awk '{print $1}' | head -1)

if [ -z "$GUNICORN_USER" ]; then
    # Tentar detectar do systemd backup
    if [ -f "$BACKUP_FILE" ]; then
        GUNICORN_USER=$(grep "^User=" "$BACKUP_FILE" | cut -d'=' -f2 | head -1)
    fi
    
    if [ -z "$GUNICORN_USER" ]; then
        # Tentar detectar do arquivo atual (se existir)
        if [ -f "$SERVICE_FILE" ]; then
            GUNICORN_USER=$(grep "^User=" "$SERVICE_FILE" | cut -d'=' -f2 | head -1)
        fi
    fi
    
    if [ -z "$GUNICORN_USER" ]; then
        GUNICORN_USER="django"
        echo "⚠️  Usuário não detectado, usando padrão: $GUNICORN_USER"
    fi
fi

echo "👤 Usuário detectado: $GUNICORN_USER"
echo ""

# Verificar caminho do Gunicorn
echo "🔍 Verificando caminho do Gunicorn..."
GUNICORN_PATH=""

# Tentar .venv primeiro (mais comum)
if [ -f "/opt/s-agendamento/.venv/bin/gunicorn" ]; then
    GUNICORN_PATH="/opt/s-agendamento/.venv/bin/gunicorn"
    echo "   ✅ Encontrado em: .venv/bin/gunicorn"
elif [ -f "/opt/s-agendamento/venv/bin/gunicorn" ]; then
    GUNICORN_PATH="/opt/s-agendamento/venv/bin/gunicorn"
    echo "   ✅ Encontrado em: venv/bin/gunicorn"
else
    # Tentar usar which
    GUNICORN_PATH=$(which gunicorn 2>/dev/null || echo "")
    if [ -n "$GUNICORN_PATH" ]; then
        echo "   ✅ Encontrado via which: $GUNICORN_PATH"
    else
        echo "   ❌ Gunicorn não encontrado!"
        echo "   Verificando diretórios..."
        if [ -d "/opt/s-agendamento/.venv" ]; then
            echo "   Diretório .venv existe"
        fi
        if [ -d "/opt/s-agendamento/venv" ]; then
            echo "   Diretório venv existe"
        fi
        echo "   Tentando instalar gunicorn..."
        GUNICORN_PATH="/opt/s-agendamento/.venv/bin/gunicorn"
    fi
fi

if [ -z "$GUNICORN_PATH" ] || [ ! -f "$GUNICORN_PATH" ]; then
    echo "⚠️  Gunicorn não encontrado, usando caminho padrão"
    GUNICORN_PATH="/opt/s-agendamento/.venv/bin/gunicorn"
fi

echo "   📍 Caminho final: $GUNICORN_PATH"

echo "📝 Criando novo arquivo systemd..."

# Criar arquivo novo
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

echo "✅ Arquivo criado: $SERVICE_FILE"
echo ""

# Verificar sintaxe
echo "🔍 Verificando sintaxe..."
if systemd-analyze verify "$SERVICE_FILE" 2>&1; then
    echo "✅ Sintaxe válida!"
else
    echo "❌ Erro na sintaxe! Verifique o arquivo manualmente."
    exit 1
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

# Verificar status
echo "📊 Status do serviço:"
systemctl status s-agendamento.service --no-pager || true

echo ""
echo "📝 Próximos passos:"
echo "   1. Verificar se o arquivo está correto: sudo cat $SERVICE_FILE"
echo "   2. Ajustar usuário se necessário (atualmente: $GUNICORN_USER)"
echo "   3. Iniciar o serviço: sudo systemctl start s-agendamento"
echo "   4. Verificar status: sudo systemctl status s-agendamento"
echo "   5. Ver logs: sudo journalctl -u s-agendamento -n 50"
echo ""
echo "=========================================="
echo "  Concluído!"
echo "=========================================="


