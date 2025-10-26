@echo off
echo ==============================================
echo FIX NGINX - Executar no servidor via SSM
echo ==============================================
echo.

echo Escolha uma opcao:
echo 1. Executar via SSM (sem chave SSH)
echo 2. Ver instrucoes para SSH manual
echo 3. Copiar comando para executar manualmente
echo.

set /p opcao="Escolha (1, 2 ou 3): "

if "%opcao%"=="1" goto ssm
if "%opcao%"=="2" goto ssh_manual
if "%opcao%"=="3" goto copy_command

:ssm
echo.
echo Enviando comando via AWS SSM...
echo Instancia: i-0077873407e4114b1
echo.

aws ssm send-command --instance-ids "i-0077873407e4114b1" --document-name "AWS-RunShellScript" --parameters "commands=['#!/bin/bash', 'curl -o /tmp/fix_nginx.sh https://raw.githubusercontent.com/gist/anonymous/fix_nginx.sh', 'chmod +x /tmp/fix_nginx.sh', 'sudo /tmp/fix_nginx.sh']" --region us-east-1

echo.
echo Comando enviado! Verificando status...
echo.
timeout /t 5 /nobreak
aws ssm list-commands --command-id $(aws ssm list-commands --query "CommandInvocations[0].CommandId" --output text)
echo.
echo Para ver o output, execute: aws ssm get-command-invocation --command-id <ID>
goto end

:ssh_manual
echo.
echo ==============================================
echo OPCAO 1: Usar Session Manager (recomendado)
echo ==============================================
echo aws ssm start-session --target i-0077873407e4114b1
echo.
echo ==============================================
echo OPCAO 2: Usar SSH (precisa da chave .pem)
echo ==============================================
echo 1. Coloque a chave .pem no diretorio atual
echo 2. Execute:
echo    ssh -i sua_chave.pem ec2-user@52.91.139.151
echo 3. Depois de conectar, execute o script:
echo.
echo Ou copie e cole este comando direto no servidor:
goto copy_command

:copy_command
echo.
echo ==============================================
echo COMANDO PARA COPIAR E COLAR NO SERVIDOR:
echo ==============================================
echo.
echo Copie tudo abaixo ate a linha SCRIPT_END:
echo.
(
echo sudo tee /etc/nginx/sites-available/s-agendamento > /dev/null ^^<^^<'SCRIPT_EOF'
echo # Servidor HTTP para acesso direto pelo IP
echo server {
echo     listen 80 default_server;
echo     listen [::]:80 default_server;
echo     server_name _;
echo     
echo     location /static/ {
echo         alias /opt/s-agendamento/staticfiles/;
echo         expires 1y;
echo         add_header Cache-Control "public, immutable";
echo     }
echo     
echo     location /media/ {
echo         alias /opt/s-agendamento/mediafiles/;
echo         expires 1y;
echo         add_header Cache-Control "public, immutable";
echo     }
echo     
echo     location / {
echo         include proxy_params;
echo         proxy_pass http://unix:/opt/s-agendamento/s-agendamento.sock;
echo         proxy_set_header Host $host;
echo         proxy_set_header X-Real-IP $remote_addr;
echo         proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
echo         proxy_set_header X-Forwarded-Proto $scheme;
echo     }
echo }
echo 
echo # Servidor HTTPS para dominio
echo server {
echo     listen 443 ssl http2;
echo     server_name fourmindstech.com.br www.fourmindstech.com.br;
echo     
echo     ssl_certificate /etc/letsencrypt/live/fourmindstech.com.br/fullchain.pem;
echo     ssl_certificate_key /etc/letsencrypt/live/fourmindstech.com.br/privkey.pem;
echo     
echo     ssl_protocols TLSv1.2 TLSv1.3;
echo     ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
echo     ssl_prefer_server_ciphers off;
echo     ssl_session_cache shared:SSL:10m;
echo     ssl_session_timeout 10m;
echo     
echo     location /static/ {
echo         alias /opt/s-agendamento/staticfiles/;
echo         expires 1y;
echo         add_header Cache-Control "public, immutable";
echo     }
echo     
echo     location /media/ {
echo         alias /opt/s-agendamento/mediafiles/;
echo         expires 1y;
echo         add_header Cache-Control "public, immutable";
echo     }
echo     
echo     location / {
echo         include proxy_params;
echo         proxy_pass http://unix:/opt/s-agendamento/s-agendamento.sock;
echo         proxy_set_header Host $host;
echo         proxy_set_header X-Real-IP $remote_addr;
echo         proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
echo         proxy_set_header X-Forwarded-Proto $scheme;
echo     }
echo }
echo SCRIPT_EOF
echo.
echo sudo nginx -t && sudo systemctl reload nginx
echo.
echo ==============================================
goto end

:end
echo.
pause

