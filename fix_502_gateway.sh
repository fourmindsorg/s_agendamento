#!/bin/bash
echo "=== CORRIGINDO ERRO 502 BAD GATEWAY ==="

# 1. Verificar status dos serviços
echo "1. Verificando status dos serviços..."
sudo systemctl status nginx --no-pager
echo ""
sudo supervisorctl status s-agendamento
echo ""

# 2. Verificar se o Django está rodando na porta 8000
echo "2. Verificando se Django está rodando na porta 8000..."
sudo netstat -tlnp | grep :8000
echo ""

# 3. Verificar logs do Nginx
echo "3. Verificando logs do Nginx..."
sudo tail -20 /var/log/nginx/error.log
echo ""

# 4. Verificar logs do Django
echo "4. Verificando logs do Django..."
sudo tail -20 /opt/s-agendamento/logs/django.log
echo ""

# 5. Verificar configuração do Nginx
echo "5. Verificando configuração do Nginx..."
sudo nginx -t
echo ""

# 6. Reiniciar serviços
echo "6. Reiniciando serviços..."
sudo supervisorctl restart s-agendamento
sleep 5
sudo systemctl restart nginx
sleep 5

# 7. Verificar novamente
echo "7. Verificando status após reinicialização..."
sudo supervisorctl status s-agendamento
sudo systemctl status nginx --no-pager

# 8. Testar conectividade local
echo "8. Testando conectividade local..."
curl -I http://127.0.0.1:8000 --connect-timeout 5

echo "=== DIAGNÓSTICO CONCLUÍDO ==="

