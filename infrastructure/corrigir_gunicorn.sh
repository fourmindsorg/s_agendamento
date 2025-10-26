#!/bin/bash
# Script para corrigir Gunicorn 502

echo "=== DIAGNOSTICO E CORRECAO DO GUNICORN ==="

# Verificar status do supervisor
echo "1. Status do supervisor:"
sudo supervisorctl status

echo ""
echo "2. Verificando se o arquivo socket existe:"
ls -la /opt/s-agendamento/s-agendamento.sock

echo ""
echo "3. Verificando processos Django/Gunicorn:"
ps aux | grep -E "gunicorn|django" | grep -v grep

echo ""
echo "4. Verificando logs do Gunicorn:"
sudo tail -20 /opt/s-agendamento/logs/gunicorn.log 2>/dev/null || echo "Log não encontrado"

echo ""
echo "=== CORRECAO ==="
echo "5. Tentando iniciar o serviço:"
sudo supervisorctl start s-agendamento

echo ""
echo "6. Aguardando 3 segundos..."
sleep 3

echo ""
echo "7. Verificando status novamente:"
sudo supervisorctl status

echo ""
echo "8. Verificando socket:"
ls -la /opt/s-agendamento/s-agendamento.sock

echo ""
echo "=== TESTE ==="
echo "9. Testando conexão:"
curl -I http://localhost

