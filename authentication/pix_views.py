from django.shortcuts import render, redirect
from django.contrib.auth.mixins import LoginRequiredMixin
from django.views.generic import TemplateView
from django.contrib import messages
from .models import AssinaturaUsuario


class PaymentPixView(LoginRequiredMixin, TemplateView):
    """View para exibir QR Code PIX"""

    template_name = "authentication/payment_pix.html"

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        assinatura_id = self.kwargs.get("assinatura_id")

        try:
            assinatura = AssinaturaUsuario.objects.get(
                id=assinatura_id, usuario=self.request.user
            )
            context["assinatura"] = assinatura

            # Recuperar dados do PIX da sessão
            pix_data = self.request.session.get("pix_data", {})
            if pix_data:
                context["pix_data"] = pix_data
            else:
                # Se não houver dados na sessão, redirecionar para checkout
                messages.error(self.request, "Dados do pagamento não encontrados.")
                return redirect("authentication:plan_selection")

        except AssinaturaUsuario.DoesNotExist:
            messages.error(self.request, "Assinatura não encontrada.")
            return redirect("authentication:plan_selection")

        return context
