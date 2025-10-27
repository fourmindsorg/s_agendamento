# 🔄 Recriar Sistema do Zero no Servidor

## ⚠️ ATENÇÃO: Isso vai DELETAR o sistema atual!

## 📋 Passo a Passo Completo

### 1️⃣ Conectar no Servidor via SSH

```bash
ssh -i "infrastructure/s-agendamento-key.pem" ubuntu@ec2-52-91-139-151.compute-1.amazonaws.com
```

### 2️⃣ Fazer Backup do Sistema Atual

```bash
# Criar backup completo
sudo cp -r /opt/s-agendamento /opt/s-agendamento-backup-$(date +%Y%m%d-%H%M%S)

# Fazer backup do banco de dados
sudo cp /opt/s-agendamento/db.sqlite3 /opt/db.sqlite3.backup-$(date +%Y%m%d-%H%M%S)

# Verificar se backup foi criado
ls -lh /opt/s-agendamento-backup*
```

### 3️⃣ Parar Todos os Serviços

```bash
# Parar Gunicorn
sudo supervisorctl stop s-agendamento

# Parar qualquer processo Python antigo
sudo pkill -9 gunicorn
sudo pkill -9 python

# Verificar que tudo parou
ps aux | grep python
```

### 4️⃣ Remover Sistema Antigo

```bash
# Remover diretório antigo
sudo rm -rf /opt/s-agendamento

# Verificar que foi removido
ls -la /opt/s-agendamento
# Deve dar erro "No such file or directory"
```

### 5️⃣ Clonar Repositório Novo

```bash
# Ir para /opt
cd /opt

# Clonar repositório
sudo git clone https://github.com/fourmindsorg/s_agendamento.git s-agendamento

# Verificar clone
ls -la /opt/s-agendamento/
```

### 6️⃣ Configurar Ambiente Virtual

```bash
cd /opt/s-agendamento

# Criar venv
sudo python3 -m venv venv

# Ativar venv
source venv/bin/activate

# Instalar dependências
pip install --upgrade pip
pip install -r requirements.txt

# Verificar instalação
pip list | grep Django
```

### 7️⃣ Configurar Banco de Dados

```bash
cd /opt/s-agendamento

# Se tem backup do banco antigo, restaurar:
sudo cp /opt/db.sqlite3.backup-* /opt/s-agendamento/db.sqlite3

# OU rodar migrações do zero
python manage.py migrate
```

### 8️⃣ Coletar Arquivos Estáticos

```bash
python manage.py collectstatic --noinput
```

### 9️⃣ Configurar Supervisor

```bash
# Criar diretório de logs
sudo mkdir -p /opt/s-agendamento/logs

# Criar arquivo de configuração supervisor
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

# Carregar configuração
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start s-agendamento

# Verificar status
sudo supervisorctl status
```

### 🔟 Configurar Permissões e Nginx

```bash
# Ajustar permissões
sudo chown -R django:www-data /opt/s-agendamento
sudo chmod 755 /opt/s-agendamento
sudo chmod 666 /opt/s-agendamento/s-agendamento.sock || echo "Socket ainda não existe, será criado pelo supervisor"

# Recarregar Nginx
sudo systemctl reload nginx

# Verificar se Nginx está ok
sudo nginx -t
```

### 1️⃣1️⃣ Verificar Tudo

```bash
# Ver processos
ps aux | grep gunicorn

# Ver status do supervisor
sudo supervisorctl status

# Ver logs em tempo real (Ctrl+C para sair)
sudo tail -f /opt/s-agendamento/logs/gunicorn.log
```

### 1️⃣2️⃣ Testar

Aguarde 30 segundos e acesse:

```
https://fourmindstech.com.br/s_agendamentos/
```

---

## 🚨 Se Algo Der Errado

### Restaurar Sistema Antigo

```bash
# Parar novo sistema
sudo supervisorctl stop s-agendamento

# Remover sistema novo
sudo rm -rf /opt/s-agendamento

# Restaurar backup
sudo cp -r /opt/s-agendamento-backup-* /opt/s-agendamento

# Reiniciar
cd /opt/s-agendamento
source venv/bin/activate
sudo supervisorctl start s-agendamento
sudo systemctl reload nginx
```

---

## ✅ Checklist Final

- [ ] Backup criado
- [ ] Sistema antigo removido
- [ ] Repositório clonado
- [ ] Virtual environment configurado
- [ ] Dependências instaladas
- [ ] Migrações rodadas
- [ ] Static files coletados
- [ ] Supervisor configurado e rodando
- [ ] Nginx recarregado
- [ ] Site acessível
- [ ] Backup funcionando

---

## 📝 Comandos Úteis

```bash
# Ver logs
sudo tail -f /opt/s-agendamento/logs/gunicorn.log

# Reiniciar sistema
sudo supervisorctl restart s-agendamento

# Ver status
sudo supervisorctl status
sudo systemctl status nginx

# Testar localmente
curl http://localhost

# Ver últimos commits
cd /opt/s-agendamento && git log --oneline -5
```

