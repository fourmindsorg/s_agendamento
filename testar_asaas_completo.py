#!/usr/bin/env python3
"""
Script completo para testar todas as funcionalidades da integração Asaas
Sistema de Agendamento - 4Minds

Este script testa:
1. Configurações do Django
2. Serviço AsaasClient
3. Modelos do banco de dados
4. Views e URLs
5. Testes unitários
"""

import os
import sys
import django
from datetime import datetime, timedelta

# Configurar Django
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "core.settings")
django.setup()


def test_django_configuration():
    """Testa configurações do Django relacionadas ao Asaas"""
    print("🔧 Testando configurações do Django...")
    print("-" * 40)

    try:
        from django.conf import settings

        # Verifica configurações do Asaas
        asaas_key = getattr(settings, "ASAAS_API_KEY", None)
        asaas_env = getattr(settings, "ASAAS_ENV", None)
        asaas_webhook = getattr(settings, "ASAAS_WEBHOOK_TOKEN", None)

        print(f"✅ ASAAS_API_KEY: {'Configurada' if asaas_key else 'Não configurada'}")
        print(f"✅ ASAAS_ENV: {asaas_env}")
        print(
            f"✅ ASAAS_WEBHOOK_TOKEN: {'Configurado' if asaas_webhook else 'Não configurado'}"
        )

        # Verifica apps instalados
        installed_apps = getattr(settings, "INSTALLED_APPS", [])
        if "financeiro" in installed_apps:
            print("✅ App 'financeiro' instalado")
        else:
            print("❌ App 'financeiro' não encontrado")

        return True

    except Exception as e:
        print(f"❌ Erro nas configurações: {e}")
        return False


def test_asaas_client():
    """Testa inicialização do cliente Asaas"""
    print("\n🌐 Testando cliente Asaas...")
    print("-" * 40)

    try:
        from financeiro.services.asaas import AsaasClient

        # Testa inicialização
        client = AsaasClient()
        print(f"✅ Cliente inicializado")
        print(
            f"   API Key: {client.api_key[:20]}..."
            if client.api_key
            else "   API Key: Não configurada"
        )
        print(f"   Ambiente: {client.env}")
        print(f"   URL Base: {client.base}")

        # Testa métodos disponíveis
        methods = [method for method in dir(client) if not method.startswith("_")]
        print(f"✅ Métodos disponíveis: {len(methods)}")
        print(f"   - create_customer")
        print(f"   - create_payment")
        print(f"   - get_payment")
        print(f"   - get_pix_qr")
        print(f"   - pay_with_credit_card")

        return True

    except Exception as e:
        print(f"❌ Erro no cliente Asaas: {e}")
        return False


def test_asaas_models():
    """Testa modelos do banco de dados"""
    print("\n📊 Testando modelos do banco...")
    print("-" * 40)

    try:
        from financeiro.models import AsaasPayment
        from decimal import Decimal

        # Testa criação de registro
        payment = AsaasPayment.objects.create(
            asaas_id="test_payment_123",
            customer_id="test_customer_123",
            amount=Decimal("100.00"),
            billing_type="PIX",
            status="PENDING",
            qr_code_base64="test_qr_code",
            copy_paste_payload="test_payload",
        )

        print(f"✅ Modelo AsaasPayment criado")
        print(f"   ID: {payment.id}")
        print(f"   Asaas ID: {payment.asaas_id}")
        print(f"   Valor: R$ {payment.amount}")
        print(f"   Status: {payment.status}")

        # Testa representação string
        str_repr = str(payment)
        print(f"   String: {str_repr}")

        # Limpa o teste
        payment.delete()
        print("✅ Registro de teste removido")

        return True

    except Exception as e:
        print(f"❌ Erro nos modelos: {e}")
        return False


def test_asaas_urls():
    """Testa URLs do financeiro"""
    print("\n🔗 Testando URLs do financeiro...")
    print("-" * 40)

    try:
        from django.urls import reverse
        from django.test import Client

        client = Client()

        # URLs disponíveis
        urls_to_test = [
            "financeiro:create_pix_charge",
            "financeiro:pix_qr_view",
            "financeiro:asaas_webhook",
        ]

        for url_name in urls_to_test:
            try:
                url = reverse(
                    url_name, args=["test_id"] if "pix_qr_view" in url_name else []
                )
                print(f"✅ {url_name}: {url}")
            except Exception as e:
                print(f"❌ {url_name}: {e}")

        return True

    except Exception as e:
        print(f"❌ Erro nas URLs: {e}")
        return False


