#!/usr/bin/env python3
"""
Script para executar testes de integração com API real do Asaas
"""
import os
import sys
import django
from datetime import datetime, timedelta


def setup_django():
    """Configura Django para execução dos testes"""
    os.environ.setdefault("DJANGO_SETTINGS_MODULE", "core.settings")
    django.setup()


def load_real_api_config():
    """Carrega configurações da API real do arquivo"""
    config_file = ".env"
    if os.path.exists(config_file):
        print(f"✅ Carregando configurações de {config_file}")
        with open(config_file, "r") as f:
            for line in f:
                if line.strip() and not line.startswith("#"):
                    if "=" in line:
                        key, value = line.strip().split("=", 1)
                        os.environ[key] = value
    else:
        print("❌ Arquivo .env não encontrado")
        return False

    return True


def test_real_api_connection():
    """Testa conexão real com a API Asaas"""
    print("🌐 Testando conexão real com API Asaas...")
    print("=" * 50)

    try:
        from financeiro.services.asaas import AsaasClient

        # Inicializa cliente com API key real
        client = AsaasClient()
        print(f"✅ Cliente inicializado")
        print(f"✅ API Key: {client.api_key[:20]}...")
        print(f"✅ Ambiente: {client.env}")
        print(f"✅ URL Base: {client.base}")

        return client

    except Exception as e:
        print(f"❌ Erro ao inicializar cliente: {e}")
        return None


def test_create_customer(client):
    """Testa criação real de cliente"""
    print("\n📝 Testando criação de cliente...")
    print("-" * 30)

    try:
        # Dados de teste únicos
        timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
        customer_data = {
            "name": f"Cliente Teste {timestamp}",
            "email": f"teste.{timestamp}@example.com",
            "cpf_cnpj": f"123456789{timestamp[-4:]}",
            "phone": "11999999999",
        }

        print(f"📋 Dados do cliente: {customer_data['name']}")
        customer = client.create_customer(**customer_data)

        print(f"✅ Cliente criado com sucesso!")
        print(f"   ID: {customer['id']}")
        print(f"   Nome: {customer['name']}")
        print(f"   Email: {customer.get('email', 'N/A')}")

        return customer

    except Exception as e:
        print(f"❌ Erro ao criar cliente: {e}")
        return None


def test_create_payment(client, customer_id):
    """Testa criação real de pagamento PIX"""
    print("\n💰 Testando criação de pagamento PIX...")
    print("-" * 30)

    try:
        # Data de vencimento para 7 dias
        due_date = (datetime.now() + timedelta(days=7)).strftime("%Y-%m-%d")

        payment_data = {
            "customer_id": customer_id,
            "value": 10.00,  # Valor baixo para teste
            "due_date": due_date,
            "billing_type": "PIX",
            "description": f"Teste de integração - {datetime.now().strftime('%d/%m/%Y %H:%M')}",
        }

        print(f"📋 Dados do pagamento: R$ {payment_data['value']}")
        payment = client.create_payment(**payment_data)

        print(f"✅ Pagamento criado com sucesso!")
        print(f"   ID: {payment['id']}")
        print(f"   Valor: R$ {payment['value']}")
        print(f"   Status: {payment['status']}")
        print(f"   Vencimento: {payment['dueDate']}")

        return payment

    except Exception as e:
        print(f"❌ Erro ao criar pagamento: {e}")
        return None


def test_get_pix_qr(client, payment_id):
    """Testa obtenção de QR Code PIX"""
    print("\n📱 Testando obtenção de QR Code PIX...")
    print("-" * 30)

    try:
        qr_data = client.get_pix_qr(payment_id)

        print(f"✅ QR Code obtido com sucesso!")
        print(f"   QR Code presente: {'Sim' if qr_data.get('qrCode') else 'Não'}")
        print(f"   Payload presente: {'Sim' if qr_data.get('payload') else 'Não'}")
        print(f"   Expira em: {qr_data.get('expiresAt', 'N/A')}")

        # Salva dados do QR Code
        if qr_data.get("qrCode"):
            qr_file = f"qr_code_test_{payment_id}.txt"
            with open(qr_file, "w") as f:
                f.write(f"Payment ID: {payment_id}\n")
                f.write(f"QR Code: {qr_data['qrCode']}\n")
                f.write(f"Payload: {qr_data.get('payload', '')}\n")
            print(f"   QR Code salvo em: {qr_file}")

        return qr_data

    except Exception as e:
        print(f"❌ Erro ao obter QR Code: {e}")
        return None


def test_get_payment_info(client, payment_id):
    """Testa obtenção de informações do pagamento"""
    print("\n📊 Testando obtenção de informações do pagamento...")
    print("-" * 30)

    try:
        payment_info = client.get_payment(payment_id)

        print(f"✅ Informações obtidas com sucesso!")
        print(f"   ID: {payment_info['id']}")
        print(f"   Status: {payment_info['status']}")
        print(f"   Valor: R$ {payment_info['value']}")
        print(f"   Cliente: {payment_info['customer']}")
        print(f"   Criado em: {payment_info.get('dateCreated', 'N/A')}")

        return payment_info

    except Exception as e:
        print(f"❌ Erro ao obter informações: {e}")
        return None


def run_integration_tests():
    """Executa todos os testes de integração"""
    print("🚀 Iniciando Testes de Integração com API Real Asaas")
    print("=" * 60)

    # Testa conexão
    client = test_real_api_connection()
    if not client:
        return False

    # Testa criação de cliente
    customer = test_create_customer(client)
    if not customer:
        return False

    # Testa criação de pagamento
    payment = test_create_payment(client, customer["id"])
    if not payment:
        return False

    # Testa obtenção de QR Code
    qr_data = test_get_pix_qr(client, payment["id"])
    if not qr_data:
        return False

    # Testa obtenção de informações
    payment_info = test_get_payment_info(client, payment["id"])
    if not payment_info:
        return False

    print("\n" + "=" * 60)
    print("🎉 TODOS OS TESTES DE INTEGRAÇÃO PASSARAM!")
    print("=" * 60)
    print(f"✅ Cliente criado: {customer['id']}")
    print(f"✅ Pagamento criado: {payment['id']}")
    print(f"✅ QR Code obtido: {'Sim' if qr_data.get('qrCode') else 'Não'}")
    print(f"✅ Informações obtidas: {'Sim' if payment_info else 'Não'}")

    print("\n📋 RESUMO:")
    print(f"- Cliente: {customer['name']} ({customer['email']})")
    print(f"- Pagamento: R$ {payment['value']} - Status: {payment['status']}")
    print(f"- QR Code: Disponível para pagamento")
    print(f"- Webhook URL: https://seu-dominio.com/financeiro/webhooks/asaas/")

    return True


def main():
    """Função principal"""
    print("🔧 Configurando ambiente...")

    # Carrega configurações ANTES de configurar Django
    if not load_real_api_config():
        sys.exit(1)

    setup_django()

    print("🧪 Executando testes de integração...")
    success = run_integration_tests()

    if success:
        print("\n✅ Testes de integração concluídos com sucesso!")
        sys.exit(0)
    else:
        print("\n❌ Testes de integração falharam.")
        sys.exit(1)


if __name__ == "__main__":
    main()
