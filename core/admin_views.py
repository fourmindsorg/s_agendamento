import json
import os
from collections import defaultdict

from django.conf import settings
from django.contrib import messages
from django.contrib.admin.views.decorators import staff_member_required
from django.contrib.auth import get_user_model
from django.contrib.auth.views import LoginView
from django.core.serializers.json import DjangoJSONEncoder
from django.db.models import Count
from django.shortcuts import redirect, render
from django.utils import timezone
from django.utils.decorators import method_decorator
from django.views.decorators.csrf import csrf_protect

from agendamentos.models import Agendamento, Cliente, TipoServico
from authentication.models import AssinaturaUsuario, PreferenciasUsuario


@method_decorator(csrf_protect, name="dispatch")
class CustomAdminLoginView(LoginView):
    """View personalizada para login do admin com template customizado"""

    template_name = "admin/login.html"

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context["site_title"] = "Admin Django"
        context["site_header"] = "Sistema de Agendamento - 4Minds"
        return context

    def form_valid(self, form):
        """Override para adicionar mensagens personalizadas"""
        response = super().form_valid(form)
        messages.success(self.request, "Login realizado com sucesso!")
        return response

    def form_invalid(self, form):
        """Override para mensagens de erro personalizadas"""
        messages.error(
            self.request, "Usuário ou senha incorretos. Tente novamente."
        )
        return super().form_invalid(form)


@staff_member_required
def custom_admin_dashboard(request):
    """Mantido por compatibilidade; redireciona ao novo painel."""
    return redirect("admin_user_activity")


