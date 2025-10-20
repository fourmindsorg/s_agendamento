#!/bin/bash
set -e
set -x

echo "🎨 APLICANDO AVISOS EM VERMELHO"
echo "==============================="

# 1. Atualizar código
echo "📁 Atualizando código..."
cd /home/ubuntu/s_agendamento
git pull origin main

# 2. Ativar ambiente virtual
echo "🐍 Ativando ambiente virtual..."
source .venv/bin/activate

# 3. Instalar dependências
echo "📦 Instalando dependências..."
pip install -r requirements.txt

# 4. Executar migrações
echo "🗄️ Executando migrações..."
python manage.py migrate

# 5. Coletar arquivos estáticos
echo "📁 Coletando arquivos estáticos..."
python manage.py collectstatic --noinput

# 6. Reiniciar serviços
echo "🔄 Reiniciando serviços..."
sudo systemctl daemon-reload
sudo systemctl restart gunicorn
sudo systemctl restart nginx

# 7. Aguardar serviços iniciarem
echo "⏳ Aguardando serviços iniciarem..."
sleep 10

# 8. Verificar status
echo "✅ Verificando status dos serviços..."
sudo systemctl status gunicorn --no-pager
sudo systemctl status nginx --no-pager

# 9. Testar aplicação
echo "🌐 Testando aplicação..."
curl -I http://localhost:8000/ || echo "❌ Aplicação não está respondendo localmente"
curl -I http://3.80.178.120/ || echo "❌ Aplicação não está acessível externamente"

echo "🎉 AVISOS EM VERMELHO APLICADOS!"
echo "================================"
echo "✅ Mensagens de erro agora aparecem em vermelho"
echo "✅ Campos com erro têm borda vermelha"
echo "🌐 Teste: https://fourmindstech.com.br/authentication/register/"
echo "👤 Tente cadastrar com usuário existente para ver o aviso vermelho"
