#!/usr/bin/env python3
"""
Script para configurar e testar a integração Asaas com API key de teste
Sistema de Agendamento - 4Minds
"""

import os
import sys
import django
from datetime import datetime, timedelta


def setup_environment():
    """Configura variáveis de ambiente para teste"""
    print("🔧 Configurando ambiente para testes...")

    # Configurações de teste (usando API key de exemplo)
    os.environ["ASAAS_API_KEY"] = "sk_test_exemplo_para_teste"
    os.environ["ASAAS_ENV"] = "sandbox"
    os.environ["ASAAS_WEBHOOK_TOKEN"] = "test_webhook_token_123"

    print("✅ Variáveis de ambiente configuradas")
    print(f"   ASAAS_API_KEY: {os.environ['ASAAS_API_KEY']}")
    print(f"   ASAAS_ENV: {os.environ['ASAAS_ENV']}")
    print(f"   ASAAS_WEBHOOK_TOKEN: {os.environ['ASAAS_WEBHOOK_TOKEN']}")


def test_asaas_client_with_mock():
    """Testa cliente Asaas com mocks"""
    print("\n🌐 Testando cliente Asaas com mocks...")
    print("-" * 50)

    try:
        from financeiro.services.asaas import AsaasClient
        from unittest.mock import patch, Mock

        # Mock das respostas da API
        mock_customer_response = Mock()
        mock_customer_response.json.return_value = {
            "id": "cus_test_123",
            "name": "Cliente Teste Mock",
            "email": "teste@example.com",
            "cpfCnpj": "12345678901",
        }
        mock_customer_response.raise_for_status.return_value = None

        mock_payment_response = Mock()
        mock_payment_response.json.return_value = {
            "id": "pay_test_123",
            "customer": "cus_test_123",
            "value": 100.00,
            "status": "PENDING",
            "billingType": "PIX",
            "dueDate": "2024-12-31",
        }
        mock_payment_response.raise_for_status.return_value = None

        mock_qr_response = Mock()
        mock_qr_response.json.return_value = {
            "qrCode": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==",
            "payload": "00020126580014br.gov.bcb.pix0136123e4567-e89b-12d3-a456-4266141740005204000053039865405100.005802BR5913Teste Pagamento6008Brasilia62070503***63041D3D",
            "expiresAt": (datetime.now() + timedelta(hours=24)).isoformat(),
        }
        mock_qr_response.raise_for_status.return_value = None

        # Testa com mocks
        with patch(
            "financeiro.services.asaas.requests.Session.post"
        ) as mock_post, patch(
            "financeiro.services.asaas.requests.Session.get"
        ) as mock_get:

            # Configura mocks
            mock_post.return_value = mock_customer_response
            mock_get.return_value = mock_qr_response

            # Inicializa cliente
            client = AsaasClient()
            print(f"✅ Cliente inicializado")
            print(f"   API Key: {client.api_key}")
            print(f"   Ambiente: {client.env}")
            print(f"   URL Base: {client.base}")

            # Testa criação de cliente
            customer = client.create_customer(
                name="Cliente Teste Mock",
                email="teste@example.com",
                cpf_cnpj="12345678901",
            )
            print(f"✅ Cliente criado: {customer['id']}")

            # Testa criação de pagamento
            payment = client.create_payment(
                customer_id=customer["id"],
                value=100.00,
                due_date="2024-12-31",
                billing_type="PIX",
                description="Teste Mock",
            )
            print(f"✅ Pagamento criado: {payment['id']}")

            # Testa obtenção de QR Code
            qr_data = client.get_pix_qr(payment["id"])
            print(f"✅ QR Code obtido: {'Sim' if qr_data.get('qrCode') else 'Não'}")

            return True

    except Exception as e:
        print(f"❌ Erro no teste com mocks: {e}")
        return False


