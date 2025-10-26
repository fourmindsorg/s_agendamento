# 🚨 RESOLVER ERRO 502 BAD GATEWAY - COMANDOS PARA EXECUTAR

## ⚠️ Problema Atual
- Erro: `502 Bad Gateway` em https://fourmindstech.com.br/s_agendamentos/
- Causa: Django/Gunicorn não está rodando no servidor

## ✅ Solução Rápida

### Opção 1: Comandos Sequenciais (Copie e Cole)

```bash
# 1. Verificar estado
aws ec2 describe-instances \
  --instance-ids i-0077873407e4114b1 \
  --query 'Reservations[0].Instances[0].[State.Name,PublicIpAddress]' \
  --output table

# 2. Se estiver "stopped", iniciar:
aws ec2 start-instances --instance-ids i-0077873407e4114b1
aws ec2 wait instance-running --instance-ids i-0077873407e4114b1

# 3. Obter IP
aws ec2 describe-instances \
  --instance-ids i-0077873407e4114b1 \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text

# 4. Conectar (USE O IP DA LINHA ANTERIOR)
# Substitua IP_AQUI pelo IP obtido
ssh ubuntu@IP_AQUI
```

Dentro do servidor (após conectar):
```bash
cd /opt/s-agendamento
sudo supervisorctl restart s-agendamento
sudo systemctl reload nginx
sudo supervisorctl status s-agendamento
exit
```

### Opção 2: Via SSM (Recomendado se configurado)

```bash
# Conectar via SSM
aws ssm start-session --target i-0077873407e4114b1
```

Dentro da sessão:
```bash
cd /opt/s-agendamento
sudo supervisorctl restart s-agendamento
sudo systemctl reload nginx
sudo supervisorctl status
exit
```

### Opção 3: Comando SSH Direto (Uma Linha)

Substitua `<IP>` pelo IP da instância:

```bash
ssh ubuntu@<IP> "cd /opt/s-agendamento && sudo supervisorctl restart s-agendamento && sudo systemctl reload nginx"
```

### Opção 4: Via AWS CLI (SSM Send-Command)

```bash
aws ssm send-command \
  --instance-ids i-0077873407e4114b1 \
  --document-name "AWS-RunShellScript" \
  --parameters 'commands=[
    "cd /opt/s-agendamento",
    "sudo supervisorctl restart s-agendamento",
    "sudo systemctl reload nginx",
    "echo ✅ Serviços reiniciados!"
  ]'
```

## 🔍 Diagnóstico

Se o problema persistir, conecte e execute:

```bash
# Verificar status
sudo supervisorctl status
sudo systemctl status nginx

# Ver logs
sudo tail -50 /opt/s-agendamento/logs/gunicorn.log
sudo tail -50 /var/log/nginx/error.log

# Verificar se o socket existe
ls -la /opt/s-agendamento/s-agendamento.sock

# Testar Django
cd /opt/s-agendamento
source venv/bin/activate
python manage.py check
```

## 🛠️ Solução Completa (Se Nada Funcionar)

Se reiniciar não resolver, faça o deploy completo:

```bash
aws ssm start-session --target i-0077873407e4114b1
cd /opt/s-agendamento
sudo bash infrastructure/deploy_completo.sh
```

## ✅ Teste Após Correção

Aguarde 10-15 segundos após os comandos acima e teste:

```bash
# Testar HTTP
curl -I http://52.91.139.151/s_agendamentos/

# Testar HTTPS
curl -I https://fourmindstech.com.br/s_agendamentos/
```

Se retornar `200 OK` ou conteúdo HTML = ✅ **PROBLEMA RESOLVIDO!**

## 📝 Explicação

O erro **502 Bad Gateway** acontece quando:
1. ✅ Nginx está rodando (servidor web OK)
2. ❌ Django/Gunicorn não está rodando (aplicação parada)

Soluções:
- `sudo supervisorctl restart s-agendamento` - Reinicia o Django
- `sudo systemctl reload nginx` - Recarrega o Nginx
- Ambos devem rodar simultaneamente

