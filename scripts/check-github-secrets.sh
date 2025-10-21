#!/bin/bash

# ========================================
# Script de Verificação de Secrets do GitHub
# Sistema de Agendamento - 4Minds
# ========================================

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "🔍 Verificando Secrets do GitHub"
echo "================================="

# Verificar se GitHub CLI está instalado
if ! command -v gh &> /dev/null; then
    print_error "GitHub CLI não encontrado. Instale com:"
    echo "  - Linux: sudo apt install gh"
    echo "  - macOS: brew install gh"
    echo "  - Windows: winget install GitHub.cli"
    exit 1
fi

# Verificar autenticação
if ! gh auth status &> /dev/null; then
    print_error "GitHub não autenticado. Execute: gh auth login"
    exit 1
fi

# Obter informações do repositório
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
print_status "Repositório: $REPO"

echo ""
print_status "Verificando secrets necessários..."

# Lista de secrets necessários com descrições
declare -A SECRETS=(
    ["AWS_ACCESS_KEY_ID"]="Chave de acesso AWS (obtenha no IAM)"
    ["AWS_SECRET_ACCESS_KEY"]="Chave secreta AWS (obtenha no IAM)"
    ["EC2_HOST"]="IP público da instância EC2 (ex: 34.228.191.215)"
    ["EC2_USERNAME"]="Usuário SSH da EC2 (geralmente: ubuntu)"
    ["EC2_SSH_KEY"]="Chave privada SSH para conectar na EC2"
    ["CLOUDFLARE_API_TOKEN"]="Token da API do Cloudflare (opcional)"
)

# Verificar cada secret
MISSING_SECRETS=()
CONFIGURED_SECRETS=()

for secret in "${!SECRETS[@]}"; do
    if gh secret list | grep -q "$secret"; then
        print_success "✅ $secret - Configurado"
        CONFIGURED_SECRETS+=("$secret")
    else
        print_warning "❌ $secret - NÃO CONFIGURADO"
        MISSING_SECRETS+=("$secret")
    fi
done

echo ""
echo "================================="
echo "📊 RESUMO DA VERIFICAÇÃO"
echo "================================="

echo "✅ Secrets configurados: ${#CONFIGURED_SECRETS[@]}"
echo "❌ Secrets ausentes: ${#MISSING_SECRETS[@]}"

if [ ${#MISSING_SECRETS[@]} -eq 0 ]; then
    print_success "Todos os secrets estão configurados!"
    echo ""
    echo "🚀 Seu pipeline CI/CD está pronto para funcionar!"
    echo ""
    echo "Para testar:"
    echo "  git add ."
    echo "  git commit -m 'Teste CI/CD'"
    echo "  git push origin main"
else
    echo ""
    print_warning "Secrets ausentes encontrados:"
    echo ""
    
    for secret in "${MISSING_SECRETS[@]}"; do
        echo "🔧 $secret"
        echo "   Descrição: ${SECRETS[$secret]}"
        echo ""
    done
    
    echo "================================="
    echo "🛠️  COMO CONFIGURAR OS SECRETS"
    echo "================================="
    echo ""
    
    # AWS Credentials
    if [[ " ${MISSING_SECRETS[@]} " =~ " AWS_ACCESS_KEY_ID " ]] || [[ " ${MISSING_SECRETS[@]} " =~ " AWS_SECRET_ACCESS_KEY " ]]; then
        echo "1. AWS Credentials:"
        echo "   a. Acesse: https://console.aws.amazon.com/iam/"
        echo "   b. Vá em 'Users' > 'Add user'"
        echo "   c. Nome: 'github-actions'"
        echo "   d. Permissões: 'AdministratorAccess' (ou políticas específicas)"
        echo "   e. Crie as credenciais de acesso"
        echo "   f. Configure os secrets:"
        echo "      gh secret set AWS_ACCESS_KEY_ID --body 'sua_access_key'"
        echo "      gh secret set AWS_SECRET_ACCESS_KEY --body 'sua_secret_key'"
        echo ""
    fi
    
    # EC2 Configuration
    if [[ " ${MISSING_SECRETS[@]} " =~ " EC2_HOST " ]] || [[ " ${MISSING_SECRETS[@]} " =~ " EC2_USERNAME " ]] || [[ " ${MISSING_SECRETS[@]} " =~ " EC2_SSH_KEY " ]]; then
        echo "2. EC2 Configuration:"
        echo "   a. Crie uma instância EC2 (t2.micro para Free Tier)"
        echo "   b. Configure security group (SSH, HTTP, HTTPS)"
        echo "   c. Gere par de chaves SSH"
        echo "   d. Configure os secrets:"
        echo "      gh secret set EC2_HOST --body 'IP_PUBLICO_DA_EC2'"
        echo "      gh secret set EC2_USERNAME --body 'ubuntu'"
        echo "      gh secret set EC2_SSH_KEY --body 'CONTEUDO_DA_CHAVE_PRIVADA'"
        echo ""
    fi
    
    # Cloudflare (opcional)
    if [[ " ${MISSING_SECRETS[@]} " =~ " CLOUDFLARE_API_TOKEN " ]]; then
        echo "3. Cloudflare (opcional):"
        echo "   a. Acesse: https://dash.cloudflare.com/profile/api-tokens"
        echo "   b. Crie um token com permissões de DNS"
        echo "   c. Configure o secret:"
        echo "      gh secret set CLOUDFLARE_API_TOKEN --body 'seu_token'"
        echo ""
    fi
    
    echo "================================="
    echo "🚀 APÓS CONFIGURAR OS SECRETS"
    echo "================================="
    echo ""
    echo "Execute novamente este script para verificar:"
    echo "  ./scripts/check-github-secrets.sh"
    echo ""
    echo "Ou execute o script completo de configuração:"
    echo "  ./scripts/setup-ci-cd.sh"
fi

echo ""
echo "📚 Documentação adicional:"
echo "  - CI/CD Analysis: CI_CD_ANALYSIS.md"
echo "  - Configuração: CONFIGURACAO.md"
echo "  - Segurança: SECURITY.md"