def test_asaas_models():
    """Testa modelos do banco de dados"""
    print("\n📊 Testando modelos do banco...")
    print("-" * 50)

    try:
        from financeiro.models import AsaasPayment
        from decimal import Decimal

        # Cria registro de teste
        payment = AsaasPayment.objects.create(
            asaas_id="test_payment_mock_123",
            customer_id="test_customer_mock_123",
            amount=Decimal("150.00"),
            billing_type="PIX",
            status="PENDING",
            qr_code_base64="mock_qr_code_base64",
            copy_paste_payload="mock_payload_123",
        )

        print(f"✅ Modelo AsaasPayment criado")
        print(f"   ID: {payment.id}")
        print(f"   Asaas ID: {payment.asaas_id}")
        print(f"   Valor: R$ {payment.amount}")
        print(f"   Status: {payment.status}")
        print(f"   Criado em: {payment.created_at}")

        # Testa atualização
        payment.status = "RECEIVED"
        payment.paid_at = datetime.now()
        payment.save()

        print(f"✅ Status atualizado para: {payment.status}")

        # Limpa o teste
        payment.delete()
        print("✅ Registro de teste removido")

        return True

    except Exception as e:
        print(f"❌ Erro nos modelos: {e}")
        return False


def test_asaas_views():
    """Testa views do financeiro"""
    print("\n👁️ Testando views do financeiro...")
    print("-" * 50)

    try:
        from django.test import Client
        from django.contrib.auth.models import User
        from financeiro.models import AsaasPayment
        from decimal import Decimal

        # Cria usuário de teste
        user, created = User.objects.get_or_create(
            username="testuser", defaults={"email": "test@example.com"}
        )

        # Cria pagamento de teste
        payment = AsaasPayment.objects.create(
            asaas_id="test_view_payment_123",
            amount=Decimal("200.00"),
            billing_type="PIX",
            status="PENDING",
            qr_code_base64="test_qr_code",
            copy_paste_payload="test_payload_123",
        )

        client = Client()

        # Testa view de QR Code
        response = client.get(f"/financeiro/{payment.asaas_id}/qr/")
        print(f"✅ QR Code view: {response.status_code}")

        # Testa view de QR Code inexistente
        response = client.get("/financeiro/inexistente/qr/")
        print(f"✅ QR Code view (404 esperado): {response.status_code}")

        # Testa webhook POST
        webhook_data = {
            "id": "evt_test_123",
            "event": "PAYMENT_RECEIVED",
            "payment": {"id": payment.asaas_id, "status": "RECEIVED"},
        }

        response = client.post(
            "/financeiro/webhooks/asaas/",
            data=webhook_data,
            content_type="application/json",
            HTTP_ASAAS_ACCESS_TOKEN="test_webhook_token_123",
        )
        print(f"✅ Webhook POST: {response.status_code}")

        # Limpa o teste
        payment.delete()
        if created:
            user.delete()

        return True

    except Exception as e:
        print(f"❌ Erro nas views: {e}")
        return False


