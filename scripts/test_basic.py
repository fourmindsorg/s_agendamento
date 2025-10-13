#!/usr/bin/env python3
"""
Testes básicos para o sistema de agendamento
"""

import os
import sys
import django
from django.conf import settings

# Adicionar o diretório raiz do projeto ao Python path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

def test_django_setup():
    """Testar configuração básica do Django"""
    print("Testando configuracao do Django...")
    
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
    django.setup()
    print("Django configurado com sucesso")
    assert True  # Pytest espera assert, não return

def test_imports():
    """Testar importações básicas"""
    print("Testando importacoes...")
    
    from django.contrib.auth.models import User
    from django.db import models
    print("Modelos do Django importados")
    
    # Testar importações específicas do projeto
    from core.settings import DEBUG
    print(f"Configuracoes carregadas (DEBUG: {DEBUG})")
    
    assert True  # Pytest espera assert, não return

def test_database_connection():
    """Testar conexão com banco de dados"""
    print("Testando conexao com banco de dados...")
    
    from django.db import connection
    with connection.cursor() as cursor:
        cursor.execute("SELECT 1")
        result = cursor.fetchone()
        assert result[0] == 1, "Resultado inesperado do banco de dados"
        print("Conexao com banco de dados OK")

def test_urls():
    """Testar configuração de URLs"""
    print("Testando configuracao de URLs...")
    
    from django.urls import reverse
    from django.test import Client
    
    client = Client()
    
    # Testar URLs básicas
    response = client.get('/')
    print(f"Pagina principal responde (status: {response.status_code})")
    assert response.status_code in [200, 302, 404], f"Status code inesperado: {response.status_code}"

def main():
    """Executar todos os testes básicos"""
    print("Executando testes basicos do sistema...")
    print("=" * 50)
    
    tests = [
        test_django_setup,
        test_imports,
        test_database_connection,
        test_urls
    ]
    
    passed = 0
    total = len(tests)
    
    for test in tests:
        try:
            test()
            passed += 1
        except AssertionError as e:
            print(f"Teste falhou: {e}")
        except Exception as e:
            print(f"Erro no teste: {e}")
        print()
    
    print(f"Resultado: {passed}/{total} testes passaram")
    
    if passed == total:
        print("Todos os testes basicos passaram!")
    else:
        print("Alguns testes falharam!")
        sys.exit(1)

if __name__ == '__main__':
    main()
