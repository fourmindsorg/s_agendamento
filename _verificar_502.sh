#!/bin/bash
# Script para diagnosticar erro 502 Bad Gateway

echo "=========================================="
echo "DIAGNOSTICO 502 BAD GATEWAY"
echo "=========================================="
echo ""

# 1. Verificar processos Django
echo "1. VERIFICANDO PROCESSOS DJANGO"
echo "-" * 60
DJANGO_PROCESSES=$(ps aux | grep -E "python.*manage.py|gunicorn|uwsgi" | grep -v grep)
if [ ! -z "$DJANGO_PROCESSES" ]; then
    echo "[OK] Processos encontrados:"
    echo "$DJANGO_PROCESSES"
else
    echo "[ERRO] Nenhum processo Django encontrado!"
    echo "   O Django nao esta rodando!"
fi
echo ""

# 2. Verificar porta 8000
echo "2. VERIFICANDO PORTA 8000"
echo "-" * 60
if command -v netstat &> /dev/null; then
    PORT_CHECK=$(sudo netstat -tlnp 2>/dev/null | grep 8000)
elif command -v ss &> /dev/null; then
    PORT_CHECK=$(sudo ss -tlnp 2>/dev/null | grep 8000)
else
    PORT_CHECK=""
fi

if [ ! -z "$PORT_CHECK" ]; then
    echo "[OK] Porta 8000 esta em uso:"
    echo "$PORT_CHECK"
else
    echo "[ERRO] Porta 8000 nao esta em uso!"
    echo "   Nada esta ouvindo na porta 8000"
fi
echo ""

# 3. Verificar nginx
echo "3. VERIFICANDO NGINX"
echo "-" * 60
if systemctl is-active --quiet nginx 2>/dev/null; then
    echo "[OK] Nginx esta rodando"
    sudo systemctl status nginx --no-pager | head -5
else
    echo "[ERRO] Nginx nao esta rodando!"
fi
echo ""

# 4. Verificar configuracao nginx
echo "4. VERIFICANDO CONFIGURACAO NGINX"
echo "-" * 60
if sudo nginx -t 2>&1 | grep -q "successful"; then
    echo "[OK] Configuracao do nginx esta correta"
else
    echo "[ERRO] Configuracao do nginx tem erros!"
    sudo nginx -t
fi
echo ""

# 5. Verificar unix socket (se usar)
echo "5. VERIFICANDO UNIX SOCKET (se usar)"
echo "-" * 60
SOCKET_PATHS=("/tmp/gunicorn.sock" "/run/gunicorn.sock" "/var/run/gunicorn.sock")
SOCKET_FOUND=false
for socket in "${SOCKET_PATHS[@]}"; do
    if [ -S "$socket" ]; then
        echo "[OK] Socket encontrado: $socket"
        ls -la "$socket"
        SOCKET_FOUND=true
    fi
done
if [ "$SOCKET_FOUND" = false ]; then
    echo "[INFO] Nenhum unix socket encontrado (usando TCP)"
fi
echo ""

# 6. Verificar logs do nginx
echo "6. ULTIMAS LINHAS DO LOG DE ERRO DO NGINX"
echo "-" * 60
if [ -f "/var/log/nginx/error.log" ]; then
    echo "Ultimas 10 linhas:"
    sudo tail -10 /var/log/nginx/error.log
else
    echo "[AVISO] Arquivo de log nao encontrado"
fi
echo ""

# 7. Verificar servicos systemd
echo "7. VERIFICANDO SERVICOS SYSTEMD"
echo "-" * 60
SERVICES=("s-agendamento" "gunicorn" "django")
for service in "${SERVICES[@]}"; do
    if systemctl list-units --type=service --all | grep -q "$service"; then
        echo "Servico: $service"
        sudo systemctl status "$service" --no-pager | head -5
        echo ""
    fi
done

echo "=========================================="
echo "DIAGNOSTICO CONCLUIDO"
echo "=========================================="
echo ""
echo "PROXIMOS PASSOS:"
echo "1. Se Django nao esta rodando:"
echo "   sudo systemctl restart s-agendamento"
echo ""
echo "2. Se nginx tem erro:"
echo "   sudo nginx -t"
echo "   sudo systemctl reload nginx"
echo ""
echo "3. Ver logs detalhados:"
echo "   sudo tail -f /var/log/nginx/error.log"
echo "   tail -f /opt/s-agendamento/logs/django.log"

