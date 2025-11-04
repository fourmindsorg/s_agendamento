import os
from dotenv import load_dotenv

print("=" * 60)
print("🔍 Verificação de Configuração Asaas")
print("=" * 60)
print()

# Carregar .env
load_dotenv()
print("✅ .env carregado")
print()

# Verificar variáveis
print("📋 Variáveis de Ambiente:")
print(f"   ASAAS_ENV: {os.environ.get('ASAAS_ENV', 'NÃO ENCONTRADO')}")
print(f"   ASAAS_API_KEY_PRODUCTION: {'✅ Configurada' if os.environ.get('ASAAS_API_KEY_PRODUCTION') else '❌ Não configurada'}")
print(f"   ASAAS_API_KEY_SANDBOX: {'✅ Configurada' if os.environ.get('ASAAS_API_KEY_SANDBOX') else '❌ Não configurada'}")
print(f"   ASAAS_API_KEY (fallback): {'✅ Configurada' if os.environ.get('ASAAS_API_KEY') else '❌ Não configurada'}")
print()

# Verificar .env diretamente
print("📋 Conteúdo do .env (linhas ASAAS):")
try:
    with open('.env', 'r') as f:
        for line in f:
            if 'ASAAS' in line:
                # Mascarar chaves
                if 'ASAAS_API_KEY' in line:
                    parts = line.strip().split('=')
                    if len(parts) == 2 and parts[1]:
                        masked = parts[1][:10] + '...' + parts[1][-10:] if len(parts[1]) > 20 else '***'
                        print(f"   {parts[0]}={masked}")
                else:
                    print(f"   {line.strip()}")
except Exception as e:
    print(f"   ❌ Erro ao ler .env: {e}")
print()

# Testar Django settings
print("📋 Settings do Django:")
try:
    import django
    django.setup()
    
    from django.conf import settings
    
    print(f"   ASAAS_ENV: {getattr(settings, 'ASAAS_ENV', 'NÃO CONFIGURADO')}")
    print(f"   ASAAS_API_KEY: {'✅ Configurada' if getattr(settings, 'ASAAS_API_KEY', None) else '❌ Não configurada'}")
    print(f"   ASAAS_ENABLED: {getattr(settings, 'ASAAS_ENABLED', False)}")
    
    if getattr(settings, 'ASAAS_API_KEY', None):
        key = getattr(settings, 'ASAAS_API_KEY', '')
        masked = key[:10] + '...' + key[-10:] if len(key) > 20 else '***'
        print(f"   Chave (mascarada): {masked}")
    
    print()
    
    # Testar cliente
    print("🔌 Testando cliente Asaas:")
    try:
        from financeiro.services.asaas import AsaasClient
        client = AsaasClient()
        print(f"   ✅ Cliente inicializado")
        print(f"   Base URL: {client.base}")
        print(f"   Ambiente: {client.env}")
        
        if client.env == "production":
            print("\n⚠️  ATENÇÃO: Ambiente PRODUÇÃO - Cobranças reais!")
        else:
            print("\n✅ Ambiente SANDBOX - Testes seguros")
            
    except Exception as e:
        print(f"   ❌ Erro ao inicializar cliente: {e}")
        import traceback
        traceback.print_exc()
        
except Exception as e:
    print(f"   ❌ Erro ao carregar Django: {e}")
    import traceback
    traceback.print_exc()

print()
print("=" * 60)

# Verificar problema
if not os.environ.get('ASAAS_API_KEY_PRODUCTION'):
    print("⚠️  PROBLEMA ENCONTRADO:")
    print("   ASAAS_API_KEY_PRODUCTION não está configurada!")
    print()
    print("💡 SOLUÇÃO:")
    print("   1. Verificar se o .env está no diretório correto")
    print("   2. Verificar se a linha está correta:")
    print("      ASAAS_API_KEY_PRODUCTION=$aact_SUA_CHAVE_AQUI")
    print("   3. Verificar se não há espaços ao redor do =")
    print("   4. Reiniciar o Django após editar .env")
else:
    print("✅ Configuração parece estar correta!")

print("=" * 60)

