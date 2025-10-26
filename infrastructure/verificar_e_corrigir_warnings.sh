#!/bin/bash
# Script para corrigir warnings do Nginx

echo "=== CORRIGINDO WARNINGS DO NGINX ==="
echo ""

# Ver todas as configurações do Nginx
echo "1. Verificando configurações ativas..."
sudo nginx -T 2>&1 | grep -A 5 "server_name.*fourmindstech"

# Ver se há arquivos duplicados
echo ""
echo "2. Verificando arquivos de configuração..."
ls -la /etc/nginx/sites-enabled/

# Procurar por conflitos
echo ""
echo "3. Procurando conflitos de configuração..."
sudo find /etc/nginx -name "*.conf" -o -name "s-agendamento*" 2>/dev/null

echo ""
echo "=== INSTRUCOES ==="
echo "Se houver arquivos duplicados em /etc/nginx/sites-enabled/, remova os duplicados:"
echo "sudo rm /etc/nginx/sites-enabled/arquivo-duplicado"
echo ""
echo "Depois recarregue:"
echo "sudo nginx -t && sudo systemctl reload nginx"

