#!/bin/bash
# Script para conectar ao servidor e corrigir Nginx

echo "=============================================="
echo "CONECTAR E CORRIGIR NGINX"
echo "=============================================="
echo ""

# Tentar conectar via Session Manager
echo "Tentando conectar via AWS Session Manager..."
echo ""

aws ssm start-session --target i-0077873407e4114b1 <<EOF

# Após conectar, executar os comandos abaixo:

echo "=== CONFIGURANDO NGINX ==="

# Fazer backup
sudo cp /etc/nginx/sites-available/s-agendamento /etc/nginx/sites-available/s-agendamento.backup.\$(date +%Y%m%d_%H%M%S)

# Criar nova configuração
sudo tee /etc/nginx/sites-available/s-agendamento > /dev/null <<'SCRIPT_EOF'
# Servidor HTTP para IP (sem SSL)
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
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}

# Servidor HTTPS para domínio
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
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
SCRIPT_EOF

# Testar e recarregar
echo "Testando configuração..."
sudo nginx -t

if [ \$? -eq 0 ]; then
    echo "✓ Configuração válida!"
    echo "Recarregando Nginx..."
    sudo systemctl reload nginx
    echo "✓ Nginx recarregado!"
    echo ""
    echo "=== SUCESSO ==="
    echo "Testar: curl -I http://52.91.139.151"
else
    echo "✗ Erro na configuração!"
fi

EOF

