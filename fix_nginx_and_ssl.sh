#!/bin/bash
echo "=== CORRIGINDO NGINX E CONFIGURANDO SSL ==="

# Parar serviços
sudo supervisorctl stop s-agendamento

# Backup da configuração atual
sudo cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.backup

# Configurar Nginx corretamente para o domínio
sudo tee /etc/nginx/sites-available/fourmindstech.com.br > /dev/null <<'NGINX_EOF'
server {
    listen 80;
    server_name fourmindstech.com.br www.fourmindstech.com.br;
    
    # Configurações do Django
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Arquivos estáticos
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
}
NGINX_EOF

# Habilitar site
sudo ln -sf /etc/nginx/sites-available/fourmindstech.com.br /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Testar configuração
sudo nginx -t

# Recarregar Nginx
sudo systemctl reload nginx

# Instalar Certbot se não estiver instalado
sudo apt update
sudo apt install -y certbot python3-certbot-nginx

# Obter certificado SSL
echo "Obtendo certificado SSL..."
sudo certbot --nginx -d fourmindstech.com.br -d www.fourmindstech.com.br --non-interactive --agree-tos --email admin@fourmindstech.com.br --redirect

# Reiniciar serviços
sudo supervisorctl start s-agendamento
sudo systemctl reload nginx

# Verificar certificado
sudo certbot certificates

echo "=== NGINX E SSL CONFIGURADOS ==="
