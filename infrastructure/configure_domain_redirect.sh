#!/bin/bash
# Script para configurar redirecionamento do domínio fourmindstech.com.br

echo "=== CONFIGURANDO REDIRECIONAMENTO DO DOMÍNIO ==="

# Backup da configuração atual
sudo cp /etc/nginx/sites-available/s-agendamento /etc/nginx/sites-available/s-agendamento.backup.$(date +%Y%m%d_%H%M%S)

# Criar nova configuração com redirecionamento
sudo tee /etc/nginx/sites-available/s-agendamento > /dev/null <<EOF
# Configuração para fourmindstech.com.br
server {
    listen 80;
    server_name fourmindstech.com.br www.fourmindstech.com.br;

    # Redirecionar raiz para /s_agendamentos
    location = / {
        return 301 http://\$server_name/s_agendamentos/;
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

# Configuração para IP direto (fallback)
server {
    listen 80 default_server;
    server_name _;

    location = /favicon.ico { access_log off; log_not_found off; }
    location /static/ {
        alias /opt/s-agendamento/staticfiles/;
    }
    location /media/ {
        alias /opt/s-agendamento/mediafiles/;
    }

    location / {
        include proxy_params;
        proxy_pass http://unix:/opt/s-agendamento/s-agendamento.sock;
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
    
    echo ""
    echo "=== CONFIGURAÇÃO CONCLUÍDA ==="
    echo "Domínio: fourmindstech.com.br"
    echo "Redirecionamento: / -> /s_agendamentos/"
    echo "IP: 34.202.149.24"
    echo ""
    echo "Teste o acesso em:"
    echo "- http://fourmindstech.com.br"
    echo "- http://fourmindstech.com.br/s_agendamentos/"
    echo "- http://34.202.149.24"
else
    echo "Erro na configuração do Nginx. Restaurando backup..."
    sudo cp /etc/nginx/sites-available/s-agendamento.backup.* /etc/nginx/sites-available/s-agendamento
    sudo nginx -t
    echo "Backup restaurado."
fi
