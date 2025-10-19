from django.shortcuts import redirect
from django.contrib import messages
from django.urls import reverse
from django.utils import timezone
from .models import AssinaturaUsuario
import logging


def safe_add_message(request, level, message):
    """
    Adiciona uma mensagem de forma segura, verificando se o middleware de mensagens está instalado.
    """
    try:
        # Verificar se o request tem o atributo _messages (middleware de mensagens instalado)
        if hasattr(request, "_messages"):
            messages.add_message(request, level, message)
        else:
            # Se não tiver o middleware de mensagens, apenas logar
            logging.warning(
                f"Middleware de mensagens não disponível. Mensagem: {message}"
            )
    except Exception as e:
        # Se não conseguir adicionar mensagem, apenas logar o erro
        logging.warning(f"Não foi possível adicionar mensagem: {e}")


class SubscriptionExpirationMiddleware:
    """
    Middleware para verificar se a assinatura do usuário expirou.
    Redireciona para a página de planos se a assinatura estiver expirada.
    """

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        # URLs que não precisam de verificação de assinatura
        exempt_urls = [
            "/authentication/login/",
            "/authentication/register/",
            "/authentication/logout/",
            "/authentication/planos/",
            "/authentication/planos/confirmar/",
            "/authentication/checkout/",
            "/authentication/pagamento/",
            "/admin/",
            "/static/",
            "/media/",
            "/info/",
        ]

        # URLs específicas que são exceções
        exempt_paths = [
            "/",  # Página inicial exata
            "/authentication/planos/",  # Página de planos
        ]

        # Verificar se a URL atual está na lista de exceções
        current_path = request.path
        is_exempt = (
            any(current_path.startswith(url) for url in exempt_urls)
            or current_path in exempt_paths
        )

        # Se for uma URL exceção ou usuário não autenticado, continuar normalmente
        if is_exempt or not request.user.is_authenticated:
            response = self.get_response(request)
            return response

        # Verificar se o usuário está ativo
        if not request.user.is_active:
            safe_add_message(
                request,
                messages.ERROR,
                "Sua conta está inativa. Entre em contato com o suporte para reativar sua conta.",
            )
            return redirect("authentication:plan_selection")

        # Verificar se a assinatura expirou
        try:
            # Buscar assinatura ativa mais recente
            assinatura = (
                AssinaturaUsuario.objects.filter(usuario=request.user, status="ativa")
                .order_by("-data_inicio")
                .first()
            )

            if not assinatura:
                # Usuário não tem assinatura ativa - permitir apenas visualização
                # Não redirecionar aqui, deixar as views decidirem
                pass

            # Verificar se a assinatura expirou (apenas se existir)
            if assinatura:
                agora = timezone.now()
                if assinatura.data_fim < agora:
                    # Marcar como expirada e redirecionar
                    assinatura.status = "expirada"
                    assinatura.save()

                    safe_add_message(
                        request,
                        messages.WARNING,
                        "Seu período gratuito expirou. Selecione um plano para continuar usando o sistema.",
                    )
                    return redirect("authentication:plan_selection")

        except Exception as e:
            logging.error(
                f"Erro no middleware de assinatura para usuário {request.user.id}: {e}"
            )
            # Em caso de erro, redirecionar para planos por segurança
            safe_add_message(
                request,
                messages.ERROR,
                "Erro ao verificar sua assinatura. Por favor, selecione um plano.",
            )
            return redirect("authentication:plan_selection")

        # Se chegou até aqui, a assinatura está ativa - continuar normalmente
        response = self.get_response(request)
        return response
