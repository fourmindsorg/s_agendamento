#!/bin/bash
set -e

# Log de inicialização
echo "$(date): Iniciando configuração da instância EC2" >> /var/log/cloud-init-output.log

# Atualizar sistema
apt-get update
apt-get upgrade -y

# Instalar dependências básicas
apt-get install -y python3 python3-pip python3-venv nginx git curl

# Criar usuário para aplicação
useradd -m -s /bin/bash django

# Criar diretórios
mkdir -p /var/www/agendamento
mkdir -p /var/log/django

# Configurar permissões
chown -R django:django /var/www/agendamento
chown -R django:django /var/log/django

# Log de inicialização
echo "$(date): Instância EC2 inicializada com sucesso" >> /var/log/django/startup.log
echo "$(date): Configuração concluída" >> /var/log/cloud-init-output.log
