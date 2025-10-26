#!/bin/bash
# Comandos para executar no servidor para corrigir Django

echo "=== COMANDOS PARA EXECUTAR NO SERVIDOR ==="
echo "SSH no servidor EC2 e execute os comandos abaixo:"
echo ""

echo "# 1. Verificar se o projeto Django existe"
echo "ls -la /opt/s-agendamento/"
echo ""

echo "# 2. Verificar logs do Supervisor"
echo "sudo tail -20 /opt/s-agendamento/logs/gunicorn.log"
echo ""

echo "# 3. Verificar configuração do Supervisor"
echo "sudo cat /etc/supervisor/conf.d/s-agendamento.conf"
echo ""

echo "# 4. Ir para o diretório do projeto"
echo "cd /opt/s-agendamento"
echo ""

echo "# 5. Verificar se manage.py existe"
echo "ls -la manage.py"
echo ""

echo "# 6. Testar Django diretamente"
echo "sudo -u django bash -c 'cd /opt/s-agendamento && source venv/bin/activate && python manage.py check'"
echo ""

echo "# 7. Se houver erro, verificar dependências"
echo "sudo -u django bash -c 'cd /opt/s-agendamento && source venv/bin/activate && pip list'"
echo ""

echo "# 8. Se necessário, reinstalar dependências"
echo "sudo -u django bash -c 'cd /opt/s-agendamento && source venv/bin/activate && pip install -r requirements.txt'"
echo ""

echo "# 9. Executar migrações"
echo "sudo -u django bash -c 'cd /opt/s-agendamento && source venv/bin/activate && python manage.py migrate'"
echo ""

echo "# 10. Coletar arquivos estáticos"
echo "sudo -u django bash -c 'cd /opt/s-agendamento && source venv/bin/activate && python manage.py collectstatic --noinput'"
echo ""

echo "# 11. Testar Django na porta 8000"
echo "sudo -u django bash -c 'cd /opt/s-agendamento && source venv/bin/activate && python manage.py runserver 127.0.0.1:8000 &'"
echo "sleep 5"
echo "curl -I http://127.0.0.1:8000"
echo "pkill -f 'python manage.py runserver'"
echo ""

echo "# 12. Se funcionar, configurar Gunicorn"
echo "sudo -u django bash -c 'cd /opt/s-agendamento && source venv/bin/activate && gunicorn --bind 127.0.0.1:8000 --workers 3 core.wsgi:application &'"
echo "sleep 5"
echo "curl -I http://127.0.0.1:8000"
echo "pkill -f gunicorn"
echo ""

echo "# 13. Atualizar configuração do Supervisor"
echo "sudo tee /etc/supervisor/conf.d/s-agendamento.conf > /dev/null <<'EOF'"
echo "[program:s-agendamento]"
echo "command=/opt/s-agendamento/venv/bin/gunicorn --bind 127.0.0.1:8000 --workers 3 core.wsgi:application"
echo "directory=/opt/s-agendamento"
echo "user=django"
echo "autostart=true"
echo "autorestart=true"
echo "redirect_stderr=true"
echo "stdout_logfile=/opt/s-agendamento/logs/gunicorn.log"
echo "environment=PATH=\"/opt/s-agendamento/venv/bin\""
echo "EOF"
echo ""

echo "# 14. Recarregar Supervisor"
echo "sudo supervisorctl reread"
echo "sudo supervisorctl update"
echo "sudo supervisorctl restart s-agendamento"
echo ""

echo "# 15. Verificar status"
echo "sudo supervisorctl status s-agendamento"
echo "curl -I http://127.0.0.1:8000"
echo "curl -I https://fourmindstech.com.br/s_agendamentos/"
echo ""

echo "=== COMANDOS RÁPIDOS (se o projeto não existir) ==="
echo ""
echo "# Se o projeto não existir, criar estrutura básica:"
echo "sudo mkdir -p /opt/s-agendamento"
echo "sudo chown django:django /opt/s-agendamento"
echo "cd /opt/s-agendamento"
echo ""
echo "# Clonar repositório ou criar projeto básico"
echo "sudo -u django git clone https://github.com/4Minds-Team/s-agendamento.git ."
echo "# OU criar projeto Django básico se não houver repositório"
echo ""

echo "=== RESULTADO ESPERADO ==="
echo ""
echo "Após executar os comandos:"
echo "✅ Django rodando na porta 8000"
echo "✅ Supervisor gerenciando o serviço"
echo "✅ HTTPS funcionando: https://fourmindstech.com.br/s_agendamentos/"
echo "✅ Admin funcionando: https://fourmindstech.com.br/admin/"
echo ""

