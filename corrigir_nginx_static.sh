#!/bin/bash
set -e
set -x

echo "🌐 CORRIGINDO NGINX PARA ARQUIVOS ESTÁTICOS"
echo "==========================================="

# 1. Fazer backup da configuração atual
echo "💾 Fazendo backup da configuração atual..."
sudo cp /etc/nginx/sites-available/agendamento-4minds /etc/nginx/sites-available/agendamento-4minds.backup

# 2. Configurar Nginx para arquivos estáticos
echo "🌐 Configurando Nginx para arquivos estáticos..."
sudo tee /etc/nginx/sites-available/agendamento-4minds > /dev/null << 'EOF'
server {
    listen 80;
    server_name fourmindstech.com.br www.fourmindstech.com.br 3.80.178.120;

    # Configurações de log
    access_log /var/log/nginx/agendamento_access.log;
    error_log /var/log/nginx/agendamento_error.log;

    # Arquivos estáticos com configurações otimizadas
    location /static/ {
        alias /home/ubuntu/s_agendamento/staticfiles/;
        expires 1y;
        add_header Cache-Control "public, immutable";
        add_header Access-Control-Allow-Origin "*";
        
        # Configurações específicas para diferentes tipos de arquivo
        location ~* \.(css)$ {
            add_header Content-Type text/css;
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
        
        location ~* \.(js)$ {
            add_header Content-Type application/javascript;
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
        
        location ~* \.(png|jpg|jpeg|gif|ico|svg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
        
        location ~* \.(woff|woff2|ttf|eot)$ {
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
        expires 1y;
        add_header Cache-Control "public, immutable";
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
        proxy_set_header Host $host;
    }
}
EOF

# 3. Testar configuração do Nginx
echo "🧪 Testando configuração do Nginx..."
sudo nginx -t

# 4. Reiniciar Nginx
echo "🔄 Reiniciando Nginx..."
sudo systemctl restart nginx

# 5. Aguardar Nginx iniciar
echo "⏳ Aguardando Nginx iniciar..."
sleep 5

# 6. Verificar status
echo "✅ Verificando status do Nginx..."
sudo systemctl status nginx --no-pager

# 7. Testar arquivos estáticos
echo "🌐 Testando arquivos estáticos..."
echo "Testando CSS:"
curl -I http://3.80.178.120/static/css/style.css || echo "❌ CSS não acessível"
echo "Testando Bootstrap CSS:"
curl -I http://3.80.178.120/static/css/bootstrap.min.css || echo "❌ Bootstrap CSS não acessível"
echo "Testando Error Messages CSS:"
curl -I http://3.80.178.120/static/css/error-messages.css || echo "❌ Error Messages CSS não acessível"
echo "Testando Bootstrap JS:"
curl -I http://3.80.178.120/static/js/bootstrap.bundle.min.js || echo "❌ Bootstrap JS não acessível"

# 8. Verificar logs
echo "📋 Verificando logs do Nginx..."
sudo tail -10 /var/log/nginx/agendamento_error.log

echo "🎉 NGINX CORRIGIDO!"
echo "=================="
echo "✅ Configuração otimizada para arquivos estáticos"
echo "✅ Cache configurado para melhor performance"
echo "✅ Headers corretos para CSS e JS"
echo "✅ Logs específicos configurados"
echo "🌐 Teste: https://fourmindstech.com.br/"
