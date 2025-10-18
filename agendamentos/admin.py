from django.contrib import admin
from .models import Cliente, TipoServico, Agendamento, StatusAgendamento


@admin.register(Cliente)
class ClienteAdmin(admin.ModelAdmin):
    list_display = ["nome", "email", "telefone", "cpf", "idade", "ativo", "criado_em"]
    list_filter = ["ativo", "criado_em", "data_nascimento"]
    search_fields = ["nome", "email", "telefone", "cpf"]
    readonly_fields = ["criado_em", "atualizado_em", "idade"]
    list_editable = ["ativo"]
    ordering = ["nome"]

    fieldsets = (
        (
            "Informações Pessoais",
            {
                "fields": (
                    "nome",
                    "email",
                    "telefone",
                    "cpf",
                    "data_nascimento",
                    "idade",
                )
            },
        ),
        (
            "Endereço e Observações",
            {"fields": ("endereco", "observacoes"), "classes": ("collapse",)},
        ),
        (
            "Status e Controle",
            {"fields": ("ativo", "criado_por", "criado_em", "atualizado_em")},
        ),
    )


@admin.register(TipoServico)
class TipoServicoAdmin(admin.ModelAdmin):
    list_display = ["nome", "preco", "duracao_formatada", "ativo", "criado_em"]
    list_filter = ["ativo", "criado_em"]
    search_fields = ["nome", "descricao"]
    readonly_fields = ["criado_em", "duracao_formatada"]
    list_editable = ["ativo", "preco"]
    ordering = ["nome"]

    fieldsets = (
        (
            "Informações do Serviço",
            {"fields": ("nome", "descricao", "duracao", "duracao_formatada")},
        ),
        ("Preços e Status", {"fields": ("preco", "ativo")}),
        ("Controle", {"fields": ("criado_por", "criado_em")}),
    )


@admin.register(Agendamento)
class AgendamentoAdmin(admin.ModelAdmin):
    list_display = [
        "cliente",
        "servico",
        "data_agendamento",
        "hora_inicio",
        "hora_fim",
        "status",
        "valor_cobrado",
        "criado_em",
    ]
    list_filter = ["status", "data_agendamento", "criado_em", "servico"]
    search_fields = ["cliente__nome", "cliente__email", "servico__nome", "observacoes"]
    readonly_fields = ["criado_em", "atualizado_em", "duracao_total"]
    list_editable = ["status", "valor_cobrado"]
    ordering = ["-data_agendamento", "-hora_inicio"]
    date_hierarchy = "data_agendamento"

    fieldsets = (
        (
            "Informações do Agendamento",
            {
                "fields": (
                    "cliente",
                    "servico",
                    "data_agendamento",
                    "hora_inicio",
                    "hora_fim",
                    "duracao_total",
                )
            },
        ),
        ("Status e Valores", {"fields": ("status", "valor_cobrado")}),
        ("Observações", {"fields": ("observacoes",), "classes": ("collapse",)}),
        ("Controle", {"fields": ("criado_por", "criado_em", "atualizado_em")}),
    )

    def get_queryset(self, request):
        return (
            super()
            .get_queryset(request)
            .select_related("cliente", "servico", "criado_por")
        )
