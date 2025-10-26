@echo off
echo ==============================================
echo FIX NGINX VIA AWS SSM
echo ==============================================
echo.

echo 1. Enviando comandos para configurar o Nginx...
echo.

aws ssm send-command --instance-ids "i-0077873407e4114b1" --document-name "AWS-RunShellScript" --parameters "commands=['#!/bin/bash', 'set -e', '', 'echo \"=== CONFIGURANDO NGINX PARA IP E DOMINIO ===\"', '', '# Fazer backup', 'sudo cp /etc/nginx/sites-available/s-agendamento /etc/nginx/sites-available/s-agendamento.backup.%27%27%28date +%%Y%%m%%d_%%H%%M%%S%29%27%27', '', '# Criar nova configuracao', 'sudo tee /etc/nginx/sites-available/s-agendamento > /dev/null <<\"SCRIPT_EOF\"', '# Servidor HTTP para acesso direto pelo IP (sem SSL)', 'server {', '    listen 80 default_server;', '    listen [::]:80 default_server;', '    server_name _;', '    ', '    location /static/ {', '        alias /opt/s-agendamento/staticfiles/;', '        expires 1y;', '        add_header Cache-Control \"public, immutable\";', '    }', '    ', '    location /media/ {', '        alias /opt/s-agendamento/mediafiles/;', '        expires 1y;', '        add_header Cache-Control \"public, immutable\";', '    }', '    ', '    location / {', '        include proxy_params;', '        proxy_pass http://unix:/opt/s-agendamento/s-agendamento.sock;', '        proxy_set_header Host $host;', '        proxy_set_header X-Real-IP $remote_addr;', '        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;', '        proxy_set_header X-Forwarded-Proto $scheme;', '    }', '}', '', '# Servidor HTTPS apenas para dominio', 'server {', '    listen 443 ssl http2;', '    server_name fourmindstech.com.br www.fourmindstech.com.br;', '    ', '    ssl_certificate /etc/letsencrypt/live/fourmindstech.com.br/fullchain.pem;', '    ssl_certificate_key /etc/letsencrypt/live/fourmindstech.com.br/privkey.pem;', '    ', '    ssl_protocols TLSv1.2 TLSv1.3;', '    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;', '    ssl_prefer_server_ciphers off;', '    ssl_session_cache shared:SSL:10m;', '    ssl_session_timeout 10m;', '    ', '    location /static/ {', '        alias /opt/s-agendamento/staticfiles/;', '        expires 1y;', '        add_header Cache-Control \"public, immutable\";', '    }', '    ', '    location /media/ {', '        alias /opt/s-agendamento/mediafiles/;', '        expires 1y;', '        add_header Cache-Control \"public, immutable\";', '    }', '    ', '    location / {', '        include proxy_params;', '        proxy_pass http://unix:/opt/s-agendamento/s-agendamento.sock;', '        proxy_set_header Host $host;', '        proxy_set_header X-Real-IP $remote_addr;', '        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;', '        proxy_set_header X-Forwarded-Proto $scheme;', '    }', '}', 'SCRIPT_EOF', '', '# Testar configuracao', 'echo \"Testando configuracao do Nginx...\"', 'sudo nginx -t', '', 'if [ $? -eq 0 ]; then', '    echo \"Configuracao valida. Recarregando Nginx...\"', '    sudo systemctl reload nginx', '    echo \"Nginx recarregado com sucesso!\"', '    echo \"\"', '    echo \"=== CONFIGURACAO CONCLUIDA ===\"', '    echo \"Agora o servidor aceita:\"', '    echo \"  - http://52.91.139.151 (HTTP sem SSL)\"', '    echo \"  - https://fourmindstech.com.br (HTTPS com SSL)\"', 'else', '    echo \"Erro na configuracao!\"', 'fi']" --region us-east-1

echo.
echo 2. Comando enviado. Aguardando execucao...
echo.
echo Para verificar o status do comando:
echo aws ssm list-commands
echo.
echo Para ver a saida do comando:
echo aws ssm list-command-invocations --command-id <COMMAND_ID>
echo.
echo Para testar a conexao:
echo curl -I http://52.91.139.151
echo.
pause