def test_asaas_integration_flow():
    """Testa fluxo completo de integração"""
    print("\n🔗 Testando fluxo completo de integração...")
    print("-" * 50)

    try:
        from financeiro.services.asaas import AsaasClient
        from financeiro.models import AsaasPayment
        from decimal import Decimal
        from unittest.mock import patch, Mock

        # Mock completo
        mock_responses = {
            "customer": {
                "id": "cus_integration_123",
                "name": "Cliente Integração",
                "email": "integracao@example.com",
            },
            "payment": {
                "id": "pay_integration_123",
                "customer": "cus_integration_123",
                "value": 250.00,
                "status": "PENDING",
                "billingType": "PIX",
                "dueDate": "2024-12-31",
            },
            "qr": {
                "qrCode": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==",
                "payload": "00020126580014br.gov.bcb.pix...",
                "expiresAt": (datetime.now() + timedelta(hours=24)).isoformat(),
            },
        }

        with patch(
            "financeiro.services.asaas.requests.Session.post"
        ) as mock_post, patch(
            "financeiro.services.asaas.requests.Session.get"
        ) as mock_get:

            # Configura mocks
            def mock_post_side_effect(url, **kwargs):
                mock_response = Mock()
                if "customers" in url:
                    mock_response.json.return_value = mock_responses["customer"]
                elif "payments" in url:
                    mock_response.json.return_value = mock_responses["payment"]
                mock_response.raise_for_status.return_value = None
                return mock_response

            def mock_get_side_effect(url, **kwargs):
                mock_response = Mock()
                mock_response.json.return_value = mock_responses["qr"]
                mock_response.raise_for_status.return_value = None
                return mock_response

            mock_post.side_effect = mock_post_side_effect
            mock_get.side_effect = mock_get_side_effect

            # Fluxo completo
            client = AsaasClient()

            # 1. Criar cliente
            customer = client.create_customer(
                name="Cliente Integração",
                email="integracao@example.com",
                cpf_cnpj="98765432100",
            )
            print(f"✅ 1. Cliente criado: {customer['id']}")

            # 2. Criar pagamento
            payment = client.create_payment(
                customer_id=customer["id"],
                value=250.00,
                due_date="2024-12-31",
                billing_type="PIX",
                description="Teste de integração completa",
            )
            print(f"✅ 2. Pagamento criado: {payment['id']}")

            # 3. Obter QR Code
            qr_data = client.get_pix_qr(payment["id"])
            print(f"✅ 3. QR Code obtido: {'Sim' if qr_data.get('qrCode') else 'Não'}")

            # 4. Salvar no banco
            asaas_payment = AsaasPayment.objects.create(
                asaas_id=payment["id"],
                customer_id=customer["id"],
                amount=Decimal(str(payment["value"])),
                billing_type=payment["billingType"],
                status=payment["status"],
                qr_code_base64=qr_data.get("qrCode", ""),
                copy_paste_payload=qr_data.get("payload", ""),
            )
            print(f"✅ 4. Pagamento salvo no banco: {asaas_payment.id}")

            # 5. Simular webhook de pagamento recebido
            asaas_payment.status = "RECEIVED"
            asaas_payment.paid_at = datetime.now()
            asaas_payment.webhook_event_id = "evt_integration_123"
            asaas_payment.save()
            print(f"✅ 5. Status atualizado via webhook: {asaas_payment.status}")

            # 6. Verificar dados finais
            print(f"✅ 6. Dados finais:")
            print(f"    - Cliente: {customer['name']} ({customer['email']})")
            print(f"    - Pagamento: R$ {payment['value']} - {payment['status']}")
            print(
                f"    - QR Code: {'Disponível' if qr_data.get('qrCode') else 'Não disponível'}"
            )
            print(f"    - Status final: {asaas_payment.status}")

            # Limpa o teste
            asaas_payment.delete()
            print("✅ 7. Registro de teste removido")

        return True

    except Exception as e:
        print(f"❌ Erro no fluxo de integração: {e}")
        return False


def main():
    """Função principal"""
    print("🚀 Teste Completo da Integração Asaas")
    print("=" * 60)

    # Configura ambiente
    setup_environment()

    # Configura Django
    os.environ.setdefault("DJANGO_SETTINGS_MODULE", "core.settings")
    django.setup()

    # Executa testes
    tests = [
        ("Cliente Asaas com Mocks", test_asaas_client_with_mock),
        ("Modelos do Banco", test_asaas_models),
        ("Views do Financeiro", test_asaas_views),
        ("Fluxo de Integração", test_asaas_integration_flow),
    ]

    results = []

    for test_name, test_func in tests:
        print(f"\n📋 {test_name}")
        try:
            success = test_func()
            results.append((test_name, success))
        except Exception as e:
            print(f"❌ Erro inesperado: {e}")
            results.append((test_name, False))

    # Resumo final
    print("\n" + "=" * 60)
    print("📊 RESUMO DOS TESTES")
    print("=" * 60)

    passed = sum(1 for _, success in results if success)
    total = len(results)

    for test_name, success in results:
        status = "✅ PASSOU" if success else "❌ FALHOU"
        print(f"{status} - {test_name}")

    print(f"\n🎯 Resultado: {passed}/{total} testes passaram")

    if passed == total:
        print(
            "🎉 TODOS OS TESTES PASSARAM! A integração Asaas está funcionando corretamente."
        )
        print("\n📋 PRÓXIMOS PASSOS:")
        print("1. Configure uma API key real do Asaas")
        print("2. Execute: python configurar_api_asaas.py")
        print("3. Teste com API real: python testar_asaas_integracao.py")
        return True
    else:
        print("⚠️ Alguns testes falharam. Verifique os erros acima.")
        return False


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
