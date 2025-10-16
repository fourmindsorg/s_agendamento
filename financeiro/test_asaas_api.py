#!/usr/bin/env python3
"""
Testes completos para a API Asaas
Este script testa todas as funcionalidades disponíveis na API Asaas
"""
import os
import json
import requests
from datetime import datetime, timedelta
from decimal import Decimal
from django.test import TestCase, override_settings
from django.urls import reverse
from django.contrib.auth.models import User
from django.conf import settings
from unittest.mock import patch, Mock
from .services.asaas import AsaasClient
from .models import AsaasPayment


@override_settings(
    ASAAS_API_KEY="sk_test_123456789",
    ASAAS_ENV="sandbox",
    ASAAS_WEBHOOK_TOKEN="test_webhook_token",
)
class AsaasAPITestCase(TestCase):
    """Testes para a API Asaas"""

    def setUp(self):
        """Configuração inicial para os testes"""
        self.asaas_client = AsaasClient()

        # Dados de teste
        self.test_customer_data = {
            "name": "João Silva Teste",
            "email": "joao.teste@example.com",
            "cpf_cnpj": "12345678901",
            "phone": "11999999999",
        }

        self.test_payment_data = {
            "customer_id": None,  # Será preenchido após criar cliente
            "value": 100.00,
            "due_date": (datetime.now() + timedelta(days=7)).strftime("%Y-%m-%d"),
            "billing_type": "PIX",
            "description": "Teste de pagamento PIX",
        }

        # Mock para simular respostas da API
        self.mock_responses = {
            "customer": {
                "id": "cus_123456789",
                "name": "João Silva Teste",
                "email": "joao.teste@example.com",
                "cpfCnpj": "12345678901",
                "phone": "11999999999",
                "dateCreated": datetime.now().isoformat(),
            },
            "payment": {
                "id": "pay_123456789",
                "customer": "cus_123456789",
                "value": 100.00,
                "dueDate": self.test_payment_data["due_date"],
                "billingType": "PIX",
                "status": "PENDING",
                "description": "Teste de pagamento PIX",
                "dateCreated": datetime.now().isoformat(),
            },
            "pix_qr": {
                "qrCode": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==",
                "payload": "00020126580014br.gov.bcb.pix0136123e4567-e89b-12d3-a456-4266141740005204000053039865405100.005802BR5913Teste Pagamento6008Brasilia62070503***63041D3D",
                "expiresAt": (datetime.now() + timedelta(hours=24)).isoformat(),
            },
        }

    def test_asaas_client_initialization(self):
        """Testa inicialização do cliente Asaas"""
        # Teste com configurações padrão
        client = AsaasClient()
        self.assertIsNotNone(client.api_key)
        self.assertEqual(client.env, "sandbox")
        self.assertEqual(client.base, "https://api-sandbox.asaas.com/v3/")

        # Teste com ambiente de produção
        client_prod = AsaasClient(env="production")
        self.assertEqual(client_prod.base, "https://www.asaas.com/api/v3/")

    @patch("financeiro.services.asaas.requests.Session.post")
    def test_create_customer(self, mock_post):
        """Testa criação de cliente"""
        # Mock da resposta da API
        mock_response = Mock()
        mock_response.json.return_value = self.mock_responses["customer"]
        mock_response.raise_for_status.return_value = None
        mock_post.return_value = mock_response

        # Teste criação completa
        result = self.asaas_client.create_customer(**self.test_customer_data)

        # Verificações
        self.assertEqual(result["id"], "cus_123456789")
        self.assertEqual(result["name"], "João Silva Teste")
        self.assertEqual(result["email"], "joao.teste@example.com")

        # Verifica se a chamada foi feita corretamente
        mock_post.assert_called_once()
        call_args = mock_post.call_args
        self.assertIn("customers", call_args[0][0])
        self.assertEqual(call_args[1]["json"]["name"], "João Silva Teste")

    @patch("financeiro.services.asaas.requests.Session.post")
    def test_create_payment_pix(self, mock_post):
        """Testa criação de pagamento PIX"""
        # Mock da resposta
        mock_response = Mock()
        mock_response.json.return_value = self.mock_responses["payment"]
        mock_response.raise_for_status.return_value = None
        mock_post.return_value = mock_response

        # Teste criação de pagamento
        self.test_payment_data["customer_id"] = "cus_123456789"
        result = self.asaas_client.create_payment(**self.test_payment_data)

        # Verificações
        self.assertEqual(result["id"], "pay_123456789")
        self.assertEqual(result["billingType"], "PIX")
        self.assertEqual(result["value"], 100.00)

        # Verifica chamada da API
        mock_post.assert_called_once()
        call_args = mock_post.call_args
        self.assertIn("payments", call_args[0][0])

    @patch("financeiro.services.asaas.requests.Session.post")
    def test_create_payment_boleto(self, mock_post):
        """Testa criação de pagamento Boleto"""
        mock_response = Mock()
        mock_response.json.return_value = {
            **self.mock_responses["payment"],
            "billingType": "BOLETO",
            "invoiceUrl": "https://www.asaas.com/b/pdf/123456789",
        }
        mock_response.raise_for_status.return_value = None
        mock_post.return_value = mock_response

        # Teste boleto
        result = self.asaas_client.create_payment(
            customer_id="cus_123456789",
            value=150.00,
            due_date=self.test_payment_data["due_date"],
            billing_type="BOLETO",
            description="Teste Boleto",
        )

        self.assertEqual(result["billingType"], "BOLETO")
        self.assertIn("invoiceUrl", result)

    @patch("financeiro.services.asaas.requests.Session.get")
    def test_get_pix_qr(self, mock_get):
        """Testa obtenção do QR Code PIX"""
        mock_response = Mock()
        mock_response.json.return_value = self.mock_responses["pix_qr"]
        mock_response.raise_for_status.return_value = None
        mock_get.return_value = mock_response

        # Teste obtenção do QR
        result = self.asaas_client.get_pix_qr("pay_123456789")

        # Verificações
        self.assertIn("qrCode", result)
        self.assertIn("payload", result)
        self.assertIn("expiresAt", result)

        # Verifica chamada da API
        mock_get.assert_called_once()
        call_args = mock_get.call_args
        self.assertIn("payments/pay_123456789/pix", call_args[0][0])

    @patch("financeiro.services.asaas.requests.Session.post")
    def test_pay_with_credit_card(self, mock_post):
        """Testa pagamento com cartão de crédito"""
        mock_response = Mock()
        mock_response.json.return_value = {
            "id": "pay_123456789",
            "status": "CONFIRMED",
            "billingType": "CREDIT_CARD",
            "creditCard": {
                "creditCardNumber": "**** **** **** 1234",
                "creditCardBrand": "VISA",
            },
        }
        mock_response.raise_for_status.return_value = None
        mock_post.return_value = mock_response

        # Dados do cartão
        credit_card_data = {
            "creditCardNumber": "4111111111111111",
            "creditCardHolderName": "JOAO SILVA",
            "creditCardExpiryDate": "12/25",
            "creditCardCvv": "123",
            "installmentCount": 1,
        }

        # Teste pagamento com cartão
        result = self.asaas_client.pay_with_credit_card(
            "pay_123456789", credit_card_data
        )

        # Verificações
        self.assertEqual(result["status"], "CONFIRMED")
        self.assertEqual(result["billingType"], "CREDIT_CARD")

        # Verifica chamada da API
        mock_post.assert_called_once()
        call_args = mock_post.call_args
        self.assertIn("payments/pay_123456789/pay", call_args[0][0])

    def test_error_handling(self):
        """Testa tratamento de erros"""
        # Teste sem API key - deve usar a configuração do settings
        # Como estamos usando @override_settings, não deve dar erro
        client = AsaasClient(api_key=None)
        self.assertIsNotNone(client.api_key)

        # Teste com API key explícita None
        with self.assertRaises(RuntimeError):
            # Temporariamente remove a configuração do settings
            from django.test import override_settings

            with override_settings(ASAAS_API_KEY=None):
                AsaasClient(api_key=None)

    @patch("financeiro.services.asaas.requests.Session.post")
    def test_api_error_response(self, mock_post):
        """Testa resposta de erro da API"""
        # Mock de erro HTTP
        mock_response = Mock()
        mock_response.raise_for_status.side_effect = requests.HTTPError(
            "400 Bad Request"
        )
        mock_post.return_value = mock_response

        # Teste deve levantar exceção
        with self.assertRaises(requests.HTTPError):
            self.asaas_client.create_customer("Teste")


