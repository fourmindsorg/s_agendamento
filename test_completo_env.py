#!/usr/bin/env python3
# Script completo para verificar variáveis de ambiente

import os
from pathlib import Path

print("=" * 60)
print("VERIFICACAO COMPLETA DE VARIAVEIS ASAAS")
print("=" * 60)
print()

# 1. Verificar arquivo .env
print("1. VERIFICANDO ARQUIVO .env")
print("-" * 60)
env_path = Path('.env')
print(f"   Caminho: {env_path.absolute()}")
print(f"   Existe: {env_path.exists()}")

if env_path.exists():
    print(f"   Tamanho: {env_path.stat().st_size} bytes")
    print()
    print("   Linhas ASAAS no .env:")
    try:
        with open('.env', 'r') as f:
            for line in f:
                if 'ASAAS' in line:
                    # Mascarar chaves
                    if 'ASAAS_API_KEY' in line and '=' in line:
                        parts = line.strip().split('=', 1)
                        if len(parts) == 2:
                            value = parts[1]
                            if value and len(value) > 20:
                                masked = value[:10] + '...' + value[-10:]
                            else:
                                masked = '***' if value else '(vazio)'
                            print(f"      {parts[0]}={masked}")
                    else:
                        print(f"      {line.strip()}")
    except Exception as e:
        print(f"   ERRO ao ler .env: {e}")
else:
    print("   [ERRO] Arquivo .env nao encontrado!")
print()

# 2. Carregar .env
print("2. CARREGANDO .env")
print("-" * 60)
try:
    from dotenv import load_dotenv
    result = load_dotenv()
    print(f"   python-dotenv instalado: Sim")
    print(f"   load_dotenv() retornou: {result}")
except ImportError:
    print("   [ERRO] python-dotenv nao instalado!")
    print("   Instalar com: pip install python-dotenv")
except Exception as e:
    print(f"   [ERRO] Erro ao carregar .env: {e}")
print()

# 3. Verificar variáveis de ambiente
print("3. VARIAVEIS DE AMBIENTE")
print("-" * 60)
env_asaas = os.environ.get('ASAAS_ENV', 'NAO ENCONTRADO')
key_prod = os.environ.get('ASAAS_API_KEY_PRODUCTION')
key_sandbox = os.environ.get('ASAAS_API_KEY_SANDBOX')
key_fallback = os.environ.get('ASAAS_API_KEY')

print(f"   ASAAS_ENV: {env_asaas}")
print(f"   ASAAS_API_KEY_PRODUCTION: {'[OK] Configurada' if key_prod else '[ERRO] Nao configurada'}")
if key_prod:
    print(f"      Chave (mascarada): {key_prod[:10]}...{key_prod[-10:]}")
print(f"   ASAAS_API_KEY_SANDBOX: {'[OK] Configurada' if key_sandbox else '[ERRO] Nao configurada'}")
if key_sandbox:
    print(f"      Chave (mascarada): {key_sandbox[:10]}...{key_sandbox[-10:]}")
print(f"   ASAAS_API_KEY (fallback): {'[OK] Configurada' if key_fallback else '[ERRO] Nao configurada'}")
print()

# 4. Verificar qual chave será usada
print("4. CHAVE QUE SERA USADA")
print("-" * 60)
if env_asaas.lower() == 'sandbox':
    chave_usada = key_sandbox or key_fallback
    print(f"   Ambiente: sandbox")
    print(f"   Chave usada: {'ASAAS_API_KEY_SANDBOX' if key_sandbox else 'ASAAS_API_KEY (fallback)'}")
else:
    chave_usada = key_prod or key_fallback
    print(f"   Ambiente: {env_asaas}")
    print(f"   Chave usada: {'ASAAS_API_KEY_PRODUCTION' if key_prod else 'ASAAS_API_KEY (fallback)'}")

if chave_usada:
    masked = chave_usada[:10] + '...' + chave_usada[-10:] if len(chave_usada) > 20 else '***'
    print(f"   Chave (mascarada): {masked}")
else:
    print("   [ERRO] Nenhuma chave configurada!")
print()

# 5. Testar Django settings (se disponível)
print("5. SETTINGS DO DJANGO")
print("-" * 60)
try:
    import django
    django.setup()
    
    from django.conf import settings
    
    settings_env = getattr(settings, 'ASAAS_ENV', 'NAO CONFIGURADO')
    settings_key = getattr(settings, 'ASAAS_API_KEY', None)
    settings_enabled = getattr(settings, 'ASAAS_ENABLED', False)
    
    print(f"   ASAAS_ENV: {settings_env}")
    print(f"   ASAAS_API_KEY: {'[OK] Configurada' if settings_key else '[ERRO] Nao configurada'}")
    if settings_key:
        masked = settings_key[:10] + '...' + settings_key[-10:] if len(settings_key) > 20 else '***'
        print(f"      Chave (mascarada): {masked}")
    print(f"   ASAAS_ENABLED: {settings_enabled}")
    
except Exception as e:
    print(f"   [ERRO] Erro ao carregar Django: {e}")
    print("   Execute com: python manage.py shell < test_completo_env.py")

print()
print("=" * 60)

# Resumo
if chave_usada:
    print("[OK] Configuracao parece estar correta!")
    if not settings_key:
        print("[AVISO] Django settings nao encontrou a chave.")
        print("        Pode ser necessario reiniciar o Django.")
else:
    print("[ERRO] Nenhuma chave configurada!")
    print()
    print("SOLUCAO:")
    print("1. Verificar se .env existe e tem as linhas:")
    print("   ASAAS_ENV=production")
    print("   ASAAS_API_KEY_PRODUCTION=$aact_SUA_CHAVE_AQUI")
    print("2. Verificar se nao ha espacos ao redor do =")
    print("3. Reiniciar o Django apos editar .env")

print("=" * 60)