@staff_member_required
def user_activity_dashboard(request):
    """Painel avançado para monitorar atividade e consumo de dados por usuário."""

    User = get_user_model()
    users = (
        User.objects.all()
        .select_related("activity_log")
        .order_by("-is_staff", "username")
    )

    # Pré-carregar entidades relacionadas aos usuários para evitar consultas extras
    clientes_por_usuario = defaultdict(list)
    for cliente in Cliente.objects.select_related("criado_por"):
        if cliente.criado_por_id:
            clientes_por_usuario[cliente.criado_por_id].append(cliente)

    servicos_por_usuario = defaultdict(list)
    for servico in TipoServico.objects.select_related("criado_por"):
        if servico.criado_por_id:
            servicos_por_usuario[servico.criado_por_id].append(servico)

    agendamentos_por_usuario = defaultdict(list)
    for agendamento in (
        Agendamento.objects.select_related("criado_por", "cliente", "servico")
        .only(
            "criado_por",
            "data_agendamento",
            "hora_inicio",
            "hora_fim",
            "status",
            "observacoes",
            "valor_cobrado",
        )
    ):
        if agendamento.criado_por_id:
            agendamentos_por_usuario[agendamento.criado_por_id].append(agendamento)

    preferencias_por_usuario = {
        pref.usuario_id: pref
        for pref in PreferenciasUsuario.objects.select_related("usuario").all()
    }

    assinaturas_por_usuario = defaultdict(list)
    for assinatura in AssinaturaUsuario.objects.select_related("usuario", "plano"):
        assinaturas_por_usuario[assinatura.usuario_id].append(assinatura)

    def _string_size(value):
        if value is None:
            return 0
        if hasattr(value, "isoformat"):
            value = value.isoformat()
        return len(str(value))

    def _estimate_collection_size(collection, fields):
        total = 0
        for item in collection:
            total += sum(_string_size(getattr(item, field, None)) for field in fields)
        return total

    def estimate_user_data_volume(user):
        """Retorna tamanho estimado (bytes) dos dados do usuário no banco."""
        size = 0

        # Dados básicos do próprio usuário
        size += sum(
            _string_size(getattr(user, field))
            for field in ["username", "email", "first_name", "last_name"]
        )

        # Clientes, serviços e agendamentos criados pelo usuário
        size += _estimate_collection_size(
            clientes_por_usuario.get(user.id, []),
            [
                "nome",
                "email",
                "telefone",
                "cpf",
                "endereco",
                "observacoes",
                "ativo",
            ],
        )

        size += _estimate_collection_size(
            servicos_por_usuario.get(user.id, []),
            ["nome", "descricao", "duracao", "preco", "ativo"],
        )

        size += _estimate_collection_size(
            agendamentos_por_usuario.get(user.id, []),
            [
                "data_agendamento",
                "hora_inicio",
                "hora_fim",
                "status",
                "observacoes",
                "valor_cobrado",
            ],
        )

        # Preferências e assinaturas
        preferencias = preferencias_por_usuario.get(user.id)
        if preferencias:
            size += _estimate_collection_size([preferencias], ["tema", "modo"])

        size += _estimate_collection_size(
            assinaturas_por_usuario.get(user.id, []),
            [
                "status",
                "metodo_pagamento",
                "asaas_payment_id",
                "data_inicio",
                "data_fim",
            ],
        )

        # Log de atividade (guardado como meta-informação)
        activity = getattr(user, "activity_log", None)
        if activity:
            size += _estimate_collection_size(
                [activity],
                [
                    "total_requests",
                    "total_get_requests",
                    "total_post_requests",
                    "total_put_requests",
                    "total_delete_requests",
                    "total_login_success",
                    "total_login_failed",
                    "last_activity",
                    "last_request_path",
                    "last_user_agent",
                    "last_login_ip",
                ],
            )

        return size

    hoje = timezone.now().date()
    agendamentos_abertos = Agendamento.objects.filter(
        data_agendamento__gte=hoje
    ).values("criado_por").annotate(total=Count("id"))
    agendamentos_abertos_por_usuario = {
        row["criado_por"]: row["total"] for row in agendamentos_abertos
    }

    agendamentos_por_status = list(
        Agendamento.objects.values("status").annotate(total=Count("id"))
    )

    method_distribution = {
        "GET": 0,
        "POST": 0,
        "PUT": 0,
        "DELETE": 0,
    }
    login_distribution = {"success": 0, "failed": 0}

    user_rows = []
    total_estimated_volume = 0
    total_requests_geral = 0

    for user in users:
        activity = getattr(user, "activity_log", None)
        total_clientes = len(clientes_por_usuario.get(user.id, []))
        total_servicos = len(servicos_por_usuario.get(user.id, []))
        total_agendamentos = len(agendamentos_por_usuario.get(user.id, []))
        total_agendamentos_abertos = agendamentos_abertos_por_usuario.get(user.id, 0)

        estimated_volume = estimate_user_data_volume(user)
        total_estimated_volume += estimated_volume

        if activity:
            method_distribution["GET"] += activity.total_get_requests
            method_distribution["POST"] += activity.total_post_requests
            method_distribution["PUT"] += activity.total_put_requests
            method_distribution["DELETE"] += activity.total_delete_requests
            login_distribution["success"] += activity.total_login_success
            login_distribution["failed"] += activity.total_login_failed
            total_requests_geral += activity.total_requests

        user_rows.append(
            {
                "id": user.id,
                "username": user.username,
                "full_name": user.get_full_name() or user.username,
                "email": user.email,
                "is_staff": user.is_staff,
                "date_joined": user.date_joined,
                "last_login": user.last_login,
                "activity": activity,
                "total_clientes": total_clientes,
                "total_servicos": total_servicos,
                "total_agendamentos": total_agendamentos,
                "total_agendamentos_abertos": total_agendamentos_abertos,
                "assinaturas": assinaturas_por_usuario.get(user.id, []),
                "estimated_data_volume": estimated_volume,
            }
        )

    user_rows.sort(
        key=lambda row: (
            row["activity"].total_requests if row["activity"] else 0,
            row["total_agendamentos"],
        ),
        reverse=True,
    )

    chart_labels = [row["username"] for row in user_rows]
    chart_requests = [
        row["activity"].total_requests if row["activity"] else 0 for row in user_rows
    ]
    chart_memory = [row["estimated_data_volume"] for row in user_rows]

    charts_payload = {
        "labels": chart_labels,
        "requests": chart_requests,
        "memory": chart_memory,
        "loginSuccess": [
            row["activity"].total_login_success if row["activity"] else 0
            for row in user_rows
        ],
        "loginFailed": [
            row["activity"].total_login_failed if row["activity"] else 0
            for row in user_rows
        ],
    }

    db_path = settings.DATABASES["default"]["NAME"]
    try:
        db_size_bytes = os.path.getsize(db_path)
    except (OSError, TypeError):
        db_size_bytes = None

    def humanize_bytes(value):
        if value is None:
            return "N/D"
        suffixes = ["B", "KB", "MB", "GB", "TB"]
        index = 0
        value = float(value)
        while value >= 1024 and index < len(suffixes) - 1:
            value /= 1024.0
            index += 1
        return f"{value:.2f} {suffixes[index]}"

    top_active_users = user_rows[:5]
    top_memory_users = sorted(
        user_rows, key=lambda row: row["estimated_data_volume"], reverse=True
    )[:5]

    context = {
        "site_title": "Monitoramento de Usuários",
        "site_header": "Sistema de Agendamento - 4Minds",
        "total_users": users.count(),
        "user_rows": user_rows,
        "top_active_users": top_active_users,
        "top_memory_users": top_memory_users,
        "total_requests": total_requests_geral,
        "total_estimated_volume": total_estimated_volume,
        "total_estimated_volume_human": humanize_bytes(total_estimated_volume),
        "db_size_bytes": db_size_bytes,
        "db_size_human": humanize_bytes(db_size_bytes) if db_size_bytes else "N/D",
        "method_distribution": method_distribution,
        "login_distribution": login_distribution,
        "agendamentos_por_status": agendamentos_por_status,
        "charts_payload": json.dumps(charts_payload, cls=DjangoJSONEncoder),
    }

    return render(request, "admin/user_activity_dashboard.html", context)
