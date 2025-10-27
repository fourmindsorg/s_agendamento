# 🔍 Comparar Código entre Desenvolvimento e Produção

## Problema
O código em produção está diferente do desenvolvimento mesmo após tentativas de atualização.

## Análise Necessária

### No servidor, execute:

```bash
# 1. Ver quando arquivos foram modificados
echo "=== PRODUÇÃO ==="
find /opt/s-agendamento -type f -name "*.html" -exec ls -lh {} \; | head -10

echo "=== CLONE RECENTE ==="  
find /home/ubuntu/s_agendamento -type f -name "*.html" -exec ls -lh {} \; | head -10

# 2. Comparar tamanho de arquivos específicos
echo "=== PRODUÇÃO ==="
ls -lh /opt/s-agendamento/agendamentos/templates/agendamentos/home.html

echo "=== CLONE ==="
ls -lh /home/ubuntu/s_agendamento/agendamentos/templates/agendamentos/home.html

# 3. Ver hash dos arquivos
echo "=== PRODUÇÃO ==="
md5sum /opt/s-agendamento/manage.py

echo "=== CLONE ==="
md5sum /home/ubuntu/s_agendamento/manage.py

# 4. Ver se Gunicorn está usando código antigo em memória
ps aux | grep gunicorn
# Anotar o PID e executar:
# sudo ls -l /proc/[PID]/exe

# 5. Ver quando sistema foi iniciado
sudo supervisorctl status
systemctl status s-agendamento

# 6. Ver últimos commits no Git
echo "=== ÚLTIMOS COMMITS (CLONE) ==="
cd /home/ubuntu/s_agendamento && git log --oneline -5
```

## Diagnóstico Provável

### Cenário 1: Arquivos não foram copiados
- **Indicador**: Datas de modificação antigas em `/opt/s-agendamento`
- **Solução**: Seguir comando da seção "Solução Definitiva" no arquivo `DIAGNOSTICO_COMPLETO.txt`

### Cenário 2: Processo Python antigo em memória
- **Indicador**: Gunicorn rodando com PID antigo antes da cópia
- **Solução**: Matar todos processos e reiniciar
```bash
sudo pkill -9 gunicorn
sudo pkill -9 python
sudo supervisorctl restart s-agendamento
```

### Cenário 3: Cache do navegador
- **Indicador**: Site mostra versão antiga mas servidor tem código novo
- **Solução**: Limpar cache do navegador (Ctrl+Shift+Delete) ou usar modo anônimo

### Cenário 4: Permissões impedindo leitura de arquivos novos
- **Indicador**: Erros de "permission denied" nos logs
- **Solução**: Ajustar permissões conforme `DIAGNOSTICO_COMPLETO.txt`

## Comando de Comparação Direta

Execute para comparar:

```bash
# Comparar estrutura de diretórios
diff -r /opt/s-agendamento/agendamentos /home/ubuntu/s_agendamento/agendamentos | head -50

# Ver diferenças de arquivo específico
diff /opt/s-agendamento/agendamentos/templates/agendamentos/home.html \
     /home/ubuntu/s_agendamento/agendamentos/templates/agendamentos/home.html | head -100
```

## Solução Garantida

Se nada funcionar, fazer deploy completo:

```bash
# 1. Parar tudo
sudo supervisorctl stop s-agendamento
sudo pkill -9 gunicorn

# 2. Backup
sudo mv /opt/s-agendamento /opt/s-agendamento-old-$(date +%Y%m%d)

# 3. Copiar todo o clone novo
sudo cp -r /home/ubuntu/s_agendamento /opt/s-agendamento

# 4. Configurar ambiente
cd /opt/s-agendamento
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# 5. Migrar banco
python manage.py migrate

# 6. Coletar static
python manage.py collectstatic --noinput

# 7. Configurar supervisor
sudo tee /etc/supervisor/conf.d/s-agendamento.conf > /dev/null <<'EOF'
[program:s-agendamento]
command=/opt/s-agendamento/venv/bin/gunicorn s_agendamento.wsgi:application --bind unix:/opt/s-agendamento/s-agendamento.sock --workers 3
directory=/opt/s-agendamento
user=django
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/opt/s-agendamento/logs/gunicorn.log
environment=PATH="/opt/s-agendamento/venv/bin"
EOF

# 8. Iniciar
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start s-agendamento
sudo systemctl restart nginx
```

