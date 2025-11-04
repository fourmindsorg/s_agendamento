#!/bin/bash
# Script para descobrir como o Django está rodando

echo "=========================================="
echo "🔍 Verificando como o Django está rodando"
echo "=========================================="
echo ""

# 1. Verificar serviços systemd
echo "📋 Serviços systemd relacionados:"
sudo systemctl list-units --type=service --all | grep -E "(agendamento|django|gunicorn|uwsgi)" || echo "   Nenhum serviço encontrado"
echo ""

# 2. Verificar supervisor
echo "📋 Serviços supervisor:"
if command -v supervisorctl &> /dev/null; then
    sudo supervisorctl status 2>/dev/null || echo "   Supervisor não configurado"
else
    echo "   Supervisor não instalado"
fi
echo ""

# 3. Verificar processos Python/Django
echo "📋 Processos Python rodando:"
ps aux | grep -E "(python|gunicorn|uwsgi)" | grep -v grep || echo "   Nenhum processo encontrado"
echo ""

# 4. Verificar screen/tmux
echo "📋 Sessões screen:"
screen -ls 2>/dev/null || echo "   Nenhuma sessão screen"
echo ""

echo "📋 Sessões tmux:"
tmux ls 2>/dev/null || echo "   Nenhuma sessão tmux"
echo ""

# 5. Verificar se há arquivo de serviço
echo "📋 Arquivos de serviço systemd:"
ls -la /etc/systemd/system/*.service 2>/dev/null | grep -E "(agendamento|django|gunicorn)" || echo "   Nenhum arquivo encontrado"
echo ""

echo "=========================================="
echo "✅ Verificação concluída"
echo "=========================================="

