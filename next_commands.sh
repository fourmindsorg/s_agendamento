#!/bin/bash
# Próximos comandos para executar após instalar dependências

echo "=== PRÓXIMOS COMANDOS PARA EXECUTAR ==="
echo "Execute os comandos abaixo no servidor EC2:"
echo ""

echo "# 1. Verificar se as dependências foram instaladas"
echo "sudo -u django bash -c 'cd /opt/s-agendamento && source venv/bin/activate && pip list | grep Django'"
echo ""

echo "# 2. Executar migrações do banco de dados"
echo "sudo -u django bash -c 'cd /opt/s-agendamento && source venv/bin/activate && python manage.py migrate'"
echo ""

echo "# 3. Coletar arquivos estáticos"
echo "sudo -u django bash -c 'cd /opt/s-agendamento && source venv/bin/activate && python manage.py collectstatic --noinput'"
echo ""

echo "# 4. Criar superusuário admin (se não existir)"
echo "sudo -u django bash -c 'cd /opt/s-agendamento && source venv/bin/activate && echo \"from django.contrib.auth import get_user_model; User = get_user_model(); User.objects.filter(username=\\\"admin\\\").exists() or User.objects.create_superuser(\\\"admin\\\", \\\"admin@example.com\\\", \\\"admin123\\\")\" | python manage.py shell'"
echo ""

echo "# 5. Testar Django diretamente"
echo "sudo -u django bash -c 'cd /opt/s-agendamento && source venv/bin/activate && python manage.py check'"
echo ""

echo "# 6. Testar Django na porta 8000"
echo "sudo -u django bash -c 'cd /opt/s-agendamento && source venv/bin/activate && python manage.py runserver 127.0.0.1:8000 &'"
echo "sleep 5"
echo "curl -I http://127.0.0.1:8000"
echo "pkill -f 'python manage.py runserver'"
echo ""

echo "# 7. Se funcionar, testar Gunicorn"
echo "sudo -u django bash -c 'cd /opt/s-agendamento && source venv/bin/activate && gunicorn --bind 127.0.0.1:8000 --workers 3 core.wsgi:application &'"
echo "sleep 5"
echo "curl -I http://127.0.0.1:8000"
echo "pkill -f gunicorn"
echo ""

echo "# 8. Configurar Supervisor"
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

echo "# 9. Recarregar e iniciar Supervisor"
echo "sudo supervisorctl reread"
echo "sudo supervisorctl update"
echo "sudo supervisorctl restart s-agendamento"
echo ""

echo "# 10. Verificar status final"
echo "sudo supervisorctl status s-agendamento"
echo "curl -I http://127.0.0.1:8000"
echo "curl -I https://fourmindstech.com.br/s_agendamentos/"
echo ""

echo "=== COMANDOS DE VERIFICAÇÃO ==="
echo ""
echo "# Se houver erro, verificar logs:"
echo "sudo tail -20 /opt/s-agendamento/logs/gunicorn.log"
echo "sudo tail -20 /var/log/nginx/error.log"
echo ""

echo "# Verificar se o projeto está correto:"
echo "ls -la /opt/s-agendamento/"
echo "ls -la /opt/s-agendamento/manage.py"
echo ""

echo "# Verificar configuração do Django:"
echo "sudo -u django bash -c 'cd /opt/s-agendamento && source venv/bin/activate && python manage.py check --deploy'"
echo ""

echo "=== RESULTADO ESPERADO ==="
echo ""
echo "Após executar todos os comandos:"
echo "✅ Django funcionando na porta 8000"
echo "✅ Supervisor gerenciando o serviço"
echo "✅ HTTPS funcionando: https://fourmindstech.com.br/s_agendamentos/"
echo "✅ Admin funcionando: https://fourmindstech.com.br/admin/"
echo ""



