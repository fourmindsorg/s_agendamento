# Views para criar cobrança PIX, mostrar QR e webhook receiver.

import base64
import json
from django.shortcuts import render, redirect, get_object_or_404
from django.views.decorators.csrf import csrf_exempt
from django.http import JsonResponse, HttpResponse, HttpResponseForbidden
from django.conf import settings
from .models import AsaasPayment
from .services.asaas import AsaasClient

client = AsaasClient()

def create_pix_charge(request):
    """Endpoint para criar cobrança PIX e retornar dados para frontend."""
    if request.method == 'POST':
        data = json.loads(request.body)
        customer_id = data.get('customer_id')
        value = data.get('value')
        due_date = data.get('due_date')  # 'YYYY-MM-DD'
        description = data.get('description')
        # criar cobrança
        res = client.create_payment(customer_id=customer_id, value=value, due_date=due_date, billing_type='PIX', description=description)
        payment_id = res['id']
        # salvar no banco local
        payment = AsaasPayment.objects.create(
            asaas_id=payment_id,
            customer_id=customer_id,
            amount=value,
            billing_type='PIX',
            status=res.get('status', 'UNKNOWN')
        )
        # obter QR
        qr = client.get_pix_qr(payment_id)
        # qr contém campos como 'qrCode' (base64), 'payload', 'expiresAt'
        payment.qr_code_base64 = qr.get('qrCode')
        payment.copy_paste_payload = qr.get('payload')
        payment.save()
        return JsonResponse({'payment_id': payment.asaas_id, 'qrBase64': payment.qr_code_base64, 'payload': payment.copy_paste_payload})
    return HttpResponse(status=405)

def pix_qr_view(request, payment_id):
    """Mostra uma página simples com o QR Code (Bootstrap mínimo)."""
    payment = get_object_or_404(AsaasPayment, asaas_id=payment_id)
    return render(request, 'payments/pix_qr.html', {'payment': payment})

@csrf_exempt
def asaas_webhook(request):
    """Recebe eventos do Asaas. Validar header 'asaas-access-token'."""
    # validar método
    if request.method != 'POST':
        return HttpResponse(status=405)

    # validar token
    token_header = request.headers.get('asaas-access-token') or request.META.get('HTTP_ASAAS_ACCESS_TOKEN')
    expected = getattr(settings, 'ASAAS_WEBHOOK_TOKEN', None)
    if expected and token_header != expected:
        return HttpResponseForbidden('invalid token')

    # parse payload
    try:
        payload = json.loads(request.body)
    except Exception:
        return HttpResponse(status=400)

    # idempotência: ver se evento já processado
    event_id = payload.get('id')
    event_type = payload.get('event')
    obj = payload.get('payment') or payload.get('checkout') or payload.get('object')

    # exemplo para PAYMENT_RECEIVED
    if event_type == 'PAYMENT_RECEIVED' and obj:
        payment_id = obj.get('id')
        try:
            p = AsaasPayment.objects.get(asaas_id=payment_id)
            p.status = obj.get('status', p.status)
            # parse data de pagamento
            p.paid_at = obj.get('dateCreated') or p.paid_at
            p.webhook_event_id = event_id
            p.save()
            # aqui: liberar assinatura/recursos no seu sistema
        except AsaasPayment.DoesNotExist:
            # opcional: buscar via API e criar registro
            try:
                fetched = client.get_payment(payment_id)
                AsaasPayment.objects.create(
                    asaas_id=fetched['id'],
                    customer_id=fetched.get('customer'),
                    amount=fetched.get('value'),
                    billing_type=fetched.get('billingType'),
                    status=fetched.get('status')
                )
            except Exception:
                pass

    # responder 200 rapidamente
    return HttpResponse(status=200)
