#!/bin/bash
# Comandos rápidos para configurar e testar no servidor

echo "=========================================="
echo "🔧 Comandos Rápidos - Servidor AWS"
echo "=========================================="
echo ""

# 1. Verificar ambiente virtual
echo "1️⃣ Verificando ambiente virtual..."
if [ -d ".venv" ]; then
    echo "   ✅ .venv encontrado"
    VENV_PATH=".venv"
elif [ -d "venv" ]; then
    echo "   ✅ venv encontrado"
    VENV_PATH="venv"
elif [ -d "env" ]; then
    echo "   ✅ env encontrado"
    VENV_PATH="env"
else
    echo "   ❌ Nenhum ambiente virtual encontrado"
    echo "   💡 Criar com: python3 -m venv .venv"
    VENV_PATH=""
fi

# 2. Ativar ambiente virtual (se existir)
if [ ! -z "$VENV_PATH" ]; then
    echo ""
    echo "2️⃣ Ativando ambiente virtual..."
    if [ -f "$VENV_PATH/bin/activate" ]; then
        source "$VENV_PATH/bin/activate"
        echo "   ✅ Ambiente virtual ativado"
        echo "   💡 Para ativar manualmente: source $VENV_PATH/bin/activate"
    else
        echo "   ❌ Arquivo activate não encontrado em $VENV_PATH/bin/"
    fi
fi

# 3. Verificar .env
echo ""
echo "3️⃣ Verificando arquivo .env..."
if [ -f ".env" ]; then
    echo "   ✅ Arquivo .env encontrado"
    echo "   📋 Variáveis Asaas configuradas:"
    grep "^ASAAS" .env | sed 's/=.*/=***/' || echo "      Nenhuma variável ASAAS encontrada"
else
    echo "   ❌ Arquivo .env não encontrado"
    echo "   💡 Criar com: nano .env"
fi

# 4. Verificar python-dotenv
echo ""
echo "4️⃣ Verificando python-dotenv..."
if python3 -c "import dotenv" 2>/dev/null; then
    echo "   ✅ python-dotenv instalado"
else
    echo "   ❌ python-dotenv não instalado"
    echo "   💡 Instalar com: pip install python-dotenv"
fi

# 5. Verificar Django
echo ""
echo "5️⃣ Verificando Django..."
if python3 -c "import django" 2>/dev/null; then
    DJANGO_VERSION=$(python3 -c "import django; print(django.get_version())" 2>/dev/null)
    echo "   ✅ Django instalado (versão: $DJANGO_VERSION)"
else
    echo "   ❌ Django não instalado"
    echo "   💡 Instalar com: pip install -r requirements.txt"
fi

# 6. Verificar processos Django
echo ""
echo "6️⃣ Verificando processos Django rodando..."
DJANGO_PROCESSES=$(ps aux | grep -E "python.*manage.py|gunicorn" | grep -v grep)
if [ ! -z "$DJANGO_PROCESSES" ]; then
    echo "   ✅ Processos encontrados:"
    echo "$DJANGO_PROCESSES" | while read line; do
        echo "      $line"
    done
else
    echo "   ❌ Nenhum processo Django encontrado"
    echo "   💡 Iniciar com: python manage.py runserver 0.0.0.0:8000"
fi

echo ""
echo "=========================================="
echo "✅ Verificação concluída"
echo "=========================================="
echo ""
echo "📋 Próximos passos:"
echo "   1. Se venv não existe: python3 -m venv .venv"
echo "   2. Ativar venv: source .venv/bin/activate"
echo "   3. Instalar dependências: pip install -r requirements.txt"
echo "   4. Configurar .env (se não configurou)"
echo "   5. Testar: python manage.py shell"
echo ""

