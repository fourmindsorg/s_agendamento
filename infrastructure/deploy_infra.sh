#!/bin/bash
set -e  # para parar se algum comando falhar

echo "Ì¥ß Iniciando implanta√ß√£o Terraform..."

cd ~/environment/aws-infrastructure  # Caminho onde est√£o os arquivos .tfcd /c/PROJETOS/TRABALHOS/STARTUP/4Minds/Sistemas/s_agendamento/aws-infrastructure

# Inicializa Terraform
terraform init -reconfigure

# Mostra plano
terraform plan -out=tfplan

# Aplica automaticamente
terraform apply -auto-approve tfplan

echo "‚úÖ Infraestrutura criada com sucesso!"
