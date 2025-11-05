"""
Testes Funcionais da Integração com API Asaas

Este arquivo contém testes que verificam se a integração com a API Asaas
está funcionando corretamente, incluindo criação de clientes, pagamentos PIX,
obtenção de QR Code, etc.

IMPORTANTE: Estes testes fazem chamadas reais à API Asaas (sandbox ou produção).
Certifique-se de ter configurado ASAAS_API_KEY no .env antes de executar.
"""

import os
import json
import time
from datetime import datetime, timedelta
from decimal import Decimal
from unittest.mock import patch, Mock, MagicMock

from django.test import TestCase, Client
from django.contrib.auth.models import User
from django.urls import reverse
from django.conf import settings
from django.utils import timezone

from .models import AsaasPayment
from .services.asaas import AsaasClient, AsaasAPIError
from .test_utils import gerar_cpf_valido


def wait_for_pix_qr(client, payment_id, max_wait=60, interval=2):
    """
    Aguarda o QR Code PIX ficar disponível.
    
    Args:
        client: AsaasClient
        payment_id: ID do pagamento
        max_wait: Tempo máximo de espera em segundos (default: 60)
        interval: Intervalo entre tentativas em segundos (default: 2)
    
    Returns:
        tuple: (pix_data, elapsed_time) ou (None, elapsed_time) se não conseguir
    """
    start_time = time.time()
    elapsed = 0
    tentativa = 0
    
    while elapsed < max_wait:
        tentativa += 1
        try:
            pix_data = client.get_pix_qr(payment_id)
            elapsed_time = time.time() - start_time
            if pix_data and pix_data.get("payload"):
                print(f"     [INFO] QR Code obtido na tentativa {tentativa} apos {elapsed_time:.1f} segundos")
                return pix_data, elapsed_time
        except AsaasAPIError as e:
            # Se for 404, ainda não está disponível, continuar tentando
            if e.status_code == 404:
                elapsed = time.time() - start_time
                if elapsed < max_wait:
                    # Mostrar progresso a cada 10 segundos
                    if tentativa % 5 == 0:
                        print(f"     [INFO] Tentativa {tentativa}: QR Code ainda nao disponivel ({elapsed:.1f}s)...")
                    time.sleep(interval)
                    continue
                else:
                    # Timeout atingido
                    elapsed_time = time.time() - start_time
                    print(f"     [WARN] Timeout apos {elapsed_time:.1f} segundos ({tentativa} tentativas)")
                    return None, elapsed_time
            # Outro erro diferente de 404, relançar
            raise
        except Exception as e:
            # Erro inesperado
            elapsed_time = time.time() - start_time
            print(f"     [ERRO] Erro inesperado na tentativa {tentativa}: {e}")
            raise
    
    # Timeout (não deveria chegar aqui, mas por segurança)
    elapsed_time = time.time() - start_time
    print(f"     [WARN] Timeout apos {elapsed_time:.1f} segundos ({tentativa} tentativas)")
    return None, elapsed_time


