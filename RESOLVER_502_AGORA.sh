#!/bin/bash
# Script para resolver erro 502 Bad Gateway

echo "🔍 Resolvendo erro 502 Bad Gateway..."
echo ""

INSTANCE_ID="i-0077873407e4114b1"

# 1. Verificar e iniciar instância se necessário
echo "1️⃣ Verificando estado da instância..."
STATE=$(aws ec2 describe-instances \
  --instance-ids "$INSTANCE_ID" \
  --query "Reservations[0].Instances[0].State.Name" \
  --output text)

echo "   Estado: $STATE"

if [ "$STATE" == "stopped" ]; then
    echo "   ⚠️ Instância parada. Iniciando..."
    aws ec2 start-instances --instance-ids "$INSTANCE_ID"
    aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"
    echo "   ✅ Instância iniciada!"
    sleep 30
fi

# 2. Obter IP
echo ""
echo "2️⃣ Obtendo IP da instância..."
IP=$(aws ec2 describe-instances \
  --instance-ids "$INSTANCE_ID" \
  --query "Reservations[0].Instances[0].PublicIpAddress" \
  --output text)
echo "   IP: $IP"

# 3. Conectar e corrigir
echo ""
echo "3️⃣ Conectando e reiniciando serviços..."
echo "   (Vai pedir senha SSH ou usar chave configurada)"
echo ""

ssh ubuntu@$IP << 'ENDSSH'
cd /opt/s-agendamento
echo "📍 Diretório: $(pwd)"

echo "🔄 Reiniciando Gunicorn..."
sudo supervisorctl restart s-agendamento

echo "🔄 Recarregando Nginx..."
sudo systemctl reload nginx

echo "📊 Status dos serviços:"
sudo supervisorctl status s-agendamento
sudo systemctl is-active nginx

echo ""
echo "✅ Serviços reiniciados!"
ENDSSH

echo ""
echo "4️⃣ Aguardando serviços iniciarem..."
sleep 10

echo ""
echo "5️⃣ Testando conexão..."
echo "   Acesse: https://fourmindstech.com.br/s_agendamentos/"
echo ""
echo "✅ Se ainda der erro 502, execute:"
echo "   aws ssm start-session --target $INSTANCE_ID"
echo "   cd /opt/s-agendamento"
echo "   sudo bash infrastructure/deploy_completo.sh"

