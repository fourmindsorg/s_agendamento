# 📊 GUIA DE LOGS NA AWS

## 🎯 Como Analisar Logs da Sua Aplicação

---

## 📋 MÉTODO 1: Logs no Servidor EC2 (Via SSH)

### 1. Acessar o Servidor

**Via EC2 Instance Connect (navegador):**
1. https://console.aws.amazon.com/ec2
2. Instances → `agendamento-4minds-web-server`
3. Connect → EC2 Instance Connect → Connect

---

### 2. Principais Arquivos de Log

#### 🔹 Logs do Django (Gunicorn)

```bash
# Ver logs em tempo real (mais recentes)
sudo tail -f /var/log/gunicorn/gunicorn.log

# Ver últimas 100 linhas
sudo tail -100 /var/log/gunicorn/gunicorn.log

# Ver logs de erro
sudo tail -f /var/log/gunicorn/error.log

# Ver logs de acesso
sudo tail -f /var/log/gunicorn/access.log

# Buscar por erro específico
sudo grep -i "error" /var/log/gunicorn/gunicorn.log

# Buscar por palavra-chave
sudo grep -i "database" /var/log/gunicorn/gunicorn.log
```

#### 🔹 Logs do Nginx

```bash
# Logs de erro do Nginx
sudo tail -f /var/log/nginx/error.log

# Logs de acesso (todas as requisições)
sudo tail -f /var/log/nginx/access.log

# Ver últimas 50 linhas
sudo tail -50 /var/log/nginx/access.log

# Filtrar por código de status (ex: 500, 404)
sudo grep "500" /var/log/nginx/access.log
sudo grep "404" /var/log/nginx/access.log
```

#### 🔹 Logs do User Data (Inicialização)

```bash
# Ver log completo de inicialização
sudo cat /var/log/user-data.log

# Ver últimas 100 linhas
sudo tail -100 /var/log/user-data.log

# Verificar se completou
sudo grep "Configuração concluída" /var/log/user-data.log
```

#### 🔹 Logs do Sistema (Syslog)

```bash
# Logs do sistema
sudo tail -f /var/log/syslog

# Logs de autenticação (SSH, sudo)
sudo tail -f /var/log/auth.log

# Logs do kernel
sudo dmesg | tail -50
```

#### 🔹 Logs do Supervisor

```bash
# Logs do Supervisor (gerenciador do Gunicorn)
sudo tail -f /var/log/supervisor/supervisord.log

# Status dos processos
sudo supervisorctl status
```

---

### 3. Comandos Úteis para Análise

#### 🔸 Buscar Erros

```bash
# Buscar todos os erros nas últimas 24h
sudo grep -i "error\|exception\|traceback" /var/log/gunicorn/gunicorn.log

# Contar quantos erros
sudo grep -c "ERROR" /var/log/gunicorn/gunicorn.log

# Buscar por data específica
sudo grep "2025-10-13" /var/log/gunicorn/access.log
```

#### 🔸 Monitorar em Tempo Real

```bash
# Ver múltiplos logs simultaneamente
sudo tail -f /var/log/gunicorn/gunicorn.log /var/log/nginx/error.log

# Com cores (instalar multitail se necessário)
sudo apt install -y multitail
sudo multitail /var/log/gunicorn/gunicorn.log /var/log/nginx/access.log
```

#### 🔸 Analisar Performance

```bash
# Requisições por minuto
sudo grep "$(date +%Y-%m-%d\ %H:%M)" /var/log/nginx/access.log | wc -l

# IPs mais frequentes
sudo awk '{print $1}' /var/log/nginx/access.log | sort | uniq -c | sort -nr | head -10

# URLs mais acessadas
sudo awk '{print $7}' /var/log/nginx/access.log | sort | uniq -c | sort -nr | head -10

# Códigos de status HTTP
sudo awk '{print $9}' /var/log/nginx/access.log | sort | uniq -c | sort -nr
```

---

## 📋 MÉTODO 2: Logs no CloudWatch (Via AWS Console)

### 1. Acessar CloudWatch

1. Acesse: https://console.aws.amazon.com/cloudwatch
2. Menu lateral: **"Logs"** → **"Log groups"**
3. Procure: `/aws/ec2/agendamento-4minds/django`
4. Clique no log group

---

### 2. Ver Log Streams

1. Você verá **log streams** (um por dia ou instância)
2. Clique no stream mais recente
3. Veja os logs em tempo real

---

### 3. Filtrar Logs

**Na barra de filtro:**

