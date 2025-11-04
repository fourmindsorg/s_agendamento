#!/usr/bin/env python3
"""
Script para verificar configuração do Asaas
Execute: python _VERIFICAR_CONFIGURACAO_ASAAS.py
"""

import os
import sys
import django

# Configurar Django
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "core.settings")
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
django.setup()

from django.conf import settings

def verificar_configuracao():
    """Verifica a configuração do Asaas"""
    
    print("=" * 70)
    print("🔍 Verificação de Configuração - Asaas")
    print("=" * 70)
    
    # Verificar variáveis de ambiente
    print("\n📋 Variáveis de Ambiente:")
    env_asaas = os.environ.get("ASAAS_ENV", "sandbox")
    key_sandbox = os.environ.get("ASAAS_API_KEY_SANDBOX", None)
    key_production = os.environ.get("ASAAS_API_KEY_PRODUCTION", None)
    key_fallback = os.environ.get("ASAAS_API_KEY", None)
    
    print(f"   ASAAS_ENV: {env_asaas}")
    print(f"   ASAAS_API_KEY_SANDBOX: {'✅ Configurada' if key_sandbox else '❌ Não configurada'}")
    print(f"   ASAAS_API_KEY_PRODUCTION: {'✅ Configurada' if key_production else '❌ Não configurada'}")
    print(f"   ASAAS_API_KEY (fallback): {'✅ Configurada' if key_fallback else '❌ Não configurada'}")
    
    # Verificar settings do Django
    print("\n📋 Settings do Django:")
    asaas_env = getattr(settings, 'ASAAS_ENV', 'sandbox')
    asaas_key = getattr(settings, 'ASAAS_API_KEY', None)
    asaas_enabled = getattr(settings, 'ASAAS_ENABLED', False)
    
    print(f"   ASAAS_ENV: {asaas_env}")
    print(f"   ASAAS_API_KEY: {'✅ Configurada' if asaas_key else '❌ Não configurada'}")
    if asaas_key:
        # Mostrar apenas primeiros e últimos caracteres
        masked = f"{asaas_key[:10]}...{asaas_key[-10:]}" if len(asaas_key) > 20 else "***"
        print(f"   Chave (mascarada): {masked}")
    print(f"   ASAAS_ENABLED: {asaas_enabled}")
    
    # Verificar qual chave será usada
    print("\n📋 Chave que será usada:")
    if asaas_env == "sandbox":
        chave_usada = key_sandbox or key_fallback
        print(f"   Ambiente: sandbox")
        print(f"   Chave usada: {'ASAAS_API_KEY_SANDBOX' if key_sandbox else 'ASAAS_API_KEY (fallback)'}")
    else:
        chave_usada = key_production or key_fallback
        print(f"   Ambiente: production")
        print(f"   Chave usada: {'ASAAS_API_KEY_PRODUCTION' if key_production else 'ASAAS_API_KEY (fallback)'}")
    
    if not chave_usada:
        print("\n❌ ERRO: Nenhuma chave configurada para o ambiente atual!")
        print("\n💡 Solução:")
        if asaas_env == "sandbox":
            print("   Configure ASAAS_API_KEY_SANDBOX no .env")
        else:
            print("   Configure ASAAS_API_KEY_PRODUCTION no .env")
        return False
    
    # Testar inicialização do cliente
    print("\n🔌 Testando inicialização do cliente...")
    try:
        from financeiro.services.asaas import AsaasClient
        client = AsaasClient()
        print(f"   ✅ Cliente inicializado com sucesso")
        print(f"   Base URL: {client.base}")
        print(f"   Ambiente: {client.env}")
        print(f"   API Key: {'✅ Configurada' if client.api_key else '❌ Não configurada'}")
        
        if client.env == "production":
            print("\n⚠️  ATENÇÃO: Ambiente configurado como PRODUÇÃO!")
            print("   Qualquer teste criará cobranças reais!")
        else:
            print("\n✅ Ambiente configurado como SANDBOX")
            print("   Testes são seguros (não criam cobranças reais)")
        
        return True
    except Exception as e:
        print(f"   ❌ Erro ao inicializar cliente: {e}")
        return False

if __name__ == "__main__":
    try:
        sucesso = verificar_configuracao()
        print("\n" + "=" * 70)
        if sucesso:
            print("✅ Configuração verificada com sucesso!")
        else:
            print("❌ Configuração incompleta. Verifique os erros acima.")
        print("=" * 70)
        sys.exit(0 if sucesso else 1)
    except KeyboardInterrupt:
        print("\n\n⚠️  Verificação cancelada pelo usuário")
        sys.exit(1)
    except Exception as e:
        print(f"\n\n❌ Erro inesperado: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

