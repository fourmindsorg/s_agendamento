#!/bin/bash
echo "=== CONFIGURANDO SSL FINAL NO SERVIDOR ==="

# Parar serviços
sudo supervisorctl stop s-agendamento

# Atualizar sistema
sudo apt update

# Instalar Certbot
sudo apt install -y certbot python3-certbot-nginx

# Backup da configuração atual
sudo cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.backup

# Configurar Nginx para HTTPS
sudo tee /etc/nginx/sites-available/fourmindstech.com.br > /dev/null <<'NGINX_EOF'
server {
    listen 80;
    server_name fourmindstech.com.br www.fourmindstech.com.br;
    
    # Redirecionar HTTP para HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name fourmindstech.com.br www.fourmindstech.com.br;
    
    # Configurações SSL (serão preenchidas pelo Certbot)
    ssl_certificate /etc/letsencrypt/live/fourmindstech.com.br/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/fourmindstech.com.br/privkey.pem;
    
    # Configurações SSL modernas
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Headers de segurança
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;
    add_header Referrer-Policy "same-origin" always;
    add_header Cross-Origin-Opener-Policy "same-origin" always;
    
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

# Obter certificado SSL
echo "Obtendo certificado SSL..."
sudo certbot --nginx -d fourmindstech.com.br -d www.fourmindstech.com.br --non-interactive --agree-tos --email admin@fourmindstech.com.br --redirect

# Reiniciar serviços
sudo supervisorctl start s-agendamento
sudo systemctl reload nginx

echo "=== SSL CONFIGURADO ==="