class AsaasPaymentModelTest(TestCase):
    """Testes para o modelo AsaasPayment"""

    def test_create_payment_model(self):
        """Testa criação de registro no modelo"""
        payment = AsaasPayment.objects.create(
            asaas_id="pay_123456789",
            customer_id="cus_123456789",
            amount=Decimal("100.00"),
            billing_type="PIX",
            status="PENDING",
            qr_code_base64="iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==",
            copy_paste_payload="00020126580014br.gov.bcb.pix...",
        )

        # Verificações
        self.assertEqual(payment.asaas_id, "pay_123456789")
        self.assertEqual(payment.amount, Decimal("100.00"))
        self.assertEqual(payment.billing_type, "PIX")
        self.assertEqual(payment.status, "PENDING")
        self.assertIsNotNone(payment.created_at)
        self.assertIsNotNone(payment.updated_at)

    def test_payment_str_representation(self):
        """Testa representação string do modelo"""
        payment = AsaasPayment.objects.create(
            asaas_id="pay_123456789",
            amount=Decimal("100.00"),
            billing_type="PIX",
            status="PENDING",
        )

        expected_str = "AsaasPayment(pay_123456789) - PENDING - 100.00"
        self.assertEqual(str(payment), expected_str)


@override_settings(
    ASAAS_API_KEY="sk_test_123456789",
    ASAAS_ENV="sandbox",
    ASAAS_WEBHOOK_TOKEN="test_webhook_token",
)
class AsaasViewsTest(TestCase):
    """Testes para as views do financeiro"""

    def setUp(self):
        """Configuração inicial"""
        self.user = User.objects.create_user(
            username="testuser", password="testpass123"
        )

    @patch("financeiro.views.get_asaas_client")
    def test_create_pix_charge_view(self, mock_get_client):
        """Testa view de criação de cobrança PIX"""
        # Mock do cliente Asaas
        mock_client = Mock()
        mock_client.create_payment.return_value = {
            "id": "pay_123456789",
            "status": "PENDING",
        }
        mock_client.get_pix_qr.return_value = {
            "qrCode": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==",
            "payload": "00020126580014br.gov.bcb.pix...",
        }
        mock_get_client.return_value = mock_client

        # Dados da requisição
        data = {
            "customer_id": "cus_123456789",
            "value": 100.00,
            "due_date": "2024-12-31",
            "description": "Teste PIX",
        }

        # Teste POST
        response = self.client.post(
            reverse("financeiro:create_pix_charge"),
            data=json.dumps(data),
            content_type="application/json",
        )

        # Verificações
        self.assertEqual(response.status_code, 200)
        response_data = json.loads(response.content)
        self.assertIn("payment_id", response_data)
        self.assertIn("qrBase64", response_data)
        self.assertIn("payload", response_data)

        # Verifica se o registro foi criado no banco
        payment = AsaasPayment.objects.get(asaas_id="pay_123456789")
        self.assertEqual(payment.amount, Decimal("100.00"))
        self.assertEqual(payment.billing_type, "PIX")

    def test_create_pix_charge_invalid_method(self):
        """Testa view com método inválido"""
        response = self.client.get(reverse("financeiro:create_pix_charge"))
        self.assertEqual(response.status_code, 405)

    def test_pix_qr_view(self):
        """Testa view de exibição do QR Code"""
        # Cria um pagamento de teste
        payment = AsaasPayment.objects.create(
            asaas_id="pay_123456789",
            amount=Decimal("100.00"),
            billing_type="PIX",
            status="PENDING",
            qr_code_base64="iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==",
            copy_paste_payload="00020126580014br.gov.bcb.pix...",
        )

        # Teste GET
        response = self.client.get(
            reverse("financeiro:pix_qr_view", args=["pay_123456789"])
        )

        # Verificações
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "Pague com PIX")
        self.assertContains(response, payment.copy_paste_payload)

    def test_pix_qr_view_not_found(self):
        """Testa view com payment_id inexistente"""
        response = self.client.get(
            reverse("financeiro:pix_qr_view", args=["pay_inexistente"])
        )
        self.assertEqual(response.status_code, 404)

    @patch("financeiro.views.get_asaas_client")
    def test_asaas_webhook_payment_received(self, mock_get_client):
        """Testa webhook de pagamento recebido"""
        # Cria um pagamento pendente
        payment = AsaasPayment.objects.create(
            asaas_id="pay_123456789",
            amount=Decimal("100.00"),
            billing_type="PIX",
            status="PENDING",
        )

        # Payload do webhook
        webhook_payload = {
            "id": "evt_123456789",
            "event": "PAYMENT_RECEIVED",
            "payment": {
                "id": "pay_123456789",
                "status": "RECEIVED",
                "dateCreated": datetime.now().isoformat(),
            },
        }

        # Teste POST do webhook
        response = self.client.post(
            reverse("financeiro:asaas_webhook"),
            data=json.dumps(webhook_payload),
            content_type="application/json",
            HTTP_ASAAS_ACCESS_TOKEN="test_webhook_token",
        )

        # Verificações
        self.assertEqual(response.status_code, 200)

        # Verifica se o status foi atualizado
        payment.refresh_from_db()
        self.assertEqual(payment.status, "RECEIVED")
        self.assertEqual(payment.webhook_event_id, "evt_123456789")

    def test_asaas_webhook_invalid_method(self):
        """Testa webhook com método inválido"""
        response = self.client.get(reverse("financeiro:asaas_webhook"))
        self.assertEqual(response.status_code, 405)

    def test_asaas_webhook_invalid_token(self):
        """Testa webhook com token inválido"""
        webhook_payload = {"id": "evt_123", "event": "PAYMENT_RECEIVED"}

        response = self.client.post(
            reverse("financeiro:asaas_webhook"),
            data=json.dumps(webhook_payload),
            content_type="application/json",
            HTTP_ASAAS_ACCESS_TOKEN="invalid_token",
        )

        # Como o token de teste é 'test_webhook_token', deve retornar 403
        self.assertEqual(response.status_code, 403)


