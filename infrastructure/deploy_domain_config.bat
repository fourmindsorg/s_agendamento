@echo off
echo === DEPLOY DA CONFIGURAÇÃO DO DOMÍNIO ===

set EC2_IP=34.202.149.24
set KEY_FILE=s-agendamento-key.pem

echo 1. Verificando se a chave SSH existe...
if not exist "%KEY_FILE%" (
    echo ERRO: Arquivo de chave SSH não encontrado: %KEY_FILE%
    echo Por favor, coloque o arquivo s-agendamento-key.pem no diretório atual.
    pause
    exit /b 1
)

echo 2. Copiando scripts para o servidor EC2...
scp -i %KEY_FILE% configure_domain_redirect.sh ubuntu@%EC2_IP%:/tmp/
scp -i %KEY_FILE% configure_nginx_redirect.sh ubuntu@%EC2_IP%:/tmp/
scp -i %KEY_FILE% setup_ssl_certificate.sh ubuntu@%EC2_IP%:/tmp/

echo 3. Conectando ao servidor e configurando...
ssh -i %KEY_FILE% ubuntu@%EC2_IP% << 'EOF'
    echo "=== CONFIGURANDO SERVIDOR EC2 ==="
    
    # Tornar scripts executáveis
    chmod +x /tmp/configure_domain_redirect.sh
    chmod +x /tmp/configure_nginx_redirect.sh
    chmod +x /tmp/setup_ssl_certificate.sh
    
    # Executar configuração do redirecionamento
    echo "Executando configuração do redirecionamento..."
    sudo bash /tmp/configure_domain_redirect.sh
    
    # Verificar status dos serviços
    echo "Verificando status dos serviços..."
    sudo systemctl status nginx --no-pager
    sudo supervisorctl status s-agendamento
    
    echo "=== CONFIGURAÇÃO CONCLUÍDA ==="
EOF

echo.
echo === DEPLOY CONCLUÍDO ===
echo.
echo URLs para testar:
echo - http://fourmindstech.com.br
echo - http://fourmindstech.com.br/s_agendamentos/
echo - http://34.202.149.24
echo.
echo Para configurar SSL (opcional):
echo ssh -i %KEY_FILE% ubuntu@%EC2_IP%
echo sudo bash /tmp/setup_ssl_certificate.sh
echo.
pause