```bash
# Buscar por ERROR
ERROR

# Buscar por palavra específica
database

# Filtrar por múltiplas palavras
ERROR OR WARNING

# Excluir palavras
-health -static

# Buscar por padrão
[ERROR]
```

---

### 4. Insights (Queries)

1. Clique em **"Insights"**
2. Selecione o log group
3. Use queries:

```sql
# Contar erros por hora
fields @timestamp, @message
| filter @message like /ERROR/
| stats count() by bin(5m)

# Ver últimos 20 erros
fields @timestamp, @message
| filter @message like /ERROR/
| sort @timestamp desc
| limit 20

# Requisições lentas
fields @timestamp, @message
| filter @message like /slow/
| sort @timestamp desc
```

---

## 📋 MÉTODO 3: Logs via AWS CLI (No seu Windows)

### 1. Ver Logs em Tempo Real

```bash
# Tail do log group (últimas entradas)
aws logs tail /aws/ec2/agendamento-4minds/django --follow --region us-east-1

# Ver últimas 100 linhas
aws logs tail /aws/ec2/agendamento-4minds/django --since 1h --region us-east-1
```

---

### 2. Filtrar Logs

```bash
# Buscar por padrão
aws logs filter-log-events ^
  --log-group-name /aws/ec2/agendamento-4minds/django ^
  --filter-pattern "ERROR" ^
  --region us-east-1

# Logs das últimas 2 horas
aws logs filter-log-events ^
  --log-group-name /aws/ec2/agendamento-4minds/django ^
  --start-time $(python -c "import time; print(int((time.time()-7200)*1000))") ^
  --region us-east-1
```

---

### 3. Exportar Logs

```bash
# Exportar para arquivo
aws logs tail /aws/ec2/agendamento-4minds/django ^
  --since 24h ^
  --region us-east-1 > logs_ultimas_24h.txt

# Ver no editor
notepad logs_ultimas_24h.txt
```

---

## 📋 MÉTODO 4: Comandos Rápidos no Servidor

### Script de Diagnóstico Rápido

No servidor, execute:

```bash
# Criar script de diagnóstico
sudo tee /usr/local/bin/check-logs > /dev/null << 'EOF'
#!/bin/bash
echo "========================================="
echo "DIAGNÓSTICO DE LOGS - $(date)"
echo "========================================="
echo ""

echo "📊 STATUS DOS SERVIÇOS:"
echo "-----------------------"
sudo systemctl status nginx --no-pager | head -3
sudo supervisorctl status
echo ""

echo "📝 ÚLTIMAS 10 LINHAS - GUNICORN:"
echo "---------------------------------"
sudo tail -10 /var/log/gunicorn/gunicorn.log
echo ""

echo "🔴 ERROS RECENTES - GUNICORN:"
echo "-----------------------------"
sudo grep -i "error\|exception" /var/log/gunicorn/gunicorn.log | tail -5
echo ""

echo "🌐 ÚLTIMAS REQUISIÇÕES - NGINX:"
echo "-------------------------------"
sudo tail -5 /var/log/nginx/access.log
echo ""

echo "❌ ERROS NGINX:"
echo "---------------"
sudo grep -i "error" /var/log/nginx/error.log | tail -5
echo ""

echo "💾 USO DE DISCO:"
echo "----------------"
df -h | grep -E '(Filesystem|/$|/home)'
echo ""

echo "🧠 USO DE MEMÓRIA:"
echo "------------------"
free -h
echo ""

echo "========================================="
EOF

# Dar permissão de execução
sudo chmod +x /usr/local/bin/check-logs

# Executar
check-logs
```

**Agora você pode executar `check-logs` a qualquer momento!**

---

## 🔍 TROUBLESHOOTING COMUM

### ❌ Erro 502 Bad Gateway

```bash
# Verificar se Gunicorn está rodando
sudo supervisorctl status

# Ver erro do Gunicorn
sudo tail -50 /var/log/gunicorn/error.log

# Reiniciar se necessário
sudo supervisorctl restart gunicorn
```

---

### ❌ Erro 500 Internal Server Error

```bash
# Ver traceback completo
sudo tail -100 /var/log/gunicorn/error.log

# Geralmente é erro no código Django
# Verifique migrations, dependências, configurações
```

---

### ❌ CSS não carrega (404 em /static/)

```bash
# Verificar se collectstatic foi executado
ls -la /home/django/app/staticfiles/

# Re-executar collectstatic
sudo -u django bash -c "cd /home/django/app && source venv/bin/activate && python manage.py collectstatic --noinput"

# Reiniciar Nginx
sudo systemctl restart nginx
```

