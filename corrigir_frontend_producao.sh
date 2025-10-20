#!/bin/bash
set -e
set -x

echo "🎨 CORRIGINDO FRONTEND EM PRODUÇÃO"
echo "=================================="

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

# 5. Garantir plano gratuito
echo "🎁 Garantindo plano gratuito..."
python manage.py ensure_free_plan

# 6. Limpar arquivos estáticos antigos
echo "🧹 Limpando arquivos estáticos antigos..."
rm -rf /home/ubuntu/s_agendamento/staticfiles/*
rm -rf /home/ubuntu/s_agendamento/staticfiles/.*

# 7. Verificar arquivos estáticos antes da coleta
echo "🔍 Verificando arquivos estáticos antes da coleta..."
python manage.py check_static_files

# 8. Coletar arquivos estáticos
echo "📁 Coletando arquivos estáticos..."
python manage.py collectstatic --noinput --clear

# 9. Verificar arquivos estáticos após a coleta
echo "🔍 Verificando arquivos estáticos após a coleta..."
python manage.py check_static_files

# 8. Verificar se os arquivos foram coletados
echo "📋 Verificando arquivos coletados..."
ls -la /home/ubuntu/s_agendamento/staticfiles/
ls -la /home/ubuntu/s_agendamento/staticfiles/css/
ls -la /home/ubuntu/s_agendamento/staticfiles/js/

# 9. Corrigir permissões
echo "🔒 Corrigindo permissões..."
sudo chown -R ubuntu:www-data /home/ubuntu/s_agendamento/staticfiles
sudo chmod -R 755 /home/ubuntu/s_agendamento/staticfiles

# 10. Configurar Nginx para arquivos estáticos
echo "🌐 Configurando Nginx para arquivos estáticos..."
sudo tee /etc/nginx/sites-available/agendamento-4minds > /dev/null << 'EOF'
server {
    listen 80;
    server_name fourmindstech.com.br www.fourmindstech.com.br 3.80.178.120;

    # Arquivos estáticos
    location /static/ {
        alias /home/ubuntu/s_agendamento/staticfiles/;
        expires 1y;
        add_header Cache-Control "public, immutable";
        add_header Access-Control-Allow-Origin "*";
        
        # Configurações específicas para diferentes tipos de arquivo
        location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
            add_header Access-Control-Allow-Origin "*";
        }
    }
    
    # Arquivos de mídia
    location /media/ {
        alias /home/ubuntu/s_agendamento/media/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Favicon
    location = /favicon.ico { 
        access_log off; 
        log_not_found off; 
        alias /home/ubuntu/s_agendamento/staticfiles/favicon.ico;
    }

    # Aplicação Django
    location / {
        include proxy_params;
        proxy_pass http://127.0.0.1:8000;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # Headers para HTTPS
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Host $server_name;
    }
}
EOF

# 11. Testar configuração do Nginx
echo "🧪 Testando configuração do Nginx..."
sudo nginx -t

# 12. Reiniciar serviços
echo "🔄 Reiniciando serviços..."
sudo systemctl daemon-reload
sudo systemctl restart gunicorn
sudo systemctl restart nginx

# 13. Aguardar serviços iniciarem
echo "⏳ Aguardando serviços iniciarem..."
sleep 10

# 14. Verificar status
echo "✅ Verificando status dos serviços..."
sudo systemctl status gunicorn --no-pager
sudo systemctl status nginx --no-pager

# 15. Testar arquivos estáticos
echo "🌐 Testando arquivos estáticos..."
curl -I http://3.80.178.120/static/css/style.css || echo "❌ CSS não acessível"
curl -I http://3.80.178.120/static/css/bootstrap.min.css || echo "❌ Bootstrap não acessível"
curl -I http://3.80.178.120/static/css/error-messages.css || echo "❌ Error messages CSS não acessível"
curl -I http://3.80.178.120/static/js/bootstrap.bundle.min.js || echo "❌ Bootstrap JS não acessível"

# 16. Testar aplicação
echo "🌐 Testando aplicação..."
curl -I http://localhost:8000/ || echo "❌ Aplicação não está respondendo localmente"
curl -I http://3.80.178.120/ || echo "❌ Aplicação não está acessível externamente"

echo "🎉 FRONTEND CORRIGIDO!"
echo "====================="
echo "✅ Arquivos estáticos coletados e configurados"
echo "✅ Nginx configurado para servir arquivos estáticos"
echo "✅ Permissões corrigidas"
echo "✅ Cache configurado para melhor performance"
echo "🌐 Teste: https://fourmindstech.com.br/"
echo "📁 Verifique se CSS, JS e imagens estão carregando corretamente"
