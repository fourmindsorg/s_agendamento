#!/bin/bash

# Script para gerar chaves SSH para GitHub Actions
echo "🔑 GERANDO CHAVES SSH PARA GITHUB ACTIONS"
echo "========================================="

# 1. Criar diretório .ssh se não existir
echo "📁 Criando diretório .ssh..."
mkdir -p /home/ubuntu/.ssh
chmod 700 /home/ubuntu/.ssh

# 2. Gerar chave SSH
echo "🔑 Gerando chave SSH..."
ssh-keygen -t rsa -b 4096 -C "github-actions-deploy" -f /home/ubuntu/.ssh/github_actions_key -N ""

# 3. Configurar authorized_keys
echo "📝 Configurando authorized_keys..."
cat /home/ubuntu/.ssh/github_actions_key.pub >> /home/ubuntu/.ssh/authorized_keys
chmod 600 /home/ubuntu/.ssh/authorized_keys

# 4. Mostrar chaves para GitHub Secrets
echo ""
echo "🔑 CHAVE PÚBLICA PARA GITHUB SECRETS:"
echo "====================================="
cat /home/ubuntu/.ssh/github_actions_key.pub
echo ""
echo "🔑 CHAVE PRIVADA PARA GITHUB SECRETS:"
echo "====================================="
cat /home/ubuntu/.ssh/github_actions_key
echo ""

# 5. Mostrar instruções
echo "📋 INSTRUÇÕES PARA CONFIGURAR GITHUB SECRETS:"
echo "============================================="
echo "1. Acesse: https://github.com/fourmindsorg/s_agendamento/settings/secrets/actions"
echo "2. Adicione os seguintes secrets:"
echo ""
echo "   EC2_SSH_KEY: (cole a CHAVE PRIVADA acima)"
echo "   EC2_HOST: 3.80.178.120"
echo "   EC2_USERNAME: ubuntu"
echo "   EC2_PORT: 22"
echo ""
echo "3. Atualize o workflow .github/workflows/deploy.yml"
echo "4. Execute o workflow para testar"
echo ""
echo "✅ Chaves SSH geradas com sucesso!"
