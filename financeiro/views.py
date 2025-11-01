# Views para criar cobrança PIX, mostrar QR e webhook receiver.

import logging
import json
from django.shortcuts import render, get_object_or_404
from django.views.decorators.csrf import csrf_exempt
from django.http import JsonResponse, HttpResponse, HttpResponseForbidden
from django.conf import settings
from django.views.decorators.http import require_http_methods
from django.utils.decorators import method_decorator
from django_ratelimit.decorators import ratelimit
from django_ratelimit.exceptions import Ratelimited
from .models import AsaasPayment
from .services.asaas import AsaasClient, AsaasAPIError
from .validators import SecurityValidator

logger = logging.getLogger(__name__)


# Cliente será inicializado quando necessário
def get_asaas_client():
    """Retorna cliente Asaas, inicializando apenas quando necessário"""
    try:
        return AsaasClient()
    except RuntimeError as e:
        # Se não houver API key configurada, retorna None
        logger.warning(f"Erro ao inicializar cliente Asaas: {e}")
        return None


@csrf_exempt
@require_http_methods(["POST"])
@ratelimit(key='ip', rate='10/m', method='POST', block=True)
@ratelimit(key='ip', rate='100/h', method='POST', block=True)
def create_pix_charge(request):
    """
    Endpoint para criar cobrança PIX e retornar dados para frontend.
    
    Recebe POST com:
    {
        "customer_id": "cus_xxxxx",
        "value": 100.00,
        "due_date": "2024-12-31",
        "description": "Descrição do pagamento"
    }
    """
    # Tratar rate limiting
    if getattr(request, 'limited', False):
        logger.warning(f"Rate limit excedido para IP: {request.META.get('REMOTE_ADDR', 'unknown')}")
        return JsonResponse(
            {"error": "Muitas requisições. Tente novamente mais tarde."},
            status=429
        )

    # Validar tamanho da requisição
    body = request.body
    is_valid_size, size_error = SecurityValidator.validate_request_size(body)
    if not is_valid_size:
        return JsonResponse({"error": size_error}, status=413)

    client = get_asaas_client()
    if not client:
        return JsonResponse(
            {"error": "API Asaas não configurada. Configure ASAAS_API_KEY no .env"},
            status=500
        )

    try:
        data = json.loads(request.body)
        customer_id = data.get("customer_id")
        value = data.get("value")
        due_date = data.get("due_date")  # 'YYYY-MM-DD'
        description = data.get("description")

        # Validação de segurança - customer_id
        is_valid_customer, customer_error = SecurityValidator.validate_customer_id(customer_id)
        if not is_valid_customer:
            logger.warning(f"Tentativa de criação de pagamento com customer_id inválido: {customer_id}")
            return JsonResponse({"error": customer_error}, status=400)

        # Validação de segurança - value
        is_valid_amount, amount_error, decimal_value = SecurityValidator.validate_amount(value)
        if not is_valid_amount:
            logger.warning(f"Tentativa de criação de pagamento com value inválido: {value}")
            return JsonResponse({"error": amount_error}, status=400)

        # Validação de segurança - due_date
        is_valid_date, date_error = SecurityValidator.validate_due_date(due_date)
        if not is_valid_date:
            logger.warning(f"Tentativa de criação de pagamento com due_date inválido: {due_date}")
            return JsonResponse({"error": date_error}, status=400)

        # Validação e sanitização de descrição
        is_valid_desc, desc_error, sanitized_description = SecurityValidator.validate_description(description)
        if not is_valid_desc:
            return JsonResponse({"error": desc_error}, status=400)
        description = sanitized_description

        # Criar cobrança (usar valor validado)
        res = client.create_payment(
            customer_id=str(customer_id).strip(),
            value=float(decimal_value),
            due_date=due_date,
            billing_type="PIX",
            description=description,
        )
        payment_id = res["id"]

        # Salvar no banco local
        payment = AsaasPayment.objects.create(
            asaas_id=payment_id,
            customer_id=str(customer_id).strip(),
            amount=decimal_value,
            billing_type="PIX",
            status=res.get("status", "PENDING"),
        )

        # Obter QR Code
        qr = client.get_pix_qr(payment_id)
        # qr contém campos como 'qrCode' (base64), 'payload', 'expiresAt'
        payment.qr_code_base64 = qr.get("qrCode")
        payment.copy_paste_payload = qr.get("payload")
        payment.save()

        return JsonResponse(
            {
                "payment_id": payment.asaas_id,
                "qrBase64": payment.qr_code_base64,
                "payload": payment.copy_paste_payload,
                "status": payment.status,
            }
        )

    except AsaasAPIError as e:
        logger.error(f"Erro na API Asaas ao criar pagamento: {e.message}")
        return JsonResponse(
            {
                "error": f"Erro na API Asaas: {e.message}",
                "status_code": e.status_code,
            },
            status=e.status_code or 500,
        )
    except json.JSONDecodeError:
        return JsonResponse({"error": "JSON inválido"}, status=400)
    except ValueError as e:
        return JsonResponse({"error": f"Valor inválido: {str(e)}"}, status=400)
    except Exception as e:
        logger.error(f"Erro inesperado ao criar pagamento PIX: {e}", exc_info=True)
        return JsonResponse(
            {"error": "Erro interno do servidor"}, status=500
        )


