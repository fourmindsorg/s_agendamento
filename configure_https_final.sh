#!/bin/bash
# Script para configurar HTTPS definitivamente

echo "=== CONFIGURANDO HTTPS DEFINITIVAMENTE ==="
echo "Domínio: fourmindstech.com.br"
echo "IP: 52.91.139.151"
echo ""

# 1. Verificar status atual
echo "1. Verificando status atual..."

echo "HTTP funcionando:"
curl -I http://fourmindstech.com.br/s_agendamentos/ --connect-timeout 5

echo ""
echo "HTTPS não funcionando:"
curl -I https://fourmindstech.com.br/s_agendamentos/ --connect-timeout 5 || echo "HTTPS não configurado"

# 2. Verificar DNS
echo ""
echo "2. Verificando DNS..."
nslookup fourmindstech.com.br

# 3. Criar script para configurar SSL no servidor
echo ""
echo "3. Criando script para configurar SSL no servidor..."

cat > configure_ssl_final.sh <<'EOF'
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
EOF

# 4. Instruções para o usuário
echo ""
echo "=== INSTRUÇÕES PARA CONFIGURAR HTTPS ==="
echo ""
echo "OPÇÃO 1 - CLOUDFLARE SSL (MAIS RÁPIDO):"
echo ""
echo "1. Acesse o painel do Cloudflare"
echo "2. Selecione o domínio fourmindstech.com.br"
echo "3. Vá para SSL/TLS → Overview"
echo "4. Mude de 'Off' para 'Flexible'"
echo "5. Aguarde 5-10 minutos"
echo "6. Teste: https://fourmindstech.com.br/s_agendamentos/"
echo ""
echo "OPÇÃO 2 - SSL DIRETO NO SERVIDOR:"
echo ""
echo "1. SSH no servidor EC2 (52.91.139.151)"
echo "2. Execute os comandos abaixo:"
echo ""
echo "sudo apt update"
echo "sudo apt install -y certbot python3-certbot-nginx"
echo "sudo certbot --nginx -d fourmindstech.com.br -d www.fourmindstech.com.br"
echo "sudo systemctl reload nginx"
echo ""
echo "OPÇÃO 3 - EXECUTAR SCRIPT AUTOMÁTICO:"
echo ""
echo "1. SSH no servidor EC2"
echo "2. Copie o conteúdo do arquivo configure_ssl_final.sh"
echo "3. Execute: bash configure_ssl_final.sh"
echo ""
echo "=== STATUS ATUAL ==="
echo ""
echo "✅ HTTP funcionando:"
echo "- http://fourmindstech.com.br/s_agendamentos/"
echo "- http://www.fourmindstech.com.br/s_agendamentos/"
echo ""
echo "❌ HTTPS não funcionando:"
echo "- https://fourmindstech.com.br/s_agendamentos/"
echo "- https://www.fourmindstech.com.br/s_agendamentos/"
echo ""
echo "🎯 RECOMENDAÇÃO:"
echo "Use a OPÇÃO 1 (Cloudflare SSL) para funcionamento imediato"
echo "ou a OPÇÃO 2 (SSL direto) para configuração completa."
echo ""
