#!/usr/bin/env python
"""
Script para executar o sistema em modo de produção
"""
import os
import sys
import subprocess

def main():
    """Executa o sistema em modo de produção"""
    
    # Configurar variáveis de ambiente para produção
    os.environ.setdefault("DJANGO_SETTINGS_MODULE", "core.settings_production")
    os.environ.setdefault("DEBUG", "False")
    
    # Verificar se as dependências estão instaladas
    try:
        import whitenoise
        print("✓ WhiteNoise disponível")
    except ImportError:
        print("⚠️  WhiteNoise não encontrado. Instalando dependências...")
        subprocess.run([sys.executable, "-m", "pip", "install", "-r", "requirements.txt"])
    
    # Coletar arquivos estáticos
    print("📦 Coletando arquivos estáticos...")
    subprocess.run([sys.executable, "manage.py", "collectstatic", "--noinput"])
    
    # Executar migrações
    print("🗄️  Executando migrações...")
    subprocess.run([sys.executable, "manage.py", "migrate"])
    
    # Iniciar servidor
    print("🚀 Iniciando servidor de produção...")
    print("   Acesse: http://localhost:8000")
    print("   Pressione Ctrl+C para parar")
    
    # Tentar usar gunicorn se disponível, senão usar runserver
    try:
        import gunicorn
        subprocess.run([
            sys.executable, "-m", "gunicorn", 
            "core.wsgi:application", 
            "--bind", "0.0.0.0:8000",
            "--workers", "3"
        ])
    except ImportError:
        print("⚠️  Gunicorn não encontrado. Usando runserver...")
        subprocess.run([sys.executable, "manage.py", "runserver", "0.0.0.0:8000"])

if __name__ == "__main__":
    main()
