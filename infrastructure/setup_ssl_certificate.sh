#!/bin/bash
# Script para configurar certificado SSL Let's Encrypt

echo "=== CONFIGURANDO CERTIFICADO SSL ==="

# Instalar Certbot
echo "1. Instalando Certbot..."
sudo apt update
sudo apt install -y certbot python3-certbot-nginx

# Parar Nginx temporariamente
echo "2. Parando Nginx..."
sudo systemctl stop nginx

# Obter certificado SSL
echo "3. Obtendo certificado SSL para fourmindstech.com.br..."
sudo certbot certonly --standalone -d fourmindstech.com.br -d www.fourmindstech.com.br --non-interactive --agree-tos --email admin@fourmindstech.com.br

# Verificar se o certificado foi criado
if [ -f "/etc/letsencrypt/live/fourmindstech.com.br/fullchain.pem" ]; then
    echo "Certificado SSL criado com sucesso!"
    
    # Configurar renovação automática
    echo "4. Configurando renovação automática..."
    (crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -
    
    echo "Renovação automática configurada!"
else
    echo "Erro ao criar certificado SSL!"
    exit 1
fi

# Reiniciar Nginx
echo "5. Reiniciando Nginx..."
sudo systemctl start nginx
sudo systemctl reload nginx

echo "=== CERTIFICADO SSL CONFIGURADO ==="
