#!/bin/bash
echo "=== DIAGNÓSTICO EC2 ==="
cd /home/ubuntu
pwd
whoami
ls -la
echo "=== VERIFICANDO S_AGENDAMENTO ==="
if [ -d "s_agendamento" ]; then
    echo "Diretório existe"
    cd s_agendamento
    ls -la
else
    echo "Diretório não existe"
fi
echo "=== VERIFICANDO SERVIÇOS ==="
sudo systemctl is-active gunicorn || echo "Gunicorn inativo"
sudo systemctl is-active nginx || echo "Nginx inativo"
echo "=== TESTANDO CONECTIVIDADE ==="
timeout 5 curl -I http://localhost:8000/ 2>/dev/null && echo "Localhost OK" || echo "Localhost falhou"
timeout 5 curl -I http://3.80.178.120/ 2>/dev/null && echo "IP externo OK" || echo "IP externo falhou"
echo "=== PROCESSOS ==="
ps aux | grep python | grep -v grep || echo "Nenhum Python"
ps aux | grep gunicorn | grep -v grep || echo "Nenhum Gunicorn"
ps aux | grep nginx | grep -v grep || echo "Nenhum Nginx"
echo "=== DIAGNÓSTICO CONCLUÍDO ==="
