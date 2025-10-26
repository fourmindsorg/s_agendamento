#!/bin/bash
# Script para configurar redirecionamento no Nginx para fourmindstech.com.br

echo "=== CONFIGURANDO REDIRECIONAMENTO NGINX ==="

# Backup da configuração atual
sudo cp /etc/nginx/sites-available/s-agendamento /etc/nginx/sites-available/s-agendamento.backup

# Criar nova configuração com redirecionamento
sudo tee /etc/nginx/sites-available/s-agendamento > /dev/null <<EOF
server {
    listen 80;
    server_name fourmindstech.com.br www.fourmindstech.com.br;

    # Redirecionar para HTTPS
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name fourmindstech.com.br www.fourmindstech.com.br;

    # Configuração SSL (certificado Let's Encrypt)
    ssl_certificate /etc/letsencrypt/live/fourmindstech.com.br/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/fourmindstech.com.br/privkey.pem;
    
    # Configurações SSL
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Redirecionar raiz para /s_agendamentos
    location = / {
        return 301 https://\$server_name/s_agendamentos/;
    }

    # Servir aplicação Django
    location / {
        include proxy_params;
        proxy_pass http://unix:/opt/s-agendamento/s-agendamento.sock;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Arquivos estáticos
    location /static/ {
        alias /opt/s-agendamento/staticfiles/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Arquivos de mídia
    location /media/ {
        alias /opt/s-agendamento/mediafiles/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF

# Testar configuração
echo "Testando configuração do Nginx..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "Configuração válida. Reiniciando Nginx..."
    sudo systemctl reload nginx
    echo "Nginx configurado com sucesso!"
else
    echo "Erro na configuração do Nginx. Restaurando backup..."
    sudo cp /etc/nginx/sites-available/s-agendamento.backup /etc/nginx/sites-available/s-agendamento
    sudo nginx -t
fi

echo "=== CONFIGURAÇÃO NGINX CONCLUÍDA ==="
