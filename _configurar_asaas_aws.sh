#!/bin/bash
# Script para configurar variáveis Asaas no servidor AWS
# Uso: bash configurar_asaas_aws.sh

set -e

echo "=========================================="
echo "🔧 Configuração Asaas - Servidor AWS"
echo "=========================================="
echo ""

# Verificar se está no diretório do projeto
if [ ! -f "manage.py" ]; then
    echo "❌ Erro: Execute este script no diretório do projeto (onde está o manage.py)"
    exit 1
fi

# Verificar se .env existe
if [ ! -f ".env" ]; then
    echo "📝 Criando arquivo .env..."
    touch .env
fi

# Fazer backup
if [ -f ".env" ]; then
    echo "💾 Fazendo backup do .env atual..."
    cp .env .env.backup.$(date +%Y%m%d_%H%M%S)
fi

echo ""
echo "📋 Configuração do Asaas"
echo ""

# Solicitar ambiente
read -p "Ambiente (production/sandbox) [production]: " asaas_env
asaas_env=${asaas_env:-production}

# Solicitar chave de produção
echo ""
read -p "Chave de API de PRODUÇÃO ($aact_...): " asaas_key_prod
if [ -z "$asaas_key_prod" ]; then
    echo "❌ Erro: Chave de produção é obrigatória!"
    exit 1
fi

# Solicitar chave de sandbox (opcional)
echo ""
read -p "Chave de API de SANDBOX (opcional, Enter para pular): " asaas_key_sandbox

# Solicitar webhook token (opcional)
echo ""
read -p "Webhook Token (opcional, Enter para pular): " webhook_token

# Remover variáveis antigas do .env
echo ""
echo "🧹 Limpando variáveis antigas do .env..."
sed -i '/^ASAAS_ENV=/d' .env
sed -i '/^ASAAS_API_KEY=/d' .env
sed -i '/^ASAAS_API_KEY_PRODUCTION=/d' .env
sed -i '/^ASAAS_API_KEY_SANDBOX=/d' .env
sed -i '/^ASAAS_WEBHOOK_TOKEN=/d' .env

# Adicionar novas variáveis
echo ""
echo "➕ Adicionando novas variáveis..."

echo "" >> .env
echo "# Configuração Asaas - $(date '+%Y-%m-%d %H:%M:%S')" >> .env
echo "ASAAS_ENV=$asaas_env" >> .env
echo "ASAAS_API_KEY_PRODUCTION=$asaas_key_prod" >> .env

if [ ! -z "$asaas_key_sandbox" ]; then
    echo "ASAAS_API_KEY_SANDBOX=$asaas_key_sandbox" >> .env
fi

if [ ! -z "$webhook_token" ]; then
    echo "ASAAS_WEBHOOK_TOKEN=$webhook_token" >> .env
fi

# Ajustar permissões
chmod 600 .env

echo ""
echo "✅ Variáveis configuradas com sucesso!"
echo ""
echo "📋 Resumo:"
echo "   Ambiente: $asaas_env"
echo "   Chave Produção: ${asaas_key_prod:0:20}..."
echo "   Chave Sandbox: ${asaas_key_sandbox:+Configurada}"
echo "   Webhook Token: ${webhook_token:+Configurado}"
echo ""

# Verificar se está usando systemd
if systemctl is-active --quiet s-agendamento 2>/dev/null || \
   systemctl is-active --quiet gunicorn 2>/dev/null || \
   systemctl is-active --quiet django 2>/dev/null; then
    echo "🔄 Reiniciando serviço Django..."
    if systemctl is-active --quiet s-agendamento 2>/dev/null; then
        sudo systemctl restart s-agendamento
        echo "✅ Serviço s-agendamento reiniciado"
    elif systemctl is-active --quiet gunicorn 2>/dev/null; then
        sudo systemctl restart gunicorn
        echo "✅ Serviço gunicorn reiniciado"
    elif systemctl is-active --quiet django 2>/dev/null; then
        sudo systemctl restart django
        echo "✅ Serviço django reiniciado"
    fi
else
    echo "⚠️  Serviço systemd não encontrado. Reinicie manualmente o servidor Django."
fi

echo ""
echo "🔍 Para verificar se funcionou, execute:"
echo "   python manage.py shell"
echo "   >>> from django.conf import settings"
echo "   >>> print(getattr(settings, 'ASAAS_ENV'))"
echo ""
echo "   OU:"
echo "   python _VERIFICAR_CONFIGURACAO_ASAAS.py"
echo ""