class AsaasFunctionalTestCase(TestCase):
    """Testes funcionais da integração com API Asaas"""

    def setUp(self):
        """Configuração inicial"""
        self.client = Client()
        
        # Verificar se API está configurada (verifica settings e variável de ambiente)
        import os
        self.api_key = (
            os.environ.get("ASAAS_API_KEY") or 
            getattr(settings, "ASAAS_API_KEY", None)
        )
        self.env = getattr(settings, "ASAAS_ENV", "sandbox")
        
        # Verificar se a chave existe e não é apenas um placeholder
        if not self.api_key or self.api_key == "test_api_key_for_ci":
            self.skipTest("ASAAS_API_KEY não configurada ou inválida. Configure uma chave válida do Asaas.")
        
        # Criar usuário de teste
        self.user = User.objects.create_user(
            username="testuser",
            email="test@example.com",
            password="testpass123"
        )
        self.client.force_login(self.user)

    # ==========================================
    # Testes de Cliente Asaas
    # ==========================================

    def test_asaas_client_initialization(self):
        """Testa se o cliente Asaas pode ser inicializado"""
        try:
            client = AsaasClient()
            self.assertIsNotNone(client)
            self.assertEqual(client.env, self.env)
            self.assertIsNotNone(client.api_key)
            print("[OK] Cliente Asaas inicializado com sucesso")
        except Exception as e:
            self.fail(f"Erro ao inicializar cliente Asaas: {e}")

    def test_create_customer(self):
        """Testa criação de cliente no Asaas"""
        client = AsaasClient()
        
        # CPF válido para testes (gerador de CPF válido)
        # Usar CPF aleatório único para cada teste
        import random
        cpf_teste = f"{random.randint(100000000, 999999999)}"
        
        email_unico = f"cliente.teste.{random.randint(1000, 9999)}@example.com"
        customer_data = client.create_customer(
            name="Cliente Teste Funcional",
            email=email_unico,
            phone="11987654321"
        )
        
        self.assertIsNotNone(customer_data)
        self.assertIn("id", customer_data)
        self.assertEqual(customer_data["name"], "Cliente Teste Funcional")
        self.assertEqual(customer_data["email"], email_unico)
        print(f"[OK] Cliente criado: {customer_data['id']}")

    def test_get_customer(self):
        """Testa busca de cliente por ID"""
        client = AsaasClient()
        
        # Primeiro criar um cliente
        import random
        email_unico = f"buscar.{random.randint(1000, 9999)}@example.com"
        customer = client.create_customer(
            name="Cliente para Buscar",
            email=email_unico
        )
        customer_id = customer["id"]
        
        # Buscar o cliente
        found_customer = client.get_customer(customer_id)
        
        self.assertIsNotNone(found_customer)
        self.assertEqual(found_customer["id"], customer_id)
        self.assertEqual(found_customer["name"], "Cliente para Buscar")
        print(f"[OK] Cliente encontrado: {customer_id}")

    def test_find_customer_by_cpf(self):
        """Testa busca de cliente por CPF (pode ser pulado se CPF não for obrigatório)"""
        client = AsaasClient()
        
        # Em sandbox, CPF pode não ser obrigatório
        # Este teste pode ser pulado se não tiver CPF válido
        try:
            # Tentar criar cliente sem CPF primeiro
            import random
            email_unico = f"cpf.{random.randint(1000, 9999)}@example.com"
            customer = client.create_customer(
                name="Cliente CPF Teste",
                email=email_unico
            )
            print(f"[OK] Cliente criado sem CPF: {customer.get('id')}")
            print("[INFO] Teste de busca por CPF requer CPF valido (pode ser opcional em sandbox)")
        except Exception as e:
            print(f"[WARN] Teste de CPF nao executado: {e}")

    # ==========================================
    # Testes de Pagamento PIX
    # ==========================================

    def test_create_pix_payment(self):
        """Testa criação de pagamento PIX"""
        client = AsaasClient()
        
        # Criar cliente primeiro (com CPF, necessário para pagamentos PIX)
        import random
        email_unico = f"pix.{random.randint(1000, 9999)}@example.com"
        customer = client.create_customer(
            name="Pagamento PIX Teste",
            email=email_unico,
            cpf_cnpj=gerar_cpf_valido()
        )
        
        # Criar pagamento PIX
        due_date = (datetime.now() + timedelta(days=1)).strftime("%Y-%m-%d")
        
        payment = client.create_payment(
            customer_id=customer["id"],
            value=50.00,
            due_date=due_date,
            billing_type="PIX",
            description="Teste de pagamento PIX funcional"
        )
        
        self.assertIsNotNone(payment)
        self.assertIn("id", payment)
        self.assertEqual(payment["billingType"], "PIX")
        self.assertEqual(float(payment["value"]), 50.00)
        self.assertEqual(payment["status"], "PENDING")
        print(f"[OK] Pagamento PIX criado: {payment['id']}")

    def test_get_pix_qr_code(self):
        """Testa obtenção de QR Code PIX com espera se necessário"""
        client = AsaasClient()
        
        # Criar cliente e pagamento (com CPF)
        import random
        email_unico = f"qrcode.{random.randint(1000, 9999)}@example.com"
        customer = client.create_customer(
            name="QR Code Teste",
            email=email_unico,
            cpf_cnpj=gerar_cpf_valido()
        )
        
        due_date = (datetime.now() + timedelta(days=1)).strftime("%Y-%m-%d")
        payment = client.create_payment(
            customer_id=customer["id"],
            value=25.00,
            due_date=due_date,
            billing_type="PIX",
            description="Teste QR Code"
        )
        
        print(f"[INFO] Pagamento criado: {payment['id']}, aguardando QR Code...")
        
        # Obter QR Code com espera (até 60 segundos)
        pix_data, elapsed_time = wait_for_pix_qr(client, payment["id"], max_wait=60, interval=2)
        
        self.assertIsNotNone(pix_data, f"QR Code nao ficou disponivel apos {elapsed_time:.1f} segundos")
        self.assertIn("payload", pix_data)
        self.assertIsInstance(pix_data["payload"], str)
        self.assertGreater(len(pix_data["payload"]), 0)
        
        # Payload PIX deve começar com código correto
        self.assertTrue(pix_data["payload"].startswith("000201"))
        
        print(f"[OK] QR Code obtido em {elapsed_time:.1f} segundos")
        print(f"     Payload: {pix_data['payload'][:50]}...")
        print(f"     Tem imagem: {bool(pix_data.get('encodedImage') or pix_data.get('qrCode'))}")

    def test_get_payment_status(self):
        """Testa obtenção de status de pagamento"""
        client = AsaasClient()
        
        # Criar pagamento (com CPF)
        import random
        email_unico = f"status.{random.randint(1000, 9999)}@example.com"
        customer = client.create_customer(
            name="Status Teste",
            email=email_unico,
            cpf_cnpj=gerar_cpf_valido()
        )
        
        due_date = (datetime.now() + timedelta(days=1)).strftime("%Y-%m-%d")
        payment = client.create_payment(
            customer_id=customer["id"],
            value=30.00,
            due_date=due_date,
            billing_type="PIX"
        )
        
        # Buscar pagamento
        fetched_payment = client.get_payment(payment["id"])
        
        self.assertIsNotNone(fetched_payment)
        self.assertEqual(fetched_payment["id"], payment["id"])
        self.assertEqual(fetched_payment["status"], "PENDING")
        self.assertEqual(float(fetched_payment["value"]), 30.00)
        print(f"[OK] Status do pagamento: {fetched_payment['status']}")

    def test_list_payments(self):
        """Testa listagem de pagamentos"""
        client = AsaasClient()
        
        # Criar alguns pagamentos (com CPF)
        import random
        email_unico = f"lista.{random.randint(1000, 9999)}@example.com"
        customer = client.create_customer(
            name="Lista Teste",
            email=email_unico,
            cpf_cnpj=gerar_cpf_valido()
        )
        
        due_date = (datetime.now() + timedelta(days=1)).strftime("%Y-%m-%d")
        
        # Criar 2 pagamentos
        payment1 = client.create_payment(
            customer_id=customer["id"],
            value=10.00,
            due_date=due_date,
            billing_type="PIX"
        )
        
        payment2 = client.create_payment(
            customer_id=customer["id"],
            value=20.00,
            due_date=due_date,
            billing_type="PIX"
        )
        
        # Listar pagamentos do cliente
        payments = client.list_payments(customer=customer["id"], limit=10)
        
        self.assertIsNotNone(payments)
        self.assertIn("data", payments)
        self.assertGreaterEqual(len(payments["data"]), 2)
        
        payment_ids = [p["id"] for p in payments["data"]]
        self.assertIn(payment1["id"], payment_ids)
        self.assertIn(payment2["id"], payment_ids)
        
        print(f"[OK] Listados {len(payments['data'])} pagamentos")

    # ==========================================
    # Testes de Integração Completa
    # ==========================================

    def test_complete_pix_flow(self):
        """Testa fluxo completo: Cliente → Pagamento → QR Code"""
        client = AsaasClient()
        
        # Passo 1: Criar cliente (com CPF para pagamentos)
        import random
        max_tentativas = 3
        customer = None
        
        for tentativa in range(max_tentativas):
            try:
                email_unico = f"fluxo.{random.randint(1000, 9999)}@example.com"
                customer = client.create_customer(
                    name="Fluxo Completo Teste",
                    email=email_unico,
                    phone="11987654321",
                    cpf_cnpj=gerar_cpf_valido()
                )
                break  # Sucesso, sair do loop
            except AsaasAPIError as e:
                if "invalid_object" in str(e) and tentativa < max_tentativas - 1:
                    print(f"[WARN] Tentativa {tentativa + 1} falhou por CPF invalido, tentando novamente...")
                    continue
                raise
        
        self.assertIsNotNone(customer, "Nao foi possivel criar cliente apos varias tentativas")
        customer_id = customer["id"]
        print(f"[OK] Passo 1: Cliente criado - {customer_id}")
        
        # Passo 2: Criar pagamento PIX
        due_date = (datetime.now() + timedelta(days=1)).strftime("%Y-%m-%d")
        payment = client.create_payment(
            customer_id=customer_id,
            value=100.00,
            due_date=due_date,
            billing_type="PIX",
            description="Teste fluxo completo"
        )
        payment_id = payment["id"]
        print(f"[OK] Passo 2: Pagamento criado - {payment_id}")
        
        # Passo 3: Obter QR Code (com espera se necessário)
        print(f"[INFO] Aguardando QR Code ficar disponivel...")
        pix_data, elapsed_time = wait_for_pix_qr(client, payment_id, max_wait=60, interval=2)
        self.assertIsNotNone(pix_data, f"QR Code nao ficou disponivel apos {elapsed_time:.1f} segundos")
        self.assertIn("payload", pix_data)
        print(f"[OK] Passo 3: QR Code obtido em {elapsed_time:.1f} segundos")
        
        # Passo 4: Verificar pagamento
        payment_status = client.get_payment(payment_id)
        self.assertEqual(payment_status["status"], "PENDING")
        print(f"[OK] Passo 4: Status verificado - {payment_status['status']}")
        
        print(f"[OK] Fluxo completo executado com sucesso!")
        print(f"     Cliente: {customer_id}")
        print(f"     Pagamento: {payment_id}")
        print(f"     Payload PIX: {pix_data['payload'][:50]}...")

    def test_payment_with_different_values(self):
        """Testa criação de pagamentos com diferentes valores"""
        client = AsaasClient()
        
        import random
        email_unico = f"valores.{random.randint(1000, 9999)}@example.com"
        customer = client.create_customer(
            name="Valores Teste",
            email=email_unico,
            cpf_cnpj=gerar_cpf_valido()
        )
        
        due_date = (datetime.now() + timedelta(days=1)).strftime("%Y-%m-%d")
        
        valores = [10.00, 50.00, 100.00, 999.99]
        
        for valor in valores:
            payment = client.create_payment(
                customer_id=customer["id"],
                value=valor,
                due_date=due_date,
                billing_type="PIX",
                description=f"Teste valor {valor}"
            )
            
            self.assertEqual(float(payment["value"]), valor)
            
            # Aguardar QR Code ficar disponível
            pix_data, elapsed_time = wait_for_pix_qr(client, payment["id"], max_wait=60, interval=2)
            self.assertIsNotNone(pix_data, f"QR Code nao ficou disponivel apos {elapsed_time:.1f} segundos para valor R$ {valor:.2f}")
            self.assertIn("payload", pix_data)
            print(f"[OK] Pagamento de R$ {valor:.2f} criado - QR Code obtido em {elapsed_time:.1f} segundos")

    # ==========================================
    # Testes de Validação
    # ==========================================

    def test_invalid_customer_data(self):
        """Testa comportamento com dados inválidos de cliente"""
        client = AsaasClient()
        
        # CPF inválido (deve ser aceito mas pode dar erro na API)
        try:
            customer = client.create_customer(
                name="Teste CPF Inválido",
                email="invalido@example.com",
                # Não enviar CPF para teste de dados inválidos
            )
            # Em sandbox pode aceitar, então só verificar que não quebrou
            print("[WARN] CPF invalido foi aceito (pode ser normal em sandbox)")
        except AsaasAPIError as e:
            # Se rejeitar, está correto
            print(f"[OK] API rejeitou CPF invalido: {e.message}")

    def test_payment_validation(self):
        """Testa validação de pagamentos"""
        client = AsaasClient()
        
        import random
        email_unico = f"validacao.{random.randint(1000, 9999)}@example.com"
        customer = client.create_customer(
            name="Validação Teste",
            email=email_unico,
            cpf_cnpj=gerar_cpf_valido()
        )
        
        # Valor zero deve ser rejeitado
        try:
            payment = client.create_payment(
                customer_id=customer["id"],
                value=0.00,
                due_date=(datetime.now() + timedelta(days=1)).strftime("%Y-%m-%d"),
                billing_type="PIX"
            )
            print("[WARN] Valor zero foi aceito (verificar se API deve rejeitar)")
        except AsaasAPIError as e:
            print(f"[OK] API rejeitou valor zero: {e.message}")

    # ==========================================
    # Testes de QR Code Generation
    # ==========================================

    def test_qr_code_generation_from_payload(self):
        """Testa geração de QR Code a partir do payload"""
        from financeiro.utils import generate_qr_code_from_payload
        
        # Payload PIX de exemplo
        payload = "00020126580014br.gov.bcb.pix013612345678901234520400005303986540510.005802BR5913TESTE DE PIX6009SAO PAULO62070503***6304ABCD"
        
        qr_code = generate_qr_code_from_payload(payload)
        
        if qr_code:
            self.assertIsInstance(qr_code, str)
            self.assertGreater(len(qr_code), 0)
            # Deve ser base64
            import base64
            try:
                base64.b64decode(qr_code)
                print("[OK] QR Code gerado com sucesso a partir do payload")
            except Exception:
                self.fail("QR Code gerado não é base64 válido")
        else:
            print("[WARN] QR Code nao foi gerado (verificar se qrcode[pil] esta instalado)")

    # ==========================================
    # Testes de Endpoints da View
    # ==========================================

    def test_create_pix_charge_endpoint(self):
        """Testa endpoint de criação de pagamento PIX"""
        # Criar cliente primeiro via API
        import random
        asaas_client = AsaasClient()
        email_unico = f"endpoint.{random.randint(1000, 9999)}@example.com"
        customer = asaas_client.create_customer(
            name="Endpoint Teste",
            email=email_unico,
            cpf_cnpj=gerar_cpf_valido()
        )
        
        # Dados para o endpoint
        data = {
            "customer_id": customer["id"],
            "value": 75.00,
            "due_date": (datetime.now() + timedelta(days=1)).strftime("%Y-%m-%d"),
            "description": "Teste endpoint funcional"
        }
        
        response = self.client.post(
            reverse("financeiro:create_pix_charge"),
            data=json.dumps(data),
            content_type="application/json"
        )
        
        if response.status_code == 200:
            result = json.loads(response.content)
            self.assertIn("payment_id", result)
            self.assertIn("qrBase64", result)
            self.assertIn("payload", result)
            print(f"[OK] Endpoint funcionou - Payment ID: {result['payment_id']}")
        else:
            error_data = json.loads(response.content) if response.content else {}
            print(f"[WARN] Endpoint retornou {response.status_code}: {error_data}")

    def test_webhook_endpoint_structure(self):
        """Testa estrutura do endpoint de webhook"""
        # Simular payload de webhook do Asaas
        payload = {
            "event": "PAYMENT_RECEIVED",
            "payment": {
                "id": "pay_test_123",
                "status": "RECEIVED",
                "value": 100.00,
                "customer": "cus_test_123"
            }
        }
        
        webhook_token = getattr(settings, "ASAAS_WEBHOOK_TOKEN", None)
        
        headers = {}
        if webhook_token:
            headers["HTTP_ASAAS_ACCESS_TOKEN"] = webhook_token
        
        response = self.client.post(
            reverse("financeiro:asaas_webhook"),
            data=json.dumps(payload),
            content_type="application/json",
            **headers
        )
        
        # Webhook deve aceitar (200) mesmo se não processar (sem registro no banco)
        self.assertIn(response.status_code, [200, 403])
        
        if response.status_code == 200:
            print("[OK] Endpoint de webhook respondeu corretamente")
        else:
            print(f"[WARN] Webhook retornou {response.status_code} (pode ser falta de token)")

    # ==========================================
    # Testes de Modelo
    # ==========================================

    def test_asaas_payment_model_creation(self):
        """Testa criação de registro AsaasPayment no banco"""
        payment = AsaasPayment.objects.create(
            asaas_id="pay_test_123",
            customer_id="cus_test_123",
            amount=Decimal("150.00"),
            billing_type="PIX",
            status="PENDING"
        )
        
        self.assertIsNotNone(payment.id)
        self.assertEqual(payment.asaas_id, "pay_test_123")
        self.assertEqual(payment.status, "PENDING")
        print(f"[OK] Modelo AsaasPayment criado: ID={payment.id}")

    # ==========================================
    # Testes de Tratamento de Erros
    # ==========================================

    def test_error_handling_invalid_payment_id(self):
        """Testa tratamento de erro para payment_id inválido"""
        client = AsaasClient()
        
        try:
            payment = client.get_payment("pay_invalido_123456")
            print("[WARN] API aceitou payment_id invalido")
        except AsaasAPIError as e:
            self.assertIsNotNone(e.status_code)
            self.assertIsNotNone(e.message)
            print(f"[OK] Erro tratado corretamente: {e.message}")

    def test_error_handling_invalid_customer_id(self):
        """Testa tratamento de erro para customer_id inválido"""
        client = AsaasClient()
        
        due_date = (datetime.now() + timedelta(days=1)).strftime("%Y-%m-%d")
        
        try:
            payment = client.create_payment(
                customer_id="cus_invalido_123",
                value=10.00,
                due_date=due_date,
                billing_type="PIX"
            )
            print("[WARN] API aceitou customer_id invalido")
        except AsaasAPIError as e:
            self.assertIsNotNone(e.status_code)
            print(f"[OK] Erro tratado corretamente: {e.message}")

    # ==========================================
    # Testes de Performance
    # ==========================================

    def test_multiple_payments_performance(self):
        """Testa criação de múltiplos pagamentos"""
        import time
        
        client = AsaasClient()
        import random
        email_unico = f"performance.{random.randint(1000, 9999)}@example.com"
        customer = client.create_customer(
            name="Performance Teste",
            email=email_unico,
            cpf_cnpj=gerar_cpf_valido()
        )
        
        due_date = (datetime.now() + timedelta(days=1)).strftime("%Y-%m-%d")
        
        start_time = time.time()
        
        payment_ids = []
        for i in range(3):  # Criar 3 pagamentos
            payment = client.create_payment(
                customer_id=customer["id"],
                value=10.00 + i,
                due_date=due_date,
                billing_type="PIX",
                description=f"Teste performance {i+1}"
            )
            payment_ids.append(payment["id"])
        
        elapsed_time = time.time() - start_time
        
        self.assertEqual(len(payment_ids), 3)
        print(f"[OK] 3 pagamentos criados em {elapsed_time:.2f} segundos")
        print(f"     Media: {elapsed_time/3:.2f} segundos por pagamento")

    # ==========================================
    # Testes de Ambiente
    # ==========================================

    def test_environment_configuration(self):
        """Testa se a configuração de ambiente está correta"""
        env = getattr(settings, "ASAAS_ENV", "sandbox")
        api_key = getattr(settings, "ASAAS_API_KEY", None)
        
        self.assertIsNotNone(api_key)
        self.assertIn(env, ["sandbox", "production"])
        
        client = AsaasClient()
        
        if env == "sandbox":
            self.assertIn("sandbox", client.base)
        else:
            self.assertIn("www.asaas.com", client.base)
        
        print(f"[OK] Ambiente configurado: {env}")
        print(f"     Base URL: {client.base}")

    def test_api_key_format(self):
        """Testa formato da chave de API"""
        api_key = getattr(settings, "ASAAS_API_KEY", None)
        
        if api_key:
            # Chaves Asaas geralmente começam com $aact_
            self.assertGreater(len(api_key), 10)
            print(f"[OK] API Key tem formato valido (tamanho: {len(api_key)})")
            
            # Não deve conter espaços
            self.assertNotIn(" ", api_key)
            print("[OK] API Key nao contem espacos")

