#!/bin/bash
# Diagnosticar erro 400 Bad Request

echo "=== DIAGNOSTICO ERROR 400 ==="

# Ver configurações de SSL que podem causar problema
echo "1. Verificando configurações SSL no settings.py:"
grep -E "SECURE|SSL|HTTPS" /opt/s-agendamento/s_agendamento/settings.py | head -20

echo ""
echo "2. Ver logs do Gunicorn para ver o erro real:"
sudo tail -30 /opt/s-agendamento/logs/gunicorn.log

echo ""
echo "3. Testar com curl verbose para ver headers:"
curl -v http://localhost 2>&1 | grep -E "Host|Request"

echo ""
echo "4. Verificar se há redirecionamento HTTPS forçado:"
grep "SECURE_SSL_REDIRECT\|SECURE_PROXY_SSL_HEADER" /opt/s-agendamento/s_agendamento/settings.py

