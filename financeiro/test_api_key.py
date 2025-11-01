#!/usr/bin/env python3
"""Script para testar se a chave de API do Asaas está configurada corretamente"""

import os
import sys
import django

# Configurar Django
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "core.settings")
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
django.setup()

from django.conf import settings
from financeiro.services.asaas import AsaasClient

def test_configuration():
    """Testa a configuração da API"""
    print("=" * 60)
    print("Teste de Configuracao - API Asaas")
    print("=" * 60)
    
    # Verificar variáveis
    api_key = getattr(settings, "ASAAS_API_KEY", None)
    env = getattr(settings, "ASAAS_ENV", "sandbox")
    enabled = getattr(settings, "ASAAS_ENABLED", False)
    
    print(f"\n1. ASAAS_API_KEY configurada: {bool(api_key)}")
    if api_key:
        print(f"   Tamanho: {len(api_key)} caracteres")
        print(f"   Comeca com $aact_: {api_key.startswith('$aact_')}")
        # Mostrar apenas primeiros e últimos caracteres por segurança
        if len(api_key) > 20:
            masked = f"{api_key[:10]}...{api_key[-10:]}"
        else:
            masked = "***"
        print(f"   Chave (mascarada): {masked}")
    else:
        print("   [ERRO] Chave nao configurada no arquivo .env")
        return False
    
    print(f"\n2. ASAAS_ENV: {env}")
    print(f"   Ambiente correto: {env in ['sandbox', 'production']}")
    
    print(f"\n3. ASAAS_ENABLED: {enabled}")
    
    # Testar inicialização do cliente
    print("\n4. Testando inicializacao do cliente...")
    try:
        client = AsaasClient()
        print(f"   [OK] Cliente inicializado")
        print(f"   Base URL: {client.base}")
        print(f"   Ambiente: {client.env}")
    except Exception as e:
        print(f"   [ERRO] Falha ao inicializar: {e}")
        return False
    
    # Testar conexão real com a API
    print("\n5. Testando conexao com a API...")
    try:
        # Tentar criar um cliente de teste (requer API válida)
        test_customer = client.create_customer(
            name="Teste API Key",
            email="teste.apikey@example.com",
            cpf_cnpj="12345678900"
        )
        print(f"   [OK] Conexao bem-sucedida!")
        print(f"   Cliente de teste criado: {test_customer.get('id', 'N/A')}")
        return True
    except Exception as e:
        print(f"   [ERRO] Falha na conexao: {e}")
        print(f"\n   Possiveis problemas:")
        print(f"   - Chave de API invalida ou expirada")
        print(f"   - Ambiente incorreto (sandbox vs production)")
        print(f"   - Chave de sandbox usada com ambiente production (ou vice-versa)")
        print(f"   - Problemas de rede/conectividade")
        return False

if __name__ == "__main__":
    success = test_configuration()
    print("\n" + "=" * 60)
    if success:
        print("SUCESSO: Configuracao valida e funcionando!")
        sys.exit(0)
    else:
        print("ERRO: Configuracao invalida ou problemas na conexao")
        sys.exit(1)