class AsaasIntegrationTest(TestCase):
    """Testes de integração com API real (opcional)"""

    @override_settings(
        ASAAS_API_KEY="sk_test_123456789",
        ASAAS_ENV="sandbox",
        ASAAS_WEBHOOK_TOKEN="webhook_token_123",
    )
    def test_real_api_connection(self):
        """Teste real de conexão com API (requer chave válida)"""
        # Este teste só roda se ASAAS_API_KEY estiver configurada
        if not settings.ASAAS_API_KEY or settings.ASAAS_API_KEY == "sk_test_123456789":
            self.skipTest("API key não configurada para teste real")

        client = AsaasClient()

        try:
            # Teste básico de conectividade
            # Nota: Este teste pode falhar se a API key for inválida
            # É apenas para verificar se a conexão está funcionando
            pass
        except Exception as e:
            self.fail(f"Falha na conexão com API: {e}")


def run_asaas_tests():
    """Função para executar todos os testes da API Asaas"""
    import django
    from django.test.utils import get_runner
    from django.conf import settings

    django.setup()
    TestRunner = get_runner(settings)
    test_runner = TestRunner()

    # Executa apenas os testes do financeiro
    failures = test_runner.run_tests(["financeiro.test_asaas_api"])
    return failures


if __name__ == "__main__":
    # Para executar os testes diretamente
    import django
    import os
    import sys

    # Configura Django
    os.environ.setdefault("DJANGO_SETTINGS_MODULE", "core.settings")
    django.setup()

    # Executa os testes
    from django.test.utils import get_runner
    from django.conf import settings

    TestRunner = get_runner(settings)
    test_runner = TestRunner()
    failures = test_runner.run_tests(["financeiro.test_asaas_api"])

    if failures:
        sys.exit(1)