def pix_qr_view(request, payment_id):
    """Mostra uma página simples com o QR Code (Bootstrap mínimo)."""
    # Validar payment_id antes de usar na query
    is_valid, error = SecurityValidator.validate_payment_id(payment_id)
    if not is_valid:
        logger.warning(f"Tentativa de acesso com payment_id inválido: {payment_id}")
        return render(request, "financeiro/pix_qr.html", {"error": "Pagamento não encontrado"}, status=404)
    
    payment = get_object_or_404(AsaasPayment, asaas_id=payment_id)
    return render(request, "financeiro/pix_qr.html", {"payment": payment})


@csrf_exempt
@require_http_methods(["POST"])
@ratelimit(key='ip', rate='100/m', method='POST', block=True)
def asaas_webhook(request):
    """Recebe eventos do Asaas. Validar header 'asaas-access-token'."""
    # Tratar rate limiting
    if getattr(request, 'limited', False):
        logger.warning(f"Rate limit excedido no webhook para IP: {request.META.get('REMOTE_ADDR', 'unknown')}")
        return HttpResponse(status=429)
    
    # Validar tamanho da requisição
    body = request.body
    is_valid_size, size_error = SecurityValidator.validate_request_size(body)
    if not is_valid_size:
        logger.warning(f"Webhook rejeitado: requisição muito grande")
        return HttpResponse(status=413)

    # Validar token
    token_header = request.headers.get("asaas-access-token") or request.META.get(
        "HTTP_ASAAS_ACCESS_TOKEN"
    )
    expected = getattr(settings, "ASAAS_WEBHOOK_TOKEN", None)
    
    # Se token é obrigatório e não foi fornecido ou é inválido, rejeitar
    if expected:
        if not token_header:
            logger.warning("Webhook rejeitado: token não fornecido")
            return HttpResponseForbidden("invalid token")
        
        # Comparação segura de tokens (timing-safe)
        if len(token_header) != len(expected):
            logger.warning("Webhook rejeitado: token com tamanho incorreto")
            return HttpResponseForbidden("invalid token")
        
        # Comparação byte a byte para prevenir timing attacks
        result = 0
        for x, y in zip(token_header.encode(), expected.encode()):
            result |= x ^ y
        
        if result != 0:
            logger.warning("Webhook rejeitado: token inválido")
            return HttpResponseForbidden("invalid token")

    # Parse payload com validação
    try:
        payload = json.loads(request.body)
        
        # Validar estrutura básica do payload
        if not isinstance(payload, dict):
            logger.warning("Webhook rejeitado: payload não é um objeto JSON")
            return HttpResponse(status=400)
        
        # Limitar tamanho de campos críticos
        if 'id' in payload and len(str(payload['id'])) > 200:
            logger.warning("Webhook rejeitado: event ID muito longo")
            return HttpResponse(status=400)
            
    except json.JSONDecodeError as e:
        logger.warning(f"Webhook rejeitado: JSON inválido - {e}")
        return HttpResponse(status=400)
    except Exception as e:
        logger.error(f"Webhook rejeitado: erro ao processar payload - {e}")
        return HttpResponse(status=400)

    # idempotência: ver se evento já processado
    event_id = payload.get("id")
    event_type = payload.get("event")
    obj = payload.get("payment") or payload.get("checkout") or payload.get("object")

    # Processar diferentes tipos de eventos
    if event_type == "PAYMENT_RECEIVED" and obj:
        payment_id = obj.get("id")
        try:
            p = AsaasPayment.objects.get(asaas_id=payment_id)
            p.status = obj.get("status", p.status)
            # Parse data de pagamento
            payment_date = obj.get("paymentDate") or obj.get("dateCreated")
            if payment_date:
                from django.utils.dateparse import parse_datetime
                parsed_date = parse_datetime(payment_date)
                if parsed_date:
                    p.paid_at = parsed_date
            p.webhook_event_id = event_id
            p.save()
            logger.info(f"Pagamento atualizado via webhook: {payment_id} - Status: {p.status}")
            # Aqui você pode adicionar lógica para liberar assinatura/recursos no seu sistema
        except AsaasPayment.DoesNotExist:
            # Opcional: buscar via API e criar registro
            try:
                client = get_asaas_client()
                if client:
                    fetched = client.get_payment(payment_id)
                    AsaasPayment.objects.create(
                        asaas_id=fetched["id"],
                        customer_id=fetched.get("customer"),
                        amount=fetched.get("value"),
                        billing_type=fetched.get("billingType"),
                        status=fetched.get("status"),
                        webhook_event_id=event_id,
                    )
                    logger.info(f"Pagamento criado via webhook: {payment_id}")
            except Exception as e:
                logger.error(f"Erro ao buscar pagamento do Asaas: {e}", exc_info=True)

    elif event_type == "PAYMENT_OVERDUE" and obj:
        payment_id = obj.get("id")
        try:
            p = AsaasPayment.objects.get(asaas_id=payment_id)
            p.status = "OVERDUE"
            p.webhook_event_id = event_id
            p.save()
            logger.info(f"Pagamento marcado como vencido: {payment_id}")
        except AsaasPayment.DoesNotExist:
            logger.warning(f"Pagamento não encontrado para evento OVERDUE: {payment_id}")

    elif event_type == "PAYMENT_DELETED" and obj:
        payment_id = obj.get("id")
        try:
            p = AsaasPayment.objects.get(asaas_id=payment_id)
            p.status = "DELETED"
            p.webhook_event_id = event_id
            p.save()
            logger.info(f"Pagamento marcado como deletado: {payment_id}")
        except AsaasPayment.DoesNotExist:
            logger.warning(f"Pagamento não encontrado para evento DELETED: {payment_id}")

    # Responder 200 rapidamente (webhook deve responder rápido)
    return HttpResponse(status=200)
