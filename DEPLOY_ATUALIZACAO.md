# 🚀 ATUALIZAR SERVIDOR AWS COM NOVO DEPLOY

## 📋 COMANDOS PARA EXECUTAR NO SERVIDOR

Acesse o servidor via EC2 Instance Connect e execute:

```bash
# 1. Ir para diretório da aplicação
cd /home/django/app

# 2. Fazer backup do .env.production (por segurança)
sudo cp /home/django/app/.env.production /home/django/app/.env.production.backup

# 3. Fazer pull das atualizações do GitHub
sudo -u django git pull origin main

# 4. Ativar venv e exportar variáveis
sudo -u django bash << 'EOF'
cd /home/django/app
source venv/bin/activate

# Exportar variáveis de ambiente
export DJANGO_SETTINGS_MODULE=core.settings_production
export DEBUG=False
export SECRET_KEY='!w8*p7423hq+i0xa2)(sk!0+fs5=gis_blcg-5fi7tds#si*5r'
export DB_NAME=agendamentos_db
export DB_USER=postgres
export DB_PASSWORD='4MindsAgendamento2025!SecureDB#Pass'
export DB_HOST=agendamento-4minds-postgres.cgr24gyuwi3d.us-east-1.rds.amazonaws.com
export DB_PORT=5432
export ALLOWED_HOSTS='fourmindstech.com.br,www.fourmindstech.com.br,13.221.138.11,localhost'

# Executar migrations (se houver novas)
python manage.py migrate --noinput

# Coletar arquivos estáticos (incluindo novos recursos)
python manage.py collectstatic --noinput --clear
EOF

# 5. Reiniciar Gunicorn
sudo supervisorctl restart gunicorn

# 6. Verificar status
sudo supervisorctl status

# 7. Verificar logs
sudo tail -20 /var/log/gunicorn/gunicorn.log

# 8. Testar health check
curl http://localhost/health/
```

---

## ✅ RESULTADO ESPERADO

```bash
# Status deve mostrar:
gunicorn                         RUNNING   pid 12345, uptime 0:00:05

# Health check deve retornar:
{"status":"ok","service":"sistema-agendamento","version":"1.0.0"}
```

---

## 🌐 TESTAR NO NAVEGADOR

Após atualizar, teste:

### Pelo IP:
```
http://13.221.138.11/admin/
```

### Pelo Domínio (se DNS já propagou):
```
http://fourmindstech.com.br/admin/
```

**Deve carregar:**
- ✅ Font Awesome (ícones)
- ✅ Google Fonts Inter (fonte)
- ✅ Plotly (gráficos)
- ✅ Bootstrap (estilos)
- ✅ Favicon (ícone da aba)
- ✅ Sem erros 404 no console

---

## 🐛 TROUBLESHOOTING

### Se Gunicorn não iniciar:

```bash
# Ver erro detalhado
sudo tail -50 /var/log/gunicorn/error.log

# Reiniciar
sudo supervisorctl stop gunicorn
sudo supervisorctl start gunicorn
```

### Se collectstatic falhar:

```bash
# Limpar e tentar novamente
sudo rm -rf /home/django/app/staticfiles/*
sudo -u django bash -c "cd /home/django/app && source venv/bin/activate && python manage.py collectstatic --noinput"
```

### Se ainda der 404 nos recursos:

```bash
# Verificar permissões
sudo chown -R django:django /home/django/app
sudo chmod -R 755 /home/django/app/static
sudo chmod -R 755 /home/django/app/staticfiles
```

---

**Criado:** Outubro 2025  
**Versão:** Final

