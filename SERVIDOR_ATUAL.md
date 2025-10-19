# 🌐 Informações do Servidor Atual - Sistema de Agendamento 4Minds

## 📊 Status do Servidor

**Última Atualização:** Outubro 2025  
**Status:** ✅ Online e Funcionando  
**Versão:** 2.0 (Produção)

---

## 🔗 URLs de Acesso

### 🌍 **Produção (Principal)**
- **Aplicação:** https://fourmindstech.com.br
- **Admin:** https://fourmindstech.com.br/admin/
- **Dashboard:** https://fourmindstech.com.br/dashboard/
- **API:** https://fourmindstech.com.br/api/

### 🧪 **Desenvolvimento**
- **Local:** http://127.0.0.1:8000
- **Admin Local:** http://127.0.0.1:8000/admin/

---

## 🏗️ Infraestrutura AWS

### **Servidor Principal**
- **Instância:** EC2 t2.micro (Ubuntu 22.04 LTS)
- **Região:** us-east-1 (N. Virginia)
- **IP Público:** 3.80.178.120
- **Domínio:** fourmindstech.com.br
- **SSL:** ✅ Ativo (Let's Encrypt)

### **Banco de Dados**
- **Tipo:** RDS PostgreSQL 15.4
- **Instância:** db.t2.micro
- **Região:** us-east-1
- **Backup:** ✅ Automático (7 dias)
- **Monitoramento:** ✅ CloudWatch

### **Armazenamento**
- **S3 Bucket:** Arquivos estáticos
- **CloudFront:** CDN (se configurado)
- **Backup:** ✅ Automático

---

## ⚙️ Configurações Técnicas

### **Backend**
- **Framework:** Django 5.2.6
- **Python:** 3.10+
- **Servidor WSGI:** Gunicorn 21.2.0
- **Proxy Reverso:** Nginx
- **Processos:** 3 workers

### **Frontend**
- **CSS Framework:** Bootstrap 5.3.0
- **Ícones:** Font Awesome 6.4.0
- **Gráficos:** Plotly.js
- **JavaScript:** Vanilla JS + jQuery

### **Banco de Dados**
- **Engine:** PostgreSQL 15.4
- **Pool de Conexões:** 10 conexões
- **Timeout:** 30 segundos
- **Charset:** UTF-8

### **Cache e Performance**
- **Cache:** Redis (opcional)
- **Arquivos Estáticos:** WhiteNoise + S3
- **Compressão:** Gzip ativo
- **CDN:** CloudFront (se configurado)

---

## 🔐 Credenciais de Acesso

### **Admin Django**
- **Usuário:** admin
- **Senha:** admin123
- **⚠️ IMPORTANTE:** Alterar após primeiro login

### **Banco de Dados**
- **Host:** [RDS Endpoint]
- **Porta:** 5432
- **Usuário:** postgres
- **Senha:** [Configurada via variáveis de ambiente]

### **SSH (EC2)**
- **Usuário:** ubuntu
- **Chave:** ~/.ssh/id_rsa
- **Porta:** 22

---

## 📈 Monitoramento

### **CloudWatch Metrics**
- **CPU Utilization:** < 80%
- **Memory Usage:** < 85%
- **Disk Usage:** < 90%
- **Network In/Out:** Monitorado

### **Logs Disponíveis**
- **Django Logs:** `/var/log/django/`
- **Nginx Logs:** `/var/log/nginx/`
- **Gunicorn Logs:** `/var/log/gunicorn/`
- **System Logs:** `/var/log/syslog`

### **Alertas Configurados**
- **CPU > 80%:** Email + SNS
- **Memory > 85%:** Email + SNS
- **Disk > 90%:** Email + SNS
- **RDS CPU > 80%:** Email + SNS

---

## 🚀 Deploy e CI/CD

### **Pipeline GitHub Actions**
- **Trigger:** Push para `main`
- **Testes:** Python 3.10 + 3.11
- **Linting:** Flake8
- **Deploy:** Automático para EC2
- **Tempo Médio:** ~5 minutos

### **Comandos de Deploy**
```bash
# Deploy automático (via GitHub)
git add .
git commit -m "Deploy: descrição da alteração"
git push origin main

# Deploy manual (via SSH)
ssh ubuntu@3.80.178.120
cd /opt/sistema-agendamento
git pull origin main
sudo systemctl restart gunicorn
sudo systemctl reload nginx
```

---

## 🔧 Manutenção

### **Atualizações de Sistema**
```bash
# Atualizar pacotes
sudo apt update && sudo apt upgrade -y

# Reiniciar serviços
sudo systemctl restart gunicorn
sudo systemctl restart nginx
sudo systemctl restart postgresql
```

### **Backup Manual**
```bash
# Backup do banco
pg_dump -h [RDS_ENDPOINT] -U postgres agendamentos_db > backup_$(date +%Y%m%d).sql

# Backup dos arquivos
tar -czf media_backup_$(date +%Y%m%d).tar.gz /opt/sistema-agendamento/media/
```

### **Logs e Debugging**
```bash
# Ver logs em tempo real
sudo journalctl -u gunicorn -f
sudo tail -f /var/log/nginx/error.log

# Status dos serviços
sudo systemctl status gunicorn
sudo systemctl status nginx
sudo systemctl status postgresql
```

---

## 📊 Métricas de Performance

### **Tempo de Resposta**
- **Página Inicial:** < 2 segundos
- **Dashboard:** < 3 segundos
- **API Endpoints:** < 1 segundo
- **Admin Interface:** < 2 segundos

### **Disponibilidade**
- **Uptime:** 99.9%
- **Downtime Mensal:** < 1 hora
- **Manutenção:** Domingos 2h-4h UTC

---

## 🛡️ Segurança

### **Configurações Ativas**
- **HTTPS:** ✅ Forçado (HTTP → HTTPS)
- **HSTS:** ✅ Ativo
- **CSP:** ✅ Configurado
- **Rate Limiting:** ✅ Ativo
- **CSRF Protection:** ✅ Ativo

### **Firewall (Security Groups)**
- **SSH (22):** Apenas IPs autorizados
- **HTTP (80):** 0.0.0.0/0 (redireciona para HTTPS)
- **HTTPS (443):** 0.0.0.0/0
- **PostgreSQL (5432):** Apenas EC2

### **Backup e Recuperação**
- **Backup Diário:** 2h UTC
- **Retenção:** 7 dias
- **Teste de Restore:** Mensal
- **Disaster Recovery:** < 4 horas

---

## 📞 Suporte e Contato

### **Equipe Técnica**
- **Desenvolvedor Principal:** 4Minds Team
- **Email:** fourmindsorg@gmail.com
- **GitHub:** https://github.com/fourmindsorg/s_agendamento

### **Horário de Suporte**
- **Segunda a Sexta:** 9h às 18h (Brasília)
- **Emergências:** 24/7 (via email)
- **SLA:** 4 horas para resposta

### **Documentação Adicional**
- **README Principal:** [README.md](../README.md)
- **Guia de Execução:** [COMO_EXECUTAR.md](../COMO_EXECUTAR.md)
- **Infraestrutura AWS:** [aws-infrastructure/README.md](aws-infrastructure/README.md)

---

## 🎯 Próximos Passos

### **Melhorias Planejadas**
- [ ] Implementar CDN CloudFront
- [ ] Adicionar Redis para cache
- [ ] Configurar backup automático para S3
- [ ] Implementar monitoramento APM
- [ ] Adicionar testes de carga

### **Manutenção Preventiva**
- [ ] Atualizar dependências mensalmente
- [ ] Revisar logs semanalmente
- [ ] Testar backup mensalmente
- [ ] Atualizar certificados SSL
- [ ] Revisar configurações de segurança

---

**Última Verificação:** Outubro 2025  
**Próxima Revisão:** Novembro 2025  
**Responsável:** 4Minds Team

🚀 **Sistema Online e Funcionando!**
