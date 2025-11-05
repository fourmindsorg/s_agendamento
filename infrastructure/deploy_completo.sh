#!/bin/bash
# Script completo de deploy com todas as correções aplicadas

set -e  # Parar se houver erro

echo "=============================================="
echo "🚀 DEPLOY COMPLETO - Sistema de Agendamento"
echo "=============================================="

cd /opt/s-agendamento

# 1. Atualizar código
echo ""
echo "1. Atualizando código..."
git fetch origin
git reset --hard origin/main
echo "✓ Código atualizado: $(git log --oneline -1)"

# 2. Ativar venv e instalar dependências
echo ""
echo "2. Instalando dependências..."
source venv/bin/activate
pip install -r requirements.txt --upgrade
echo "✓ Dependências instaladas"

# 3. Aplicar migrações
echo ""
echo "3. Aplicando migrações..."
python manage.py migrate
echo "✓ Migrações aplicadas"

# 4. Coletar arquivos estáticos
echo ""
echo "4. Coletando arquivos estáticos..."
python manage.py collectstatic --noinput
echo "✓ Arquivos estáticos coletados"

# 5. Aplicar correções do Nginx
echo ""
echo "5. Aplicando configuração do Nginx..."
sudo tee /etc/nginx/sites-available/s-agendamento > /dev/null <<'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;
    
    location /static/ {
        alias /opt/s-agendamento/staticfiles/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    location /media/ {
        alias /opt/s-agendamento/mediafiles/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    location / {
        include proxy_params;
        proxy_pass http://unix:/opt/s-agendamento/s-agendamento.sock;
        # Aumentado para 120s para evitar 502 Bad Gateway em operações longas (geração de QR code)
        proxy_connect_timeout 120s;
        proxy_send_timeout 120s;
        proxy_read_timeout 120s;
    }
}

server {
    listen 443 ssl http2;
    server_name fourmindstech.com.br www.fourmindstech.com.br;
    
    ssl_certificate /etc/letsencrypt/live/fourmindstech.com.br/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/fourmindstech.com.br/privkey.pem;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    location /static/ {
        alias /opt/s-agendamento/staticfiles/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    location /media/ {
        alias /opt/s-agendamento/mediafiles/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    location / {
        include proxy_params;
        proxy_pass http://unix:/opt/s-agendamento/s-agendamento.sock;
        # Aumentado para 120s para evitar 502 Bad Gateway em operações longas (geração de QR code)
        proxy_connect_timeout 120s;
        proxy_send_timeout 120s;
        proxy_read_timeout 120s;
    }
}
EOF

# 6. Corrigir configuração do supervisor
echo ""
echo "6. Aplicando configuração do Supervisor..."
sudo tee /etc/supervisor/conf.d/s-agendamento.conf > /dev/null <<'EOF'
[program:s-agendamento]
command=/opt/s-agendamento/venv/bin/gunicorn core.wsgi:application --bind unix:/opt/s-agendamento/s-agendamento.sock --workers 3 --timeout 120
directory=/opt/s-agendamento
user=django
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/opt/s-agendamento/logs/gunicorn.log
environment=PATH="/opt/s-agendamento/venv/bin",DJANGO_SETTINGS_MODULE="core.settings_production"
EOF

# 7. Testar e recarregar serviços
echo ""
echo "7. Testando e recarregando serviços..."
sudo nginx -t
if [ $? -eq 0 ]; then
    echo "✓ Configuração do Nginx válida"
else
    echo "✗ Erro na configuração do Nginx!"
    exit 1
fi

sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl restart s-agendamento
sudo systemctl reload nginx

echo "✓ Serviços recarregados"

# 8. Aguardar e verificar
echo ""
echo "8. Aguardando serviços iniciarem..."
sleep 5

sudo supervisorctl status

echo ""
echo "9. Testando conectividade..."
curl -I http://localhost
curl -I http://52.91.139.151

echo ""
echo "=============================================="
echo "🎉 DEPLOY CONCLUÍDO COM SUCESSO!"
echo "=============================================="
echo ""
echo "✓ Código atualizado"
echo "✓ Dependências instaladas"
echo "✓ Migrações aplicadas"
echo "✓ Arquivos estáticos coletados"
echo "✓ Nginx configurado"
echo "✓ Gunicorn configurado"
echo "✓ Serviços reiniciados"
echo ""
echo "Testar:"
echo "  http://52.91.139.151"
echo "  https://fourmindstech.com.br"
echo ""

