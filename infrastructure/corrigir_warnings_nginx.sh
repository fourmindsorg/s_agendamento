#!/bin/bash
# Script para corrigir warnings do Nginx - conflitos de configuração

echo "=== CORRIGINDO WARNINGS DO NGINX ==="
echo ""

# Ver configurações ativas
echo "1. Configurações ativas:"
sudo ls -la /etc/nginx/sites-enabled/

echo ""
echo "2. Verificando conflitos..."
sudo grep -r "server_name.*fourmindstech" /etc/nginx/sites-available/ 2>/dev/null

# Testar se tem múltiplos arquivos configurando o mesmo server_name
echo ""
echo "3. Verificando se há mais de um arquivo configurando o domínio..."
sudo find /etc/nginx/sites-available/ -type f -exec grep -l "fourmindstech.com.br" {} \;

# Backup antes de limpar
echo ""
echo "4. Fazendo backup das configurações atuais..."
sudo cp /etc/nginx/sites-available/s-agendamento /etc/nginx/sites-available/s-agendamento.backup.$(date +%Y%m%d_%H%M%S)

# Remover links simbólicos duplicados se houver
echo ""
echo "5. Verificando e removendo links duplicados..."
sudo find /etc/nginx/sites-enabled/ -name "s-agendamento*" -type l ! -name "s-agendamento" -delete 2>/dev/null

# Testar configuração
echo ""
echo "6. Testando configuração..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "✓ Configuração válida!"
    echo "7. Recarregando Nginx..."
    sudo systemctl reload nginx
    echo "✓ Nginx recarregado!"
    echo ""
    echo "=== TESTE ==="
    echo "Testar: curl -I http://localhost"
    echo "Testar: curl -I http://52.91.139.151"
else
    echo "✗ Erro na configuração!"
    echo "Verifique os logs: sudo nginx -t"
    exit 1
fi

