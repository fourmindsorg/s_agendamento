from django.db import models


class AsaasPayment(models.Model):
    """Modelo para rastrear cobranças criadas no Asaas."""

    asaas_id = models.CharField(max_length=64, unique=True)
    customer_id = models.CharField(max_length=64, null=True, blank=True)
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    billing_type = models.CharField(max_length=32)  # PIX, CREDIT_CARD, BOLETO
    status = models.CharField(max_length=32)
    qr_code_base64 = models.TextField(null=True, blank=True)
    copy_paste_payload = models.TextField(null=True, blank=True)
    invoice_url = models.TextField(null=True, blank=True)  # para cartão/boleto
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    paid_at = models.DateTimeField(null=True, blank=True)
    webhook_event_id = models.CharField(max_length=128, null=True, blank=True)

    def __str__(self):
        return f"AsaasPayment({self.asaas_id}) - {self.status} - {self.amount}"
