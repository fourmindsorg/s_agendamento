from django.shortcuts import redirect
from django.contrib import messages
from django.core.exceptions import PermissionDenied
from django.utils import timezone
from datetime import timedelta
from .models import AssinaturaUsuario


class SubscriptionRequiredMixin:
    """
    Mixin que verifica se o usuário tem assinatura ativa.
    Usuários expirados podem apenas visualizar, mas não criar/editar/deletar.
    """

    def dispatch(self, request, *args, **kwargs):
        # Verificar se o usuário está autenticado
        if not request.user.is_authenticated:
            return redirect("authentication:login")

        # Verificar se o usuário está ativo
        if not request.user.is_active:
            messages.error(
                request,
                "Sua conta está inativa. Entre em contato com o suporte para reativar sua conta.",
            )
            return redirect("authentication:plan_selection")

        # Verificar status da assinatura
        assinatura_status = self.get_assinatura_status(request.user)

        if assinatura_status == "expirada":
            # Para usuários expirados, permitir apenas visualização
            if self.is_write_operation():
                messages.warning(
                    request,
                    "Seu período gratuito expirou. Para criar, editar ou excluir dados, contrate um plano.",
                )
                return redirect("authentication:plan_selection")

        elif assinatura_status == "sem_assinatura":
            # Para usuários sem assinatura, permitir apenas visualização
            if self.is_write_operation():
                messages.warning(
                    request,
                    "Você precisa de uma assinatura ativa para criar, editar ou excluir dados.",
                )
                return redirect("authentication:plan_selection")

        return super().dispatch(request, *args, **kwargs)

    def get_assinatura_status(self, user):
        """Determina o status da assinatura do usuário"""
        try:
            # Buscar assinatura ativa mais recente
            assinatura = (
                AssinaturaUsuario.objects.filter(usuario=user, status="ativa")
                .order_by("-data_inicio")
                .first()
            )

            if not assinatura:
                return "sem_assinatura"

            # Verificar se a assinatura expirou
            agora = timezone.now()
            if assinatura.data_fim < agora:
                # Marcar como expirada
                assinatura.status = "expirada"
                assinatura.save()
                return "expirada"

            return "ativa"

        except Exception:
            return "sem_assinatura"

    def is_write_operation(self):
        """Verifica se a operação atual é de escrita (criar/editar/deletar)"""
        # Verificar métodos HTTP
        if self.request.method in ["POST", "PUT", "PATCH", "DELETE"]:
            return True

        # Verificar se é uma view de criação/edição/exclusão
        view_name = self.__class__.__name__.lower()
        write_views = ["create", "update", "edit", "delete", "destroy"]

        return any(write_view in view_name for write_view in write_views)


class ReadOnlyForExpiredMixin:
    """
    Mixin que torna a view somente leitura para usuários expirados.
    Usado em views de listagem e detalhes.
    """

    def dispatch(self, request, *args, **kwargs):
        # Verificar se o usuário está autenticado
        if not request.user.is_authenticated:
            return redirect("authentication:login")

        # Verificar se o usuário está ativo
        if not request.user.is_active:
            messages.error(
                request,
                "Sua conta está inativa. Entre em contato com o suporte para reativar sua conta.",
            )
            return redirect("authentication:plan_selection")

        # Verificar status da assinatura
        assinatura_status = self.get_assinatura_status(request.user)

        if assinatura_status == "expirada":
            # Adicionar contexto para mostrar que está em modo somente leitura
            self.request.read_only_mode = True
            messages.warning(
                request,
                "Seu período gratuito expirou. Você está visualizando em modo somente leitura. Contrate um plano para editar dados.",
            )

        elif assinatura_status == "sem_assinatura":
            self.request.read_only_mode = True
            messages.info(
                request,
                "Você está visualizando em modo somente leitura. Contrate um plano para editar dados.",
            )

        return super().dispatch(request, *args, **kwargs)

    def get_assinatura_status(self, user):
        """Determina o status da assinatura do usuário"""
        try:
            # Buscar assinatura ativa mais recente
            assinatura = (
                AssinaturaUsuario.objects.filter(usuario=user, status="ativa")
                .order_by("-data_inicio")
                .first()
            )

            if not assinatura:
                return "sem_assinatura"

            # Verificar se a assinatura expirou
            agora = timezone.now()
            if assinatura.data_fim < agora:
                # Marcar como expirada
                assinatura.status = "expirada"
                assinatura.save()
                return "expirada"

            return "ativa"

        except Exception:
            return "sem_assinatura"

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context["read_only_mode"] = getattr(self.request, "read_only_mode", False)
        return context