---

### ❌ Banco de dados não conecta

```bash
# Testar conexão PostgreSQL
psql -h agendamento-4minds-postgres.cgr24gyuwi3d.us-east-1.rds.amazonaws.com -U postgres -d agendamentos_db

# Verificar security group do RDS
aws rds describe-db-instances --db-instance-identifier agendamento-4minds-postgres --query 'DBInstances[0].VpcSecurityGroups'
```

---

## 📱 MÉTODO 5: Monitoramento via CloudWatch Alarms

### Ver Alarmes Ativos

```bash
# Via AWS CLI (no Windows)
aws cloudwatch describe-alarms --region us-east-1

# Ver apenas alarmes em estado de alerta
aws cloudwatch describe-alarms --state-value ALARM --region us-east-1
```

---

## 🎯 COMANDOS MAIS USADOS

### Top 10 Comandos de Log:

```bash
# 1. Ver logs Django em tempo real
sudo tail -f /var/log/gunicorn/gunicorn.log

# 2. Ver últimos erros
sudo grep -i "error" /var/log/gunicorn/error.log | tail -20

# 3. Status dos serviços
sudo supervisorctl status

# 4. Requisições recentes
sudo tail -20 /var/log/nginx/access.log

# 5. Erros Nginx
sudo tail -20 /var/log/nginx/error.log

# 6. Logs de inicialização
sudo tail -50 /var/log/user-data.log

# 7. Buscar traceback Python
sudo grep -A 10 "Traceback" /var/log/gunicorn/error.log

# 8. Uso de recursos
top
htop

# 9. Conexões ativas
sudo netstat -tulpn | grep -E '(nginx|gunicorn)'

# 10. Espaço em disco
df -h
```

---

## 💡 DICAS PROFISSIONAIS

### 1. Rotação de Logs

Os logs são automaticamente rotacionados pelo sistema, mas você pode configurar:

```bash
# Ver configuração de rotação
cat /etc/logrotate.d/nginx
cat /etc/logrotate.d/rsyslog
```

---

### 2. Limpar Logs Antigos

```bash
# Limpar logs com mais de 7 dias
sudo find /var/log -name "*.log" -mtime +7 -delete

# Limpar logs do Gunicorn manualmente
sudo truncate -s 0 /var/log/gunicorn/access.log
```

---

### 3. Download de Logs

Para baixar logs para seu computador:

```bash
# No seu Windows (via SCP - se tiver SSH funcionando)
scp -i chave.pem ubuntu@13.221.138.11:/var/log/gunicorn/gunicorn.log ./logs_local.txt

# Ou via CloudWatch (exportar)
aws logs create-export-task \
  --log-group-name /aws/ec2/agendamento-4minds/django \
  --from 1696291200000 \
  --to 1696377600000 \
  --destination your-s3-bucket \
  --destination-prefix logs/
```

---

## 📊 DASHBOARD DE LOGS

### Criar Arquivo de Monitoramento

No servidor:

```bash
# Criar dashboard simples
cat > ~/monitor.sh << 'EOF'
#!/bin/bash
while true; do
    clear
    echo "=== MONITOR - $(date) ==="
    echo ""
    echo "SERVIÇOS:"
    sudo supervisorctl status | head -5
    echo ""
    echo "CPU/MEMÓRIA:"
    top -bn1 | head -5
    echo ""
    echo "ÚLTIMAS REQUISIÇÕES:"
    sudo tail -5 /var/log/nginx/access.log
    echo ""
    echo "ÚLTIMOS ERROS:"
    sudo tail -3 /var/log/gunicorn/error.log
    sleep 5
done
EOF

chmod +x ~/monitor.sh

# Executar
~/monitor.sh
```

**Ctrl+C para sair**

---

## 🎯 COMANDOS PRÁTICOS PRONTOS

### Copie e Cole no Servidor:

#### Análise Rápida de Hoje:

```bash
echo "=== ANÁLISE DE LOGS DE HOJE ==="
echo ""
echo "Total de requisições hoje:"
sudo grep "$(date +%d/%b/%Y)" /var/log/nginx/access.log | wc -l
echo ""
echo "Erros hoje:"
sudo grep "$(date +%Y-%m-%d)" /var/log/gunicorn/error.log | grep -i "error" | wc -l
echo ""
echo "Últimos 5 erros:"
sudo grep "$(date +%Y-%m-%d)" /var/log/gunicorn/error.log | grep -i "error" | tail -5
```

#### Ver Logs da Última Hora:

