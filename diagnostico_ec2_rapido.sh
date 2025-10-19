#!/bin/bash

# Script de Diagnóstico Rápido para EC2
# Execute este script na EC2 para verificar o que aconteceu (sem travamentos)

echo "🔍 DIAGNÓSTICO RÁPIDO DA EC2"
echo "============================="

echo "📁 Verificando diretório do projeto..."
cd /home/ubuntu
ls -la

echo ""
echo "📂 Verificando se s_agendamento existe..."
if [ -d "s_agendamento" ]; then
    echo "✅ Diretório s_agendamento existe"
    cd s_agendamento
    echo "📋 Conteúdo do diretório:"
    ls -la
    echo ""
    echo "🐍 Verificando ambiente virtual..."
    if [ -d ".venv" ]; then
        echo "✅ Ambiente virtual existe"
        source .venv/bin/activate
        echo "📦 Verificando dependências Python principais..."
        pip list | grep -E "(django|gunicorn|psycopg2)" || echo "❌ Dependências Python não encontradas"
    else
        echo "❌ Ambiente virtual não existe"
    fi
    echo ""
    echo "⚙️ Verificando arquivo .env..."
    if [ -f ".env" ]; then
        echo "✅ Arquivo .env existe"
        echo "📋 Primeiras linhas do .env:"
        head -5 .env
    else
        echo "❌ Arquivo .env não existe"
    fi
else
    echo "❌ Diretório s_agendamento não existe"
fi

echo ""
echo "🔧 Verificando serviços do sistema..."
echo "📊 Status do Gunicorn:"
sudo systemctl is-active gunicorn || echo "❌ Gunicorn não está ativo"

echo ""
echo "📊 Status do Nginx:"
sudo systemctl is-active nginx || echo "❌ Nginx não está ativo"

echo ""
echo "🌐 Testando conectividade (com timeout)..."
echo "Testando localhost (timeout 5s):"
timeout 5 curl -I http://localhost:8000/ 2>/dev/null && echo "✅ Localhost responde" || echo "❌ Localhost não responde"

echo "Testando IP externo (timeout 5s):"
timeout 5 curl -I http://3.80.178.120/ 2>/dev/null && echo "✅ IP externo responde" || echo "❌ IP externo não responde"

echo ""
echo "📋 Verificando logs do Gunicorn (últimas 5 linhas):"
sudo journalctl -u gunicorn --no-pager -n 5

echo ""
echo "📋 Verificando logs do Nginx (últimas 5 linhas):"
sudo journalctl -u nginx --no-pager -n 5

echo ""
echo "🔍 Verificando processos Python:"
ps aux | grep python | grep -v grep || echo "❌ Nenhum processo Python encontrado"

echo ""
echo "🔍 Verificando processos Gunicorn:"
ps aux | grep gunicorn | grep -v grep || echo "❌ Nenhum processo Gunicorn encontrado"

echo ""
echo "🔍 Verificando processos Nginx:"
ps aux | grep nginx | grep -v grep || echo "❌ Nenhum processo Nginx encontrado"

echo ""
echo "📁 Verificando permissões do diretório:"
if [ -d "/home/ubuntu/s_agendamento" ]; then
    ls -la /home/ubuntu/s_agendamento/ | head -5
else
    echo "❌ Diretório não existe"
fi

echo ""
echo "🔍 Verificando socket do Gunicorn:"
if [ -S "/home/ubuntu/s_agendamento/gunicorn.sock" ]; then
    echo "✅ Socket existe"
    ls -la /home/ubuntu/s_agendamento/gunicorn.sock
else
    echo "❌ Socket não existe"
fi

echo ""
echo "🌐 Verificando configuração do Nginx:"
sudo nginx -t 2>&1 || echo "❌ Configuração do Nginx inválida"

echo ""
echo "📋 Verificando se arquivo de configuração do Nginx existe:"
if [ -f "/etc/nginx/sites-available/agendamento-4minds" ]; then
    echo "✅ Arquivo de configuração existe"
    echo "📋 Primeiras linhas da configuração:"
    head -10 /etc/nginx/sites-available/agendamento-4minds
else
    echo "❌ Arquivo de configuração não existe"
fi

echo ""
echo "🔍 Testando conectividade com RDS (timeout 10s):"
timeout 10 bash -c "echo > /dev/tcp/agendamento-4minds-postgres.cgr24gyuwi3d.us-east-1.rds.amazonaws.com/5432" && echo "✅ RDS acessível" || echo "❌ RDS não acessível"

echo ""
echo "🎯 DIAGNÓSTICO RÁPIDO CONCLUÍDO!"
echo "================================"
echo ""
echo "💡 Se houver problemas, execute o script de correção:"
echo "curl -o corrigir_ec2.sh https://raw.githubusercontent.com/fourmindsorg/s_agendamento/main/corrigir_ec2.sh"
echo "chmod +x corrigir_ec2.sh"
echo "./corrigir_ec2.sh"