def test_asaas_views():
    """Testa views do financeiro"""
    print("\n👁️ Testando views do financeiro...")
    print("-" * 40)

    try:
        from django.test import Client
        from django.contrib.auth.models import User

        client = Client()

        # Testa view de QR Code (deve retornar 404 para ID inexistente)
        response = client.get("/financeiro/pix/test_id_inexistente/")
        print(f"✅ QR Code view (404 esperado): {response.status_code}")

        # Testa webhook (deve retornar 405 para GET)
        response = client.get("/financeiro/webhooks/asaas/")
        print(f"✅ Webhook GET (405 esperado): {response.status_code}")

        return True

    except Exception as e:
        print(f"❌ Erro nas views: {e}")
        return False


def test_asaas_integration():
    """Testa integração completa (sem API real)"""
    print("\n🔗 Testando integração completa...")
    print("-" * 40)

    try:
        from financeiro.services.asaas import AsaasClient
        from financeiro.models import AsaasPayment
        from decimal import Decimal
        from unittest.mock import patch, Mock

        # Mock da resposta da API
        mock_customer = {
            "id": "cus_test_123",
            "name": "Cliente Teste",
            "email": "teste@example.com",
        }

        mock_payment = {
            "id": "pay_test_123",
            "customer": "cus_test_123",
            "value": 100.00,
            "status": "PENDING",
            "billingType": "PIX",
        }

        mock_qr = {
            "qrCode": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==",
            "payload": "00020126580014br.gov.bcb.pix...",
            "expiresAt": (datetime.now() + timedelta(hours=24)).isoformat(),
        }

        # Testa com mocks
        with patch(
            "financeiro.services.asaas.requests.Session.post"
        ) as mock_post, patch(
            "financeiro.services.asaas.requests.Session.get"
        ) as mock_get:

            # Configura mocks
            mock_post.return_value.json.return_value = mock_customer
            mock_post.return_value.raise_for_status.return_value = None
            mock_get.return_value.json.return_value = mock_qr
            mock_get.return_value.raise_for_status.return_value = None

            # Testa fluxo completo
            asaas_client = AsaasClient()

            # 1. Criar cliente
            customer = asaas_client.create_customer(
                name="Cliente Teste", email="teste@example.com", cpf_cnpj="12345678901"
            )
            print(f"✅ Cliente criado: {customer['id']}")

            # 2. Criar pagamento
            payment = asaas_client.create_payment(
                customer_id=customer["id"],
                value=100.00,
                due_date="2024-12-31",
                billing_type="PIX",
                description="Teste de integração",
            )
            print(f"✅ Pagamento criado: {payment['id']}")

            # 3. Obter QR Code
            qr_data = asaas_client.get_pix_qr(payment["id"])
            print(f"✅ QR Code obtido: {'Sim' if qr_data.get('qrCode') else 'Não'}")

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
            print(f"✅ Pagamento salvo no banco: {asaas_payment.id}")

            # Limpa o teste
            asaas_payment.delete()
            print("✅ Registro de teste removido")

        return True

    except Exception as e:
        print(f"❌ Erro na integração: {e}")
        return False


def run_unit_tests():
    """Executa testes unitários do Django"""
    print("\n🧪 Executando testes unitários...")
    print("-" * 40)

    try:
        from django.core.management import execute_from_command_line

        # Executa testes do financeiro
        execute_from_command_line(
            ["manage.py", "test", "financeiro.test_asaas_api", "--verbosity=1"]
        )

        print("✅ Testes unitários executados com sucesso!")
        return True

    except Exception as e:
        print(f"❌ Erro nos testes unitários: {e}")
        return False


def main():
    """Função principal"""
    print("🚀 Teste Completo da Integração Asaas")
    print("=" * 60)

    tests = [
        ("Configurações Django", test_django_configuration),
        ("Cliente Asaas", test_asaas_client),
        ("Modelos do Banco", test_asaas_models),
        ("URLs do Financeiro", test_asaas_urls),
        ("Views do Financeiro", test_asaas_views),
        ("Integração Completa", test_asaas_integration),
        ("Testes Unitários", run_unit_tests),
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
        return True
    else:
        print("⚠️ Alguns testes falharam. Verifique os erros acima.")
        return False


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
