#!/bin/bash
# Script para verificar e corrigir o estado da instância EC2

set -e

INSTANCE_ID="i-0077873407e4114b1"

echo "🔍 Verificando estado da instância EC2..."
STATE=$(aws ec2 describe-instances \
  --instance-ids "$INSTANCE_ID" \
  --query "Reservations[0].Instances[0].State.Name" \
  --output text)

IP=$(aws ec2 describe-instances \
  --instance-ids "$INSTANCE_ID" \
  --query "Reservations[0].Instances[0].PublicIpAddress" \
  --output text)

echo "📍 Estado: $STATE"
echo "📍 IP: $IP"

if [ "$STATE" == "stopped" ]; then
    echo ""
    echo "🔧 Instância está PARADA. Iniciando..."
    aws ec2 start-instances --instance-ids "$INSTANCE_ID"
    
    echo "⏳ Aguardando instância iniciar (2-3 minutos)..."
    aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"
    
    echo "✅ Instância iniciada!"
    echo ""
    echo "⏳ Aguardando SSM ficar online (1-2 minutos)..."
    sleep 60
    
    echo ""
    echo "✅ Pronto! Agora faça o deploy:"
    echo "   aws ssm start-session --target $INSTANCE_ID"
    echo ""
    echo "   Dentro da sessão:"
    echo "   cd /opt/s-agendamento"
    echo "   sudo bash infrastructure/deploy_completo.sh"
    
elif [ "$STATE" == "running" ]; then
    echo "✅ Instância está RODANDO"
    echo ""
    echo "🔍 Verificando SSM..."
    SSM_STATUS=$(aws ssm describe-instance-information \
      --filters "Key=InstanceIds,Values=$INSTANCE_ID" \
      --query "InstanceInformationList[0].PingStatus" \
      --output text 2>/dev/null || echo "Inacessível")
    
    echo "📍 SSM Status: $SSM_STATUS"
    
    if [ "$SSM_STATUS" == "Online" ]; then
        echo "✅ SSM está online! Faça o deploy:"
        echo ""
        echo "   aws ssm start-session --target $INSTANCE_ID"
        echo ""
        echo "   Dentro da sessão:"
        echo "   cd /opt/s-agendamento"
        echo "   sudo bash infrastructure/deploy_completo.sh"
    else
        echo "⚠️ SSM não está acessível"
        echo ""
        echo "💡 Faça deploy via SSH:"
        echo "   ssh ubuntu@$IP"
        echo ""
        echo "   Dentro da sessão:"
        echo "   cd /opt/s-agendamento"
        echo "   sudo bash infrastructure/deploy_completo.sh"
    fi
    
else
    echo "⚠️ Estado não suportado: $STATE"
    echo ""
    echo "💡 Execute o deploy manual via SSH (se possível):"
    echo "   ssh ubuntu@$IP"
    echo ""
    echo "   ou inicie a instância:"
    echo "   aws ec2 start-instances --instance-ids $INSTANCE_ID"
fi

