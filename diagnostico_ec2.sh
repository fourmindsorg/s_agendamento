#!/bin/bash

# Script de Diagnóstico para EC2
# Execute este script na EC2 para verificar o que aconteceu

echo "🔍 DIAGNÓSTICO COMPLETO DA EC2"
echo "================================"

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
        echo "📦 Verificando dependências Python..."
        pip list | grep -E "(django|gunicorn|psycopg2)"
    else
        echo "❌ Ambiente virtual não existe"
    fi
    echo ""
    echo "⚙️ Verificando arquivo .env..."
    if [ -f ".env" ]; then
        echo "✅ Arquivo .env existe"
        echo "📋 Conteúdo do .env:"
        cat .env
    else
        echo "❌ Arquivo .env não existe"
    fi
else
    echo "❌ Diretório s_agendamento não existe"
fi

echo ""
echo "🔧 Verificando serviços do sistema..."
echo "📊 Status do Gunicorn:"
sudo systemctl status gunicorn --no-pager

echo ""
echo "📊 Status do Nginx:"
sudo systemctl status nginx --no-pager

echo ""
echo "🌐 Testando conectividade..."
echo "Testando localhost:"
curl -I http://localhost:8000/ 2>/dev/null || echo "❌ Localhost não responde"

echo "Testando IP externo:"
curl -I http://3.80.178.120/ 2>/dev/null || echo "❌ IP externo não responde"

echo ""
echo "📋 Verificando logs do Gunicorn:"
sudo journalctl -u gunicorn --no-pager -n 20

echo ""
echo "📋 Verificando logs do Nginx:"
sudo journalctl -u nginx --no-pager -n 20

echo ""
echo "🔍 Verificando processos Python:"
ps aux | grep python

echo ""
echo "🔍 Verificando processos Gunicorn:"
ps aux | grep gunicorn

echo ""
echo "🔍 Verificando processos Nginx:"
ps aux | grep nginx

echo ""
echo "📁 Verificando permissões:"
ls -la /home/ubuntu/s_agendamento/ 2>/dev/null || echo "❌ Diretório não existe"

echo ""
echo "🔍 Verificando socket do Gunicorn:"
ls -la /home/ubuntu/s_agendamento/gunicorn.sock 2>/dev/null || echo "❌ Socket não existe"

echo ""
echo "🌐 Verificando configuração do Nginx:"
sudo nginx -t

echo ""
echo "📋 Configuração do Nginx:"
sudo cat /etc/nginx/sites-available/agendamento-4minds 2>/dev/null || echo "❌ Arquivo de configuração não existe"

echo ""
echo "🔍 Verificando conectividade com RDS:"
telnet agendamento-4minds-postgres.cgr24gyuwi3d.us-east-1.rds.amazonaws.com 5432 2>/dev/null || echo "❌ RDS não acessível"

echo ""
echo "🎯 DIAGNÓSTICO CONCLUÍDO!"
echo "================================"
