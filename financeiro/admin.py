from django.contrib import admin
from .models import AsaasPayment


@admin.register(AsaasPayment)
class AsaasPaymentAdmin(admin.ModelAdmin):
    list_display = [
        "asaas_id",
        "customer_id",
        "amount",
        "billing_type",
        "status",
        "created_at",
        "paid_at",
    ]
    list_filter = ["status", "billing_type", "created_at", "paid_at"]
    search_fields = ["asaas_id", "customer_id", "webhook_event_id"]
    readonly_fields = [
        "asaas_id",
        "customer_id",
        "amount",
        "billing_type",
        "status",
        "qr_code_base64",
        "copy_paste_payload",
        "invoice_url",
        "created_at",
        "updated_at",
        "paid_at",
        "webhook_event_id",
    ]
    ordering = ["-created_at"]
    date_hierarchy = "created_at"

    fieldsets = (
        ("Identificação", {"fields": ("asaas_id", "customer_id", "webhook_event_id")}),
        ("Pagamento", {"fields": ("amount", "billing_type", "status")}),
        (
            "Dados de Pagamento",
            {
                "fields": ("qr_code_base64", "copy_paste_payload", "invoice_url"),
                "classes": ("collapse",),
            },
        ),
        ("Datas", {"fields": ("created_at", "updated_at", "paid_at")}),
    )

    def has_add_permission(self, request):
        # Não permitir adicionar manualmente - apenas via API
        return False

    def has_change_permission(self, request, obj=None):
        # Não permitir editar - apenas visualizar
        return False

    def has_delete_permission(self, request, obj=None):
        # Não permitir deletar - dados críticos de pagamento
        return False
