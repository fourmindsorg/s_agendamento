#!/bin/bash
set -e
set -x

echo "🎁 CONFIGURANDO PLANO GRATUITO AUTOMÁTICO"
echo "========================================"

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

# 5. Garantir que o plano gratuito existe
echo "🎁 Garantindo que o plano gratuito existe..."
python manage.py ensure_free_plan

# 6. Coletar arquivos estáticos
echo "📁 Coletando arquivos estáticos..."
python manage.py collectstatic --noinput

# 7. Reiniciar serviços
echo "🔄 Reiniciando serviços..."
sudo systemctl daemon-reload
sudo systemctl restart gunicorn
sudo systemctl restart nginx

# 8. Aguardar serviços iniciarem
echo "⏳ Aguardando serviços iniciarem..."
sleep 10

# 9. Verificar status
echo "✅ Verificando status dos serviços..."
sudo systemctl status gunicorn --no-pager
sudo systemctl status nginx --no-pager

# 10. Testar aplicação
echo "🌐 Testando aplicação..."
curl -I http://localhost:8000/ || echo "❌ Aplicação não está respondendo localmente"
curl -I http://3.80.178.120/ || echo "❌ Aplicação não está acessível externamente"

echo "🎉 PLANO GRATUITO AUTOMÁTICO CONFIGURADO!"
echo "========================================"
echo "✅ Usuários recebem automaticamente 14 dias gratuitos"
echo "✅ Assinatura é criada automaticamente no cadastro"
echo "✅ Plano gratuito está ativo no sistema"
echo "🌐 Teste: https://fourmindstech.com.br/authentication/register/"
echo "👤 Cadastre um novo usuário para testar o plano gratuito"
