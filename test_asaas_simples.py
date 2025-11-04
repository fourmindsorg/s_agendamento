#!/usr/bin/env python3
"""
Script simples para testar configuração Asaas
Execute no servidor: python manage.py shell < test_asaas_simples.py
OU copie e cole no shell Python
"""

import os
from pathlib import Path

print("=" * 60)
print("🔍 Verificação de Configuração - Asaas")
print("=" * 60)
print()

# Tentar carregar .env
try:
    from dotenv import load_dotenv
    load_dotenv()
    print("✅ python-dotenv carregado")
except ImportError:
    print("⚠️  python-dotenv não instalado (opcional)")
except Exception as e:
    print(f"⚠️  Erro ao carregar .env: {e}")

print()

# Verificar variáveis de ambiente
print("📋 Variáveis de Ambiente:")
env_asaas = os.environ.get("ASAAS_ENV", "NÃO CONFIGURADO")
key_sandbox = os.environ.get("ASAAS_API_KEY_SANDBOX", None)
key_production = os.environ.get("ASAAS_API_KEY_PRODUCTION", None)
key_fallback = os.environ.get("ASAAS_API_KEY", None)

print(f"   ASAAS_ENV: {env_asaas}")
print(f"   ASAAS_API_KEY_SANDBOX: {'✅ Configurada' if key_sandbox else '❌ Não configurada'}")
print(f"   ASAAS_API_KEY_PRODUCTION: {'✅ Configurada' if key_production else '❌ Não configurada'}")
print(f"   ASAAS_API_KEY (fallback): {'✅ Configurada' if key_fallback else '❌ Não configurada'}")

print()

# Verificar qual chave será usada
print("📋 Chave que será usada:")
if env_asaas.lower() == "sandbox":
    chave_usada = key_sandbox or key_fallback
    print(f"   Ambiente: sandbox")
    print(f"   Chave usada: {'ASAAS_API_KEY_SANDBOX' if key_sandbox else 'ASAAS_API_KEY (fallback)'}")
else:
    chave_usada = key_production or key_fallback
    print(f"   Ambiente: {env_asaas}")
    print(f"   Chave usada: {'ASAAS_API_KEY_PRODUCTION' if key_production else 'ASAAS_API_KEY (fallback)'}")

if chave_usada:
    masked = f"{chave_usada[:10]}...{chave_usada[-10:]}" if len(chave_usada) > 20 else "***"
    print(f"   Chave (mascarada): {masked}")
else:
    print("   ❌ Nenhuma chave configurada!")

print()

# Testar Django settings
print("📋 Settings do Django:")
try:
    import django
    django.setup()
    
    from django.conf import settings
    
    asaas_env = getattr(settings, 'ASAAS_ENV', 'NÃO CONFIGURADO')
    asaas_key = getattr(settings, 'ASAAS_API_KEY', None)
    asaas_enabled = getattr(settings, 'ASAAS_ENABLED', False)
    
    print(f"   ASAAS_ENV: {asaas_env}")
    print(f"   ASAAS_API_KEY: {'✅ Configurada' if asaas_key else '❌ Não configurada'}")
    if asaas_key:
        masked = f"{asaas_key[:10]}...{asaas_key[-10:]}" if len(asaas_key) > 20 else "***"
        print(f"   Chave (mascarada): {masked}")
    print(f"   ASAAS_ENABLED: {asaas_enabled}")
    
    print()
    
    # Testar inicialização do cliente
    print("🔌 Testando inicialização do cliente...")
    try:
        from financeiro.services.asaas import AsaasClient
        client = AsaasClient()
        print(f"   ✅ Cliente inicializado com sucesso")
        print(f"   Base URL: {client.base}")
        print(f"   Ambiente: {client.env}")
        
        if client.env == "production":
            print("\n⚠️  ATENÇÃO: Ambiente configurado como PRODUÇÃO!")
            print("   Qualquer teste criará cobranças reais!")
        else:
            print("\n✅ Ambiente configurado como SANDBOX")
            print("   Testes são seguros (não criam cobranças reais)")
    except Exception as e:
        print(f"   ❌ Erro ao inicializar cliente: {e}")
        import traceback
        traceback.print_exc()
        
except Exception as e:
    print(f"   ❌ Erro ao carregar Django: {e}")
    print("   Execute com: python manage.py shell < test_asaas_simples.py")

print()
print("=" * 60)
if chave_usada:
    print("✅ Configuração verificada!")
else:
    print("❌ Configuração incompleta. Configure as variáveis no .env")
print("=" * 60)

