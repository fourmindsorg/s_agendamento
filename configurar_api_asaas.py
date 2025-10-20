#!/usr/bin/env python3
"""
Script para configurar e testar nova API key do Asaas
"""
import requests
import os
import sys


def test_api_key(api_key):
    """Testa se a API key está funcionando"""

    # URL base do sandbox
    base_url = "https://api-sandbox.asaas.com/v3"

    print("🔍 Testando API Key...")
    print(f"API Key: {api_key[:20]}...")
    print(f"URL Base: {base_url}")

    # Headers para autenticação
    headers = {"access_token": api_key, "Content-Type": "application/json"}

    # Teste simples: listar clientes
    try:
        response = requests.get(f"{base_url}/customers", headers=headers, timeout=10)
        print(f"Status Code: {response.status_code}")

        if response.status_code == 200:
            print("✅ API Key válida!")
            return True
        else:
            print(f"❌ Erro: {response.status_code}")
            print(f"Resposta: {response.text}")
            return False

    except requests.exceptions.RequestException as e:
        print(f"❌ Erro de conexão: {e}")
        return False


def create_test_payment(api_key):
    """Cria um pagamento de teste completo"""

    base_url = "https://api-sandbox.asaas.com/v3"
    headers = {"access_token": api_key, "Content-Type": "application/json"}

    print("\n📝 Criando cliente de teste...")

    # Criar cliente
    customer_data = {
        "name": "Cliente Teste Integração",
        "email": "teste.integracao@example.com",
        "cpfCnpj": "12345678901",
        "phone": "11999999999",
    }

    try:
        response = requests.post(
            f"{base_url}/customers", headers=headers, json=customer_data, timeout=10
        )

        if response.status_code != 200:
            print(f"❌ Erro ao criar cliente: {response.status_code}")
            print(f"Resposta: {response.text}")
            return False

        customer = response.json()
        customer_id = customer["id"]
        print(f"✅ Cliente criado: {customer_id}")

    except Exception as e:
        print(f"❌ Erro: {e}")
        return False

    print("\n💰 Criando pagamento PIX...")

    # Criar pagamento
    payment_data = {
        "customer": customer_id,
        "value": 10.00,
        "dueDate": "2024-12-31",
        "billingType": "PIX",
        "description": "Teste de integração API Asaas",
    }

    try:
        response = requests.post(
            f"{base_url}/payments", headers=headers, json=payment_data, timeout=10
        )

        if response.status_code != 200:
            print(f"❌ Erro ao criar pagamento: {response.status_code}")
            print(f"Resposta: {response.text}")
            return False

        payment = response.json()
        payment_id = payment["id"]
        print(f"✅ Pagamento criado: {payment_id}")

    except Exception as e:
        print(f"❌ Erro: {e}")
        return False

    print("\n📱 Obtendo QR Code PIX...")

    # Obter QR Code
    try:
        response = requests.get(
            f"{base_url}/payments/{payment_id}/pix", headers=headers, timeout=10
        )

        if response.status_code != 200:
            print(f"❌ Erro ao obter QR Code: {response.status_code}")
            print(f"Resposta: {response.text}")
            return False

        qr_data = response.json()
        print(f"✅ QR Code obtido!")
        print(f"   QR Code presente: {'Sim' if qr_data.get('qrCode') else 'Não'}")
        print(f"   Payload presente: {'Sim' if qr_data.get('payload') else 'Não'}")

    except Exception as e:
        print(f"❌ Erro: {e}")
        return False

    print(f"\n🎉 Teste completo realizado com sucesso!")
    print(f"Cliente: {customer_id}")
    print(f"Pagamento: {payment_id}")

    return True


def save_api_key(api_key):
    """Salva a API key no arquivo de configuração"""

    config_content = f"""# Configurações para testes de integração com API real do Asaas

# API Asaas - Sandbox
ASAAS_API_KEY={api_key}
ASAAS_ENV=sandbox
ASAAS_WEBHOOK_TOKEN=test_webhook_token

# Configurações Django
DJANGO_SETTINGS_MODULE=core.settings
DEBUG=True
SECRET_KEY=test-secret-key-for-integration-tests

# Banco de dados para testes
DB_NAME=agendamentos_db
DB_USER=postgres
DB_PASSWORD=senha_segura_postgres
DB_HOST=localhost
DB_PORT=5432
"""

    try:
        with open(".env", "w") as f:
            f.write(config_content)
        print("✅ Configuração salva em .env")
        return True
    except Exception as e:
        print(f"❌ Erro ao salvar configuração: {e}")
        return False


def main():
    """Função principal"""
    print("🔧 Configurador de API Key Asaas")
    print("=" * 50)

    print("📋 Para obter uma API key válida:")
    print("1. Acesse: https://www.asaas.com/")
    print("2. Faça login na sua conta")
    print("3. Vá em 'Minha conta' > 'Integração' > 'Chaves de API'")
    print("4. Gere uma nova chave de API")
    print("5. Copie a chave gerada")
    print()

    # Solicita API key
    api_key = input("Cole sua API key aqui: ").strip()

    if not api_key:
        print("❌ API key não fornecida.")
        sys.exit(1)

    # Testa a API key
    if not test_api_key(api_key):
        print("❌ API key inválida. Verifique se a chave está correta.")
        sys.exit(1)

    # Pergunta se quer fazer teste completo
    print("\n🧪 Deseja fazer um teste completo (criar cliente e pagamento)?")
    resposta = input("Digite 's' para sim ou qualquer tecla para não: ").strip().lower()

    if resposta == "s":
        if create_test_payment(api_key):
            print("\n✅ Teste completo realizado com sucesso!")
        else:
            print("\n❌ Teste completo falhou.")

    # Salva configuração
    if save_api_key(api_key):
        print("\n🎉 Configuração concluída!")
        print("Agora você pode executar: python testar_asaas_integracao.py")
    else:
        print("\n❌ Erro ao salvar configuração.")


if __name__ == "__main__":
    main()

