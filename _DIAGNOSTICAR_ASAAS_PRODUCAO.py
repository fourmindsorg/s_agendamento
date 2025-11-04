"""
Script para diagnosticar configuração do Asaas em produção
Execute no servidor: python manage.py shell < _DIAGNOSTICAR_ASAAS_PRODUCAO.py
"""

import os
import sys

# Configurar Django
os.environ.setdefault("DJANGO_SETTINGS_MODULE", os.environ.get("DJANGO_SETTINGS_MODULE", "core.settings"))

try:
    import django
    django.setup()
except Exception as e:
    print(f"❌ Erro ao configurar Django: {e}")
    sys.exit(1)

from django.conf import settings

print("=" * 60)
print("DIAGNÓSTICO CONFIGURAÇÃO ASAAS EM PRODUÇÃO")
print("=" * 60)
print()

# 1. Verificar Settings Module
settings_module = os.environ.get("DJANGO_SETTINGS_MODULE", "core.settings")
print(f"1. DJANGO_SETTINGS_MODULE: {settings_module}")
print(f"   {'✅ Contém production' if 'production' in settings_module.lower() else '⚠️ Não contém production'}")
print()

# 2. Verificar DEBUG
debug_value = getattr(settings, "DEBUG", True)
print(f"2. DEBUG: {debug_value}")
print(f"   {'✅ DEBUG=False (produção)' if not debug_value else '⚠️ DEBUG=True (pode ser desenvolvimento)'}")
print()

# 3. Verificar ASAAS_ENV
asaas_env = getattr(settings, "ASAAS_ENV", "N/A")
print(f"3. ASAAS_ENV (settings): {asaas_env}")
print(f"   {'✅ Configurado como production' if str(asaas_env).lower() == 'production' else '⚠️ Não está como production'}")
print()

# 4. Verificar variáveis de ambiente
print("4. Variáveis de Ambiente:")
asaas_key_prod = os.environ.get("ASAAS_API_KEY_PRODUCTION")
asaas_key_sandbox = os.environ.get("ASAAS_API_KEY_SANDBOX")
asaas_key = os.environ.get("ASAAS_API_KEY")
asaas_env_env = os.environ.get("ASAAS_ENV")

print(f"   ASAAS_API_KEY_PRODUCTION: {'✅ Configurada' if asaas_key_prod else '❌ NÃO configurada'}")
if asaas_key_prod:
    print(f"      Tamanho: {len(asaas_key_prod)} caracteres")
    print(f"      Inicia com: {asaas_key_prod[:10]}...")

print(f"   ASAAS_API_KEY_SANDBOX: {'✅ Configurada' if asaas_key_sandbox else '⚠️ Não configurada (ok em produção)'}")
print(f"   ASAAS_API_KEY (fallback): {'✅ Configurada' if asaas_key else '⚠️ Não configurada'}")
print(f"   ASAAS_ENV (env): {asaas_env_env if asaas_env_env else 'Não configurada'}")
print()

# 5. Verificar ASAAS_API_KEY no settings
asaas_key_settings = getattr(settings, "ASAAS_API_KEY", None)
print(f"5. ASAAS_API_KEY (settings): {'✅ Configurada' if asaas_key_settings else '❌ NÃO configurada'}")
if asaas_key_settings:
    print(f"   Tamanho: {len(asaas_key_settings)} caracteres")
    print(f"   Inicia com: {asaas_key_settings[:10]}...")
print()

# 6. Verificar se Asaas está habilitado
asaas_enabled = getattr(settings, "ASAAS_ENABLED", False)
print(f"6. ASAAS_ENABLED: {asaas_enabled}")
print(f"   {'✅ Asaas está habilitado' if asaas_enabled else '❌ Asaas está DESABILITADO'}")
print()

# 7. Testar detecção de produção
print("7. Detecção de Produção:")
debug_val = getattr(settings, "DEBUG", True)
settings_mod = os.environ.get("DJANGO_SETTINGS_MODULE", "")
is_prod_settings = "production" in settings_mod.lower() if settings_mod else False
asaas_env_val = getattr(settings, "ASAAS_ENV", "").lower()
is_prod_env = asaas_env_val == "production"

is_production = (
    not debug_val or
    is_prod_settings or
    is_prod_env
)

print(f"   DEBUG=False: {not debug_val}")
print(f"   Settings module contém 'production': {is_prod_settings}")
print(f"   ASAAS_ENV='production': {is_prod_env}")
print(f"   ✅ RESULTADO: {'PRODUÇÃO' if is_production else 'SANDBOX/DEV'}")
print()

# 8. Testar criação do cliente Asaas
print("8. Teste de Criação do Cliente Asaas:")
try:
    from financeiro.services.asaas import AsaasClient
    
    try:
        client = AsaasClient()
        print(f"   ✅ Cliente criado com sucesso!")
        print(f"   Ambiente: {client.env}")
        print(f"   Base URL: {client.base}")
        print(f"   API Key configurada: {'✅ Sim' if client.api_key else '❌ Não'}")
    except RuntimeError as e:
        print(f"   ❌ Erro ao criar cliente: {e}")
        print()
        print("   DETALHES DO ERRO:")
        print(f"   {str(e)}")
except Exception as e:
    print(f"   ❌ Erro ao importar/clicar cliente: {e}")
    import traceback
    traceback.print_exc()
print()

# 9. Verificar arquivo .env
print("9. Verificação do arquivo .env:")
env_path = getattr(settings, "BASE_DIR", None)
if env_path:
    env_file = env_path / ".env"
    print(f"   Caminho esperado: {env_file}")
    print(f"   Arquivo existe: {'✅ Sim' if env_file.exists() else '❌ Não'}")
    if env_file.exists():
        try:
            with open(env_file, 'r') as f:
                content = f.read()
                has_prod_key = "ASAAS_API_KEY_PRODUCTION" in content
                has_sandbox_key = "ASAAS_API_KEY_SANDBOX" in content
                print(f"   Contém ASAAS_API_KEY_PRODUCTION: {'✅ Sim' if has_prod_key else '❌ Não'}")
                print(f"   Contém ASAAS_API_KEY_SANDBOX: {'✅ Sim' if has_sandbox_key else '⚠️ Não (ok em produção)'}")
        except Exception as e:
            print(f"   ⚠️ Erro ao ler arquivo: {e}")
else:
    print("   ⚠️ BASE_DIR não encontrado")
print()

print("=" * 60)
print("FIM DO DIAGNÓSTICO")
print("=" * 60)
print()
print("RECOMENDAÇÕES:")
print()

if not is_production:
    print("⚠️ O sistema não está detectando como produção!")
    print("   - Verifique se DEBUG=False")
    print("   - Verifique se DJANGO_SETTINGS_MODULE contém 'production'")
    print("   - Verifique se ASAAS_ENV='production' no settings")
    print()

if not asaas_key_prod:
    print("❌ ASAAS_API_KEY_PRODUCTION não está configurada!")
    print("   - Configure no arquivo .env:")
    print("     ASAAS_API_KEY_PRODUCTION=$aact_SUA_CHAVE_AQUI")
    print("   - Ou configure como variável de ambiente do sistema")
    print()

if not asaas_key_settings:
    print("❌ ASAAS_API_KEY não está disponível no settings!")
    print("   - Verifique se o .env está sendo carregado corretamente")
    print("   - Verifique se o arquivo .env está no diretório correto (BASE_DIR)")
    print()

print("Para aplicar correções:")
print("1. git pull origin main")
print("2. Verificar/editar arquivo .env")
print("3. sudo systemctl restart gunicorn")
print()

