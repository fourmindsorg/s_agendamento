#!/bin/bash

# Script para verificar e configurar GitHub Secrets
echo "🔍 VERIFICANDO CONFIGURAÇÃO GITHUB SECRETS"
echo "=========================================="

# 1. Verificar se estamos no diretório correto
cd /home/ubuntu

# 2. Clonar ou atualizar repositório
if [ -d "s_agendamento" ]; then
    echo "📂 Diretório existe. Atualizando..."
    cd s_agendamento
    git pull origin main
else
    echo "📂 Clonando repositório..."
    git clone https://github.com/fourmindsorg/s_agendamento.git
    cd s_agendamento
fi

# 3. Executar deploy completo
echo "🚀 Executando deploy completo..."
curl -s https://raw.githubusercontent.com/fourmindsorg/s_agendamento/main/corrigir_ssh_e_deploy.sh | bash

# 4. Gerar chaves SSH se não existirem
echo "🔑 Verificando chaves SSH..."
if [ ! -f "/home/ubuntu/.ssh/github_actions_key" ]; then
    echo "🔑 Gerando chaves SSH..."
    curl -s https://raw.githubusercontent.com/fourmindsorg/s_agendamento/main/gerar_chaves_ssh.sh | bash
else
    echo "✅ Chaves SSH já existem"
fi

# 5. Mostrar chaves para GitHub Secrets
echo ""
echo "🔑 CHAVE PÚBLICA PARA GITHUB SECRETS:"
echo "====================================="
cat /home/ubuntu/.ssh/github_actions_key.pub
echo ""
echo "🔑 CHAVE PRIVADA PARA GITHUB SECRETS:"
echo "====================================="
cat /home/ubuntu/.ssh/github_actions_key
echo ""

# 6. Mostrar instruções
echo "📋 INSTRUÇÕES PARA CONFIGURAR GITHUB SECRETS:"
echo "============================================="
echo "1. Acesse: https://github.com/fourmindsorg/s_agendamento/settings/secrets/actions"
echo "2. Adicione os seguintes secrets:"
echo ""
echo "   EC2_HOST: 3.80.178.120"
echo "   EC2_USERNAME: ubuntu"
echo "   EC2_PORT: 22"
echo "   EC2_SSH_KEY: (cole a CHAVE PRIVADA acima)"
echo ""
echo "3. Teste o workflow: https://github.com/fourmindsorg/s_agendamento/actions"

# 7. Testar aplicação
echo ""
echo "🌐 Testando aplicação..."
timeout 10 curl -I http://3.80.178.120/ 2>/dev/null && echo "✅ Aplicação funcionando" || echo "❌ Aplicação não responde"

echo ""
echo "✅ CONFIGURAÇÃO COMPLETA!"
echo "========================="
echo "🌐 Acesse: http://3.80.178.120"
echo "👤 Admin: http://3.80.178.120/admin"
echo "👤 Usuário: admin | Senha: admin123"
