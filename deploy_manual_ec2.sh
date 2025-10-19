#!/bin/bash

# Script de Deploy Manual para EC2
# Execute este script diretamente na EC2 via Console AWS

set -e
set -x

echo "🚀 Iniciando deploy manual na EC2..."

# Navegar para o diretório do projeto
cd /home/ubuntu/s_agendamento

echo "📁 Diretório atual: $(pwd)"

# Atualizar código do repositório
echo "📥 Fazendo pull do repositório..."
git pull origin main

# Instalar dependências
echo "📦 Instalando dependências..."
pip install -r requirements.txt

# Executar migrações
echo "🗄️ Executando migrações..."
python manage.py migrate

# Coletar arquivos estáticos
echo "📁 Coletando arquivos estáticos..."
python manage.py collectstatic --noinput

# Reiniciar serviços
echo "🔄 Reiniciando serviços..."
sudo systemctl restart gunicorn
sudo systemctl restart nginx

# Verificar status dos serviços
echo "✅ Verificando status dos serviços..."
sudo systemctl status gunicorn --no-pager
sudo systemctl status nginx --no-pager

# Testar aplicação
echo "🌐 Testando aplicação..."
curl -I http://localhost:8000/ || echo "❌ Aplicação não está respondendo"
curl -I http://3.80.178.120/ || echo "❌ Aplicação não está acessível externamente"

echo "🎉 Deploy manual concluído!"
echo "🌐 Acesse: http://3.80.178.120"
echo "🌐 Acesse: http://fourmindstech.com.br (após configurar DNS)"