```bash
echo "=== LOGS DA ÚLTIMA HORA ==="
sudo journalctl --since "1 hour ago" -u nginx
sudo journalctl --since "1 hour ago" -u supervisor
```

#### Estatísticas de Acesso:

```bash
echo "=== ESTATÍSTICAS ==="
echo "Top 10 IPs:"
sudo awk '{print $1}' /var/log/nginx/access.log | sort | uniq -c | sort -nr | head -10
echo ""
echo "Top 10 URLs:"
sudo awk '{print $7}' /var/log/nginx/access.log | sort | uniq -c | sort -nr | head -10
echo ""
echo "Códigos HTTP:"
sudo awk '{print $9}' /var/log/nginx/access.log | sort | uniq -c | sort -nr
```

---

## 🔔 MÉTODO 6: Alertas Automáticos (CloudWatch)

### Ver Alarmes:

```bash
# No seu Windows
aws cloudwatch describe-alarms --region us-east-1 --query 'MetricAlarms[*].[AlarmName,StateValue]' --output table
```

### Configurar Novos Alarmes:

```bash
# Exemplo: Alarme para erros 500
aws cloudwatch put-metric-alarm \
  --alarm-name agendamento-4minds-high-errors \
  --alarm-description "Alerta quando houver muitos erros 500" \
  --metric-name 5XXError \
  --namespace AWS/ApplicationELB \
  --statistic Sum \
  --period 300 \
  --threshold 10 \
  --comparison-operator GreaterThanThreshold \
  --region us-east-1
```

---

## 📱 MÉTODO 7: Logs via Smartphone

### CloudWatch Mobile App:

1. Baixe: **AWS Console Mobile App**
2. Login com suas credenciais
3. CloudWatch → Logs
4. Veja logs em tempo real no celular!

---

## 🎯 CHECKLIST DE DIAGNÓSTICO

Quando algo der errado, siga esta ordem:

1. [ ] Ver status dos serviços (`sudo supervisorctl status`)
2. [ ] Ver logs do Gunicorn (`sudo tail -50 /var/log/gunicorn/error.log`)
3. [ ] Ver logs do Nginx (`sudo tail -50 /var/log/nginx/error.log`)
4. [ ] Verificar uso de recursos (`top`, `df -h`)
5. [ ] Testar conexão banco (`psql -h ...`)
6. [ ] Reiniciar serviços se necessário
7. [ ] Ver logs do CloudWatch (se local não ajudar)

---

## 💡 FERRAMENTAS ADICIONAIS

### Instalar Ferramentas Úteis:

```bash
# No servidor
sudo apt install -y htop iotop ncdu

# htop - monitor de processos interativo
htop

# iotop - monitor de I/O
sudo iotop

# ncdu - analisador de disco
ncdu /var/log
```

---

## 🔍 EXEMPLOS PRÁTICOS

### Exemplo 1: Aplicação está lenta

```bash
# 1. Ver uso de CPU/RAM
top

# 2. Ver processos Python
ps aux | grep python

# 3. Ver logs de performance
sudo tail -100 /var/log/gunicorn/access.log | grep -E "time=[0-9]+"

# 4. Ver queries lentas (se Django debug toolbar estiver instalado)
sudo grep "SLOW" /var/log/gunicorn/gunicorn.log
```

---

### Exemplo 2: Erro 500 intermitente

```bash
# 1. Ver todos os tracebacks de hoje
sudo grep -A 20 "Traceback" /var/log/gunicorn/error.log | grep "$(date +%Y-%m-%d)"

# 2. Ver qual rota está falhando
sudo grep "500" /var/log/nginx/access.log | awk '{print $7}' | sort | uniq -c

# 3. Ver horário dos erros
sudo grep "500" /var/log/nginx/access.log | awk '{print $4}' | cut -d: -f2 | sort | uniq -c
```

---

### Exemplo 3: Usuário relatou erro

```bash
# Buscar por IP do usuário (substitua)
sudo grep "192.168.1.100" /var/log/nginx/access.log | tail -20

# Ver o que aconteceu numa hora específica
sudo grep "13:45:" /var/log/gunicorn/gunicorn.log
```

---

## 📞 REFERÊNCIAS

- **CloudWatch Logs:** https://docs.aws.amazon.com/cloudwatch/
- **Nginx Logs:** https://nginx.org/en/docs/debugging_log.html
- **Gunicorn Logs:** https://docs.gunicorn.org/en/stable/settings.html#logging

---

**Criado:** Outubro 2025  
**Status:** Pronto para uso  
**Autor:** Especialista AWS

