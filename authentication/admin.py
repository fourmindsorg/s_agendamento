from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from django.contrib.auth.models import User
from .models import PreferenciasUsuario, Plano, AssinaturaUsuario


# Inline para PreferenciasUsuario
class PreferenciasUsuarioInline(admin.StackedInline):
    model = PreferenciasUsuario
    can_delete = False
    verbose_name_plural = "Preferências"


# Estender o UserAdmin para incluir as preferências
class CustomUserAdmin(UserAdmin):
    inlines = (PreferenciasUsuarioInline,)
    list_display = (
        "username",
        "email",
        "first_name",
        "last_name",
        "is_staff",
        "date_joined",
    )
    list_filter = ("is_staff", "is_superuser", "is_active", "date_joined")


# Re-registrar UserAdmin
admin.site.unregister(User)
admin.site.register(User, CustomUserAdmin)


@admin.register(PreferenciasUsuario)
class PreferenciasUsuarioAdmin(admin.ModelAdmin):
    list_display = ["usuario", "tema", "modo", "criado_em", "atualizado_em"]
    list_filter = ["tema", "modo", "criado_em"]
    search_fields = [
        "usuario__username",
        "usuario__email",
        "usuario__first_name",
        "usuario__last_name",
    ]
    readonly_fields = ["criado_em", "atualizado_em"]
    ordering = ["usuario__username"]

    fieldsets = (
        ("Usuário", {"fields": ("usuario",)}),
        ("Preferências de Visualização", {"fields": ("tema", "modo")}),
        ("Controle", {"fields": ("criado_em", "atualizado_em")}),
    )


@admin.register(Plano)
class PlanoAdmin(admin.ModelAdmin):
    list_display = [
        "nome",
        "tipo",
        "preco_cartao",
        "preco_pix",
        "economia_pix",
        "duracao_dias",
        "ativo",
        "destaque",
        "ordem",
    ]
    list_filter = ["tipo", "ativo", "destaque", "criado_em"]
    search_fields = ["nome", "descricao"]
    readonly_fields = ["criado_em", "atualizado_em", "economia_pix"]
    list_editable = ["ativo", "destaque", "ordem", "preco_cartao", "preco_pix"]
    ordering = ["ordem", "nome"]

    fieldsets = (
        ("Informações do Plano", {"fields": ("nome", "tipo", "descricao")}),
        ("Preços", {"fields": ("preco_cartao", "preco_pix", "economia_pix")}),
        ("Configurações", {"fields": ("duracao_dias", "ativo", "destaque", "ordem")}),
        ("Controle", {"fields": ("criado_em", "atualizado_em")}),
    )


@admin.register(AssinaturaUsuario)
class AssinaturaUsuarioAdmin(admin.ModelAdmin):
    list_display = [
        "usuario",
        "plano",
        "status",
        "data_inicio",
        "data_fim",
        "dias_restantes",
        "valor_pago",
        "metodo_pagamento",
        "criado_em",
    ]
    list_filter = ["status", "metodo_pagamento", "plano", "data_inicio", "criado_em"]
    search_fields = [
        "usuario__username",
        "usuario__email",
        "plano__nome",
        "asaas_payment_id",
    ]
    readonly_fields = [
        "data_inicio",
        "criado_em",
        "atualizado_em",
        "dias_restantes",
        "ativa",
    ]
    list_editable = ["status"]
    ordering = ["-data_inicio"]
    date_hierarchy = "data_inicio"

    fieldsets = (
        ("Usuário e Plano", {"fields": ("usuario", "plano")}),
        (
            "Status e Datas",
            {
                "fields": (
                    "status",
                    "data_fim",
                    "dias_restantes",
                    "ativa",
                )
            },
        ),
        (
            "Pagamento",
            {"fields": ("valor_pago", "metodo_pagamento", "asaas_payment_id")},
        ),
        ("Controle", {"fields": ("data_inicio", "criado_em", "atualizado_em")}),
    )

    def get_queryset(self, request):
        return super().get_queryset(request).select_related("usuario", "plano")

    def save_model(self, request, obj, form, change):
        """Calcula automaticamente a data_fim baseada no plano selecionado"""
        if obj.plano and not obj.data_fim:
            from django.utils import timezone
            from datetime import timedelta

            obj.data_fim = timezone.now() + timedelta(days=obj.plano.duracao_dias)

        super().save_model(request, obj, form, change)

    def get_form(self, request, obj=None, **kwargs):
        """Personaliza o formulário para melhor UX"""
        form = super().get_form(request, obj, **kwargs)

        # Adicionar help_text para data_fim
        if "data_fim" in form.base_fields:
            form.base_fields["data_fim"].help_text = (
                "Deixe em branco para calcular automaticamente baseado no plano selecionado"
            )

        return form

    class Media:
        js = ("admin/js/assinatura_admin.js",)
