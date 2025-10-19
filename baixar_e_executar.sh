#!/bin/bash

# Script para baixar e executar diagnóstico na EC2

echo "📥 Baixando script de diagnóstico..."
curl -o diagnostico_ec2_rapido.sh https://raw.githubusercontent.com/fourmindsorg/s_agendamento/main/diagnostico_ec2_rapido.sh

echo "🔐 Dando permissão de execução..."
chmod +x diagnostico_ec2_rapido.sh

echo "🚀 Executando diagnóstico..."
./diagnostico_ec2_rapido.sh
