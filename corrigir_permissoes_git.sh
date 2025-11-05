#!/bin/bash
# Script para corrigir permissões do Git
# Uso: sudo bash corrigir_permissoes_git.sh

set -e

echo "=========================================="
echo "  Corrigir Permissões do Git"
echo "=========================================="
echo ""

# Verificar se está rodando como root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Este script precisa ser executado com sudo"
    echo "   Uso: sudo bash corrigir_permissoes_git.sh"
    exit 1
fi

PROJECT_DIR="/opt/s-agendamento"
CURRENT_USER=$(logname 2>/dev/null || echo "${SUDO_USER:-ubuntu}")

echo "📁 Diretório do projeto: $PROJECT_DIR"
echo "👤 Usuário atual: $CURRENT_USER"
echo ""

# Verificar se o diretório existe
if [ ! -d "$PROJECT_DIR" ]; then
    echo "❌ Diretório $PROJECT_DIR não encontrado!"
    exit 1
fi

# Verificar propriedade atual
echo "🔍 Verificando propriedade atual..."
OWNER=$(stat -c '%U' "$PROJECT_DIR" 2>/dev/null || stat -f '%Su' "$PROJECT_DIR" 2>/dev/null || echo "unknown")
echo "   Proprietário atual: $OWNER"

# Ajustar propriedade
echo ""
echo "🔧 Ajustando propriedade para $CURRENT_USER..."
chown -R "$CURRENT_USER:$CURRENT_USER" "$PROJECT_DIR"

# Verificar se funcionou
NEW_OWNER=$(stat -c '%U' "$PROJECT_DIR" 2>/dev/null || stat -f '%Su' "$PROJECT_DIR" 2>/dev/null || echo "unknown")
echo "   Novo proprietário: $NEW_OWNER"

# Configurar safe.directory
echo ""
echo "🔐 Configurando safe.directory..."
sudo -u "$CURRENT_USER" git config --global --add safe.directory "$PROJECT_DIR" 2>/dev/null || true

# Verificar se o Git funciona
echo ""
echo "✅ Testando Git..."
cd "$PROJECT_DIR"
if sudo -u "$CURRENT_USER" git status > /dev/null 2>&1; then
    echo "✅ Git funcionando corretamente!"
else
    echo "⚠️  Git ainda pode ter problemas. Tente executar:"
    echo "   git status"
fi

echo ""
echo "📝 Próximos passos:"
echo "   1. Testar: git pull origin main"
echo "   2. Se ainda houver erro, execute: git config --global --add safe.directory $PROJECT_DIR"
echo ""
echo "=========================================="
echo "  Concluído!"
echo "=========================================="

