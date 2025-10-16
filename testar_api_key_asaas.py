#!/usr/bin/env python3
"""
Script para testar se a API key do Asaas está funcionando
"""
import requests
import os


def test_api_key():
    """Testa se a API key está funcionando com uma requisição simples"""

    # API key do arquivo env.example
    api_key = "aact_hmlg_000MzkwODA2MWY2OGM3MWRlMDU2NWM3MzJlNzZmNGZhZGY6OjRiY2RkYjY2LWU0ZDAtNDlkOC04ZGNhLTFlODJlYjY1M2UxZTo6JGFhY2hfNWM4NGU4ZjEtMzUwNi00NjMzLTg2NmEtYzNlZmEzNWVhZDc4"

    # URL base do sandbox
    base_url = "https://api-sandbox.asaas.com/v3"

    print("🔍 Testando API Key do Asaas...")
    print("=" * 50)
    print(f"API Key: {api_key[:20]}...")
    print(f"URL Base: {base_url}")

    # Headers para autenticação
    headers = {"access_token": api_key, "Content-Type": "application/json"}

    # Teste 1: Listar clientes (endpoint simples)
    print("\n📋 Teste 1: Listando clientes...")
    try:
        response = requests.get(f"{base_url}/customers", headers=headers, timeout=10)
        print(f"Status Code: {response.status_code}")

        if response.status_code == 200:
            print("✅ API Key válida! Conseguiu listar clientes.")
            data = response.json()
            print(f"Total de clientes: {data.get('totalCount', 'N/A')}")
        else:
            print(f"❌ Erro: {response.status_code}")
            print(f"Resposta: {response.text}")

    except requests.exceptions.RequestException as e:
        print(f"❌ Erro de conexão: {e}")

    # Teste 2: Criar cliente de teste
    print("\n📝 Teste 2: Criando cliente de teste...")
    try:
        customer_data = {
            "name": "Cliente Teste API",
            "email": "teste@example.com",
            "cpfCnpj": "12345678901",
        }

        response = requests.post(
            f"{base_url}/customers", headers=headers, json=customer_data, timeout=10
        )

        print(f"Status Code: {response.status_code}")

        if response.status_code == 200:
            print("✅ Cliente criado com sucesso!")
            data = response.json()
            print(f"ID do cliente: {data.get('id')}")
            return data.get("id")
        else:
            print(f"❌ Erro: {response.status_code}")
            print(f"Resposta: {response.text}")

    except requests.exceptions.RequestException as e:
        print(f"❌ Erro de conexão: {e}")

    return None


def test_create_payment(customer_id):
    """Testa criação de pagamento se o cliente foi criado"""
    if not customer_id:
        return

    api_key = "aact_hmlg_000MzkwODA2MWY2OGM3MWRlMDU2NWM3MzJlNzZmNGZhZGY6OjRiY2RkYjY2LWU0ZDAtNDlkOC04ZGNhLTFlODJlYjY1M2UxZTo6JGFhY2hfNWM4NGU4ZjEtMzUwNi00NjMzLTg2NmEtYzNlZmEzNWVhZDc4"
    base_url = "https://api-sandbox.asaas.com/v3"

    headers = {"access_token": api_key, "Content-Type": "application/json"}

    print(f"\n💰 Teste 3: Criando pagamento para cliente {customer_id}...")
    try:
        payment_data = {
            "customer": customer_id,
            "value": 10.00,
            "dueDate": "2024-12-31",
            "billingType": "PIX",
            "description": "Teste de integração",
        }

        response = requests.post(
            f"{base_url}/payments", headers=headers, json=payment_data, timeout=10
        )

        print(f"Status Code: {response.status_code}")

        if response.status_code == 200:
            print("✅ Pagamento criado com sucesso!")
            data = response.json()
            print(f"ID do pagamento: {data.get('id')}")
            return data.get("id")
        else:
            print(f"❌ Erro: {response.status_code}")
            print(f"Resposta: {response.text}")

    except requests.exceptions.RequestException as e:
        print(f"❌ Erro de conexão: {e}")

    return None


def main():
    """Função principal"""
    print("🚀 Testador de API Key Asaas")
    print("=" * 50)

    # Testa API key
    customer_id = test_api_key()

    # Testa criação de pagamento se cliente foi criado
    if customer_id:
        payment_id = test_create_payment(customer_id)

        if payment_id:
            print(f"\n🎉 Testes concluídos com sucesso!")
            print(f"Cliente ID: {customer_id}")
            print(f"Pagamento ID: {payment_id}")
        else:
            print(f"\n⚠️ Cliente criado, mas pagamento falhou")
    else:
        print(f"\n❌ Falha na autenticação ou criação de cliente")


if __name__ == "__main__":
    main()

