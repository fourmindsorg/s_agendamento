#!/bin/bash
echo "=== CORRIGINDO SERVIÇO DJANGO ==="

# 1. Parar todos os serviços
sudo supervisorctl stop s-agendamento
sudo systemctl stop nginx

# 2. Ir para o diretório do projeto
cd /opt/s-agendamento

# 3. Verificar se o projeto existe
if [ ! -f manage.py ]; then
    echo "❌ Projeto Django não encontrado!"
    echo "Instalando projeto..."
    
    # Clonar repositório se necessário
    sudo git clone https://github.com/4Minds-Team/s-agendamento.git /opt/s-agendamento-temp
    sudo cp -r /opt/s-agendamento-temp/* /opt/s-agendamento/
    sudo rm -rf /opt/s-agendamento-temp
fi

# 4. Configurar permissões
sudo chown -R django:django /opt/s-agendamento
sudo chmod -R 755 /opt/s-agendamento

# 5. Ativar ambiente virtual
sudo -u django bash -c "cd /opt/s-agendamento && source venv/bin/activate"

# 6. Instalar dependências
sudo -u django bash -c "cd /opt/s-agendamento && source venv/bin/activate && pip install -r requirements.txt"

# 7. Configurar variáveis de ambiente
sudo -u django tee /opt/s-agendamento/.env > /dev/null <<'ENV_EOF'
DEBUG=False
SECRET_KEY=your-secret-key-here
DB_NAME=agendamento_db
DB_USER=agendamento_user
DB_PASSWORD=Agendamento123!
DB_HOST=s-agendamento-db.c1234567890.us-east-1.rds.amazonaws.com
DB_PORT=5432
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
AWS_STORAGE_BUCKET_NAME_STATIC=s-agendamento-static-exxyawpx
AWS_STORAGE_BUCKET_NAME_MEDIA=s-agendamento-media-exxyawpx
AWS_S3_REGION_NAME=us-east-1
ENV_EOF

# 8. Executar migrações
sudo -u django bash -c "cd /opt/s-agendamento && source venv/bin/activate && python manage.py migrate"

# 9. Coletar arquivos estáticos
sudo -u django bash -c "cd /opt/s-agendamento && source venv/bin/activate && python manage.py collectstatic --noinput"

# 10. Criar superusuário se não existir
sudo -u django bash -c "cd /opt/s-agendamento && source venv/bin/activate && echo 'from django.contrib.auth import get_user_model; User = get_user_model(); User.objects.filter(username=\"admin\").exists() or User.objects.create_superuser(\"admin\", \"admin@example.com\", \"admin123\")' | python manage.py shell"

# 11. Configurar Supervisor
sudo tee /etc/supervisor/conf.d/s-agendamento.conf > /dev/null <<'SUPERVISOR_EOF'
[program:s-agendamento]
command=/opt/s-agendamento/venv/bin/gunicorn --bind 127.0.0.1:8000 --workers 3 core.wsgi:application
directory=/opt/s-agendamento
user=django
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/opt/s-agendamento/logs/gunicorn.log
environment=PATH="/opt/s-agendamento/venv/bin"
SUPERVISOR_EOF

# 12. Criar diretório de logs
sudo mkdir -p /opt/s-agendamento/logs
sudo chown django:django /opt/s-agendamento/logs

# 13. Recarregar Supervisor
sudo supervisorctl reread
sudo supervisorctl update

# 14. Iniciar serviços
sudo supervisorctl start s-agendamento
sudo systemctl start nginx

# 15. Verificar status
echo "Verificando status dos serviços..."
sudo supervisorctl status s-agendamento
sudo systemctl status nginx --no-pager

# 16. Testar conectividade
echo "Testando conectividade..."
sleep 5
curl -I http://127.0.0.1:8000 --connect-timeout 5

echo "=== SERVIÇO DJANGO CORRIGIDO ==="

