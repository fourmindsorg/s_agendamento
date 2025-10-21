#!/bin/bash

# ========================================
# Script de Configuração CI/CD
# Sistema de Agendamento - 4Minds
# ========================================

set -e

echo "🚀 Configurando CI/CD para Sistema de Agendamento"
echo "=================================================="

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para imprimir com cores
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

# Verificar se estamos no diretório correto
if [ ! -f "manage.py" ]; then
    print_error "Execute este script no diretório raiz do projeto Django"
    exit 1
fi

print_status "Verificando pré-requisitos..."

# Verificar Python
if ! command -v python3 &> /dev/null; then
    print_error "Python 3 não encontrado. Instale Python 3.8+ primeiro."
    exit 1
fi

# Verificar pip
if ! command -v pip3 &> /dev/null; then
    print_error "pip3 não encontrado. Instale pip primeiro."
    exit 1
fi

# Verificar Git
if ! command -v git &> /dev/null; then
    print_error "Git não encontrado. Instale Git primeiro."
    exit 1
fi

print_success "Pré-requisitos verificados"

# Verificar AWS CLI
print_status "Verificando AWS CLI..."
if ! command -v aws &> /dev/null; then
    print_warning "AWS CLI não encontrado. Instalando..."
    
    # Detectar sistema operacional
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        unzip awscliv2.zip
        sudo ./aws/install
        rm -rf aws awscliv2.zip
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
        sudo installer -pkg AWSCLIV2.pkg -target /
        rm AWSCLIV2.pkg
    else
        print_error "Sistema operacional não suportado. Instale AWS CLI manualmente."
        exit 1
    fi
else
    print_success "AWS CLI encontrado"
fi

# Configurar AWS CLI
print_status "Configurando AWS CLI..."
echo "Você precisará das seguintes credenciais AWS:"
echo "- Access Key ID"
echo "- Secret Access Key"
echo "- Região (padrão: us-east-1)"
echo ""

read -p "Deseja configurar AWS CLI agora? (y/n): " configure_aws

if [ "$configure_aws" = "y" ] || [ "$configure_aws" = "Y" ]; then
    aws configure
    print_success "AWS CLI configurado"
else
    print_warning "AWS CLI não configurado. Configure manualmente com 'aws configure'"
fi

# Verificar conectividade AWS
print_status "Testando conectividade AWS..."
if aws sts get-caller-identity &> /dev/null; then
    print_success "Conectividade AWS OK"
    aws sts get-caller-identity
else
    print_error "Falha na conectividade AWS. Verifique suas credenciais."
    exit 1
fi

# Verificar GitHub CLI
print_status "Verificando GitHub CLI..."
if ! command -v gh &> /dev/null; then
    print_warning "GitHub CLI não encontrado. Instalando..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        sudo apt update
        sudo apt install gh
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew install gh
    else
        print_error "Sistema operacional não suportado. Instale GitHub CLI manualmente."
        exit 1
    fi
else
    print_success "GitHub CLI encontrado"
fi

# Verificar autenticação GitHub
print_status "Verificando autenticação GitHub..."
if gh auth status &> /dev/null; then
    print_success "GitHub autenticado"
else
    print_warning "GitHub não autenticado. Fazendo login..."
    gh auth login
fi

# Verificar secrets do GitHub
print_status "Verificando secrets do GitHub..."
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)

echo "Secrets necessários para o repositório $REPO:"
echo ""

# Lista de secrets necessários
SECRETS=(
    "AWS_ACCESS_KEY_ID"
    "AWS_SECRET_ACCESS_KEY"
    "EC2_HOST"
    "EC2_USERNAME"
    "EC2_SSH_KEY"
    "CLOUDFLARE_API_TOKEN"
)

# Verificar cada secret
for secret in "${SECRETS[@]}"; do
    if gh secret list | grep -q "$secret"; then
        print_success "Secret $secret configurado"
    else
        print_warning "Secret $secret NÃO configurado"
    fi
done

echo ""
print_status "Para configurar secrets ausentes, use:"
echo "gh secret set SECRET_NAME --body 'valor_do_secret'"

# Verificar arquivos de configuração
print_status "Verificando arquivos de configuração..."

if [ -f ".env.example" ]; then
    print_success "Arquivo .env.example encontrado"
else
    print_error "Arquivo .env.example não encontrado"
    exit 1
fi

if [ -f "aws-infrastructure/terraform.tfvars.example" ]; then
    print_success "Arquivo terraform.tfvars.example encontrado"
else
    print_error "Arquivo terraform.tfvars.example não encontrado"
    exit 1
fi

# Verificar workflows
print_status "Verificando workflows do GitHub Actions..."

WORKFLOWS=(
    ".github/workflows/ci.yml"
    ".github/workflows/deploy.yml"
    ".github/workflows/terraform.yml"
    ".github/workflows/complete-setup.yml"
)

for workflow in "${WORKFLOWS[@]}"; do
    if [ -f "$workflow" ]; then
        print_success "Workflow $(basename $workflow) encontrado"
    else
        print_error "Workflow $(basename $workflow) não encontrado"
    fi
done

# Testar configuração local
print_status "Testando configuração local..."

# Instalar dependências
print_status "Instalando dependências Python..."
pip install -r requirements.txt

# Configurar ambiente de teste
print_status "Configurando ambiente de teste..."
cp .env.example .env
echo "SECRET_KEY=test-secret-key-for-ci-cd" >> .env
echo "DEBUG=True" >> .env
echo "ENVIRONMENT=development" >> .env

# Executar testes
print_status "Executando testes Django..."
python manage.py check
python manage.py test --verbosity=0

print_success "Testes Django executados com sucesso"

# Verificar Terraform
print_status "Verificando configuração Terraform..."

if command -v terraform &> /dev/null; then
    print_success "Terraform encontrado"
    
    cd aws-infrastructure
    
    # Verificar se terraform.tfvars existe
    if [ ! -f "terraform.tfvars" ]; then
        print_warning "Arquivo terraform.tfvars não encontrado. Copiando exemplo..."
        cp terraform.tfvars.example terraform.tfvars
        print_warning "Configure o arquivo terraform.tfvars com suas credenciais"
    fi
    
    # Validar configuração Terraform
    print_status "Validando configuração Terraform..."
    terraform init
    terraform validate
    
    print_success "Configuração Terraform válida"
    
    cd ..
else
    print_warning "Terraform não encontrado. Instale para usar infraestrutura como código."
fi

# Resumo final
echo ""
echo "=================================================="
print_success "Configuração CI/CD concluída!"
echo "=================================================="
echo ""
echo "📋 Próximos passos:"
echo "1. Configure os secrets ausentes no GitHub:"
echo "   gh secret set SECRET_NAME --body 'valor'"
echo ""
echo "2. Configure o arquivo terraform.tfvars:"
echo "   nano aws-infrastructure/terraform.tfvars"
echo ""
echo "3. Teste o deploy:"
echo "   git add ."
echo "   git commit -m 'Teste CI/CD'"
echo "   git push origin main"
echo ""
echo "4. Monitore os workflows em:"
echo "   https://github.com/$REPO/actions"
echo ""
echo "🎉 Sistema pronto para deploy automático!"
