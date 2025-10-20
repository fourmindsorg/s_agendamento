#!/bin/bash
set -e
set -x

echo "🔍 VERIFICANDO CONFIGURAÇÃO DE ARQUIVOS ESTÁTICOS"
echo "================================================"

# 1. Verificar configuração do Nginx
echo "📋 Configuração do Nginx:"
sudo cat /etc/nginx/sites-available/agendamento-4minds

echo ""
echo "📋 Configuração do Nginx (default):"
sudo cat /etc/nginx/sites-available/default

echo ""
echo "📋 Sites habilitados:"
ls -la /etc/nginx/sites-enabled/

echo ""
echo "📋 Status do Nginx:"
sudo systemctl status nginx --no-pager

echo ""
echo "📋 Teste de configuração do Nginx:"
sudo nginx -t

echo ""
echo "📁 Verificando arquivos estáticos:"
ls -la /home/ubuntu/s_agendamento/static/
ls -la /home/ubuntu/s_agendamento/staticfiles/

echo ""
echo "📁 Verificando CSS específico:"
ls -la /home/ubuntu/s_agendamento/static/css/
ls -la /home/ubuntu/s_agendamento/staticfiles/css/

echo ""
echo "🌐 Testando URLs de arquivos estáticos:"
curl -I http://3.80.178.120/static/css/style.css || echo "❌ CSS não acessível"
curl -I http://3.80.178.120/static/css/bootstrap.min.css || echo "❌ Bootstrap não acessível"
curl -I http://3.80.178.120/static/css/error-messages.css || echo "❌ Error messages CSS não acessível"

echo ""
echo "🔍 Verificando logs do Nginx:"
sudo tail -20 /var/log/nginx/error.log

echo ""
echo "🔍 Verificando logs do Django:"
sudo journalctl -u gunicorn --no-pager -n 10

