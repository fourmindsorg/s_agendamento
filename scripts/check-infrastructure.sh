#!/bin/bash

# ========================================
# Script de Verificação de Infraestrutura
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

echo "🔍 Verificando Infraestrutura AWS"
echo "================================="

# Verificar se estamos no diretório correto
if [ ! -f "aws-infrastructure/main.tf" ]; then
    print_error "Execute este script no diretório raiz do projeto"
    exit 1
fi

cd aws-infrastructure

# Verificar se AWS CLI está configurado
print_status "Verificando AWS CLI..."
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    print_error "AWS CLI não configurado ou sem permissões"
    exit 1
fi
print_success "AWS CLI configurado"

# Verificar se Terraform está instalado
print_status "Verificando Terraform..."
if ! command -v terraform &> /dev/null; then
    print_error "Terraform não encontrado"
    exit 1
fi
print_success "Terraform encontrado"

# Inicializar Terraform
print_status "Inicializando Terraform..."
terraform init -upgrade

# Verificar estado atual
print_status "Verificando estado da infraestrutura..."

# Verificar se há recursos existentes
if terraform show -json | jq -e '.values.root_module.resources[] | select(.type == "aws_instance")' > /dev/null 2>&1; then
    print_success "Infraestrutura já existe!"
    
    # Mostrar informações da instância existente
    print_status "Informações da instância EC2:"
    terraform output ec2_public_ip
    terraform output ec2_private_ip
    terraform output ec2_instance_id
    terraform output application_url
    
    echo ""
    print_warning "Para recriar a infraestrutura:"
    echo "1. terraform destroy -auto-approve"
    echo "2. terraform apply -var='create_infrastructure=true' -auto-approve"
    
else
    print_warning "Infraestrutura não existe"
    
    echo ""
    print_status "Para criar a infraestrutura:"
    echo "terraform apply -var='create_infrastructure=true' -auto-approve"
fi

# Verificar key pair existente
print_status "Verificando key pair..."
if aws ec2 describe-key-pairs --key-names "agendamento-4minds-key" > /dev/null 2>&1; then
    print_success "Key pair 'agendamento-4minds-key' existe"
else
    print_warning "Key pair 'agendamento-4minds-key' não existe"
    echo "Para criar: terraform apply -var='create_key_pair=true' -auto-approve"
fi

# Verificar VPC existente
print_status "Verificando VPC..."
if aws ec2 describe-vpcs --filters "Name=tag:Name,Values=agendamento-4minds-vpc" --query 'Vpcs[0].VpcId' --output text | grep -q "vpc-"; then
    print_success "VPC 'agendamento-4minds-vpc' existe"
else
    print_warning "VPC 'agendamento-4minds-vpc' não existe"
fi

# Verificar instância EC2 existente
print_status "Verificando instância EC2..."
if aws ec2 describe-instances --filters "Name=tag:Name,Values=agendamento-4minds-web-server" "Name=instance-state-name,Values=running" --query 'Reservations[0].Instances[0].InstanceId' --output text | grep -q "i-"; then
    print_success "Instância EC2 'agendamento-4minds-web-server' está rodando"
    
    # Mostrar IP público
    PUBLIC_IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=agendamento-4minds-web-server" "Name=instance-state-name,Values=running" --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
    print_status "IP Público: $PUBLIC_IP"
else
    print_warning "Instância EC2 'agendamento-4minds-web-server' não está rodando"
fi

echo ""
echo "================================="
print_success "Verificação concluída!"
echo "================================="

cd ..
