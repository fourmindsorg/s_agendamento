#!/bin/bash
# Script para verificar socket e gunicorn

echo "=========================================="
echo "VERIFICACAO SOCKET E GUNICORN"
echo "=========================================="
echo ""

# 1. Verificar socket
echo "1. VERIFICANDO SOCKET"
echo "-" * 60
SOCKET_PATH="/opt/s-agendamento/s-agendamento.sock"
if [ -S "$SOCKET_PATH" ]; then
    echo "[OK] Socket existe: $SOCKET_PATH"
    ls -la "$SOCKET_PATH"
    echo ""
    echo "Permissoes:"
    stat "$SOCKET_PATH" | grep -E "(Uid|Gid|Access)"
else
    echo "[ERRO] Socket nao existe: $SOCKET_PATH"
    echo "   O gunicorn provavelmente nao esta rodando!"
fi
echo ""

# 2. Verificar processos gunicorn
echo "2. VERIFICANDO PROCESSOS GUNICORN"
echo "-" * 60
GUNICORN_PROCESSES=$(ps aux | grep gunicorn | grep -v grep)
if [ ! -z "$GUNICORN_PROCESSES" ]; then
    echo "[OK] Processos gunicorn encontrados:"
    echo "$GUNICORN_PROCESSES"
else
    echo "[ERRO] Nenhum processo gunicorn encontrado!"
fi
echo ""

# 3. Verificar diretorio
echo "3. VERIFICANDO DIRETORIO"
echo "-" * 60
if [ -d "/opt/s-agendamento" ]; then
    echo "[OK] Diretorio existe: /opt/s-agendamento"
    ls -la /opt/s-agendamento/ | head -10
else
    echo "[ERRO] Diretorio nao existe: /opt/s-agendamento"
    echo "   Criar com: sudo mkdir -p /opt/s-agendamento"
fi
echo ""

# 4. Verificar servicos systemd
echo "4. VERIFICANDO SERVICOS SYSTEMD"
echo "-" * 60
SERVICES=("s-agendamento" "gunicorn")
for service in "${SERVICES[@]}"; do
    if systemctl list-units --type=service --all | grep -q "$service"; then
        echo "Servico: $service"
        sudo systemctl status "$service" --no-pager | head -10
        echo ""
    fi
done

# 5. Verificar logs
echo "5. VERIFICANDO LOGS"
echo "-" * 60
if [ -f "/opt/s-agendamento/logs/django.log" ]; then
    echo "[OK] Log do Django encontrado"
    echo "Ultimas 10 linhas:"
    tail -10 /opt/s-agendamento/logs/django.log
else
    echo "[AVISO] Log do Django nao encontrado em /opt/s-agendamento/logs/django.log"
    echo "Procurando em outros lugares..."
    find /opt/s-agendamento -name "*.log" -type f 2>/dev/null
    find ~/s_agendamento -name "*.log" -type f 2>/dev/null
fi
echo ""

# 6. Verificar nginx
echo "6. VERIFICANDO NGINX"
echo "-" * 60
if systemctl is-active --quiet nginx 2>/dev/null; then
    echo "[OK] Nginx esta rodando"
    echo "Ultimos erros do nginx:"
    sudo tail -5 /var/log/nginx/error.log
else
    echo "[ERRO] Nginx nao esta rodando!"
fi
echo ""

echo "=========================================="
echo "VERIFICACAO CONCLUIDA"
echo "=========================================="
echo ""
echo "SOLUCAO RAPIDA:"
echo "1. Se socket nao existe ou gunicorn nao esta rodando:"
echo "   sudo systemctl restart s-agendamento"
echo ""
echo "2. Se servico nao existe:"
echo "   Criar servico systemd (ver _CORRIGIR_502_SOCKET.md)"
echo ""
echo "3. Ver logs detalhados:"
echo "   tail -f /opt/s-agendamento/logs/django.log"
echo "   sudo tail -f /var/log/nginx/error.log"

