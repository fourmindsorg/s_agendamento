#!/bin/bash
set -e  # para parar se algum comando falhar

echo "� Iniciando implantação Terraform..."

cd ~/environment/aws-infrastructure  # Caminho onde estão os arquivos .tfcd /c/PROJETOS/TRABALHOS/STARTUP/4Minds/Sistemas/s_agendamento/aws-infrastructure

# Inicializa Terraform
terraform init -reconfigure

# Mostra plano
terraform plan -out=tfplan

# Aplica automaticamente
terraform apply -auto-approve tfplan

echo "✅ Infraestrutura criada com sucesso!"
