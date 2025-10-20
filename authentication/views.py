from django.shortcuts import render, redirect
from django.urls import reverse_lazy
from django.contrib.auth.views import LoginView, LogoutView
from django.contrib.auth.mixins import LoginRequiredMixin, UserPassesTestMixin
from django.contrib.auth.models import User
from django.contrib.auth.forms import UserCreationForm
from django.contrib import messages
from django.views.generic import (
    ListView,
    CreateView,
    UpdateView,
    DeleteView,
    DetailView,
    TemplateView,
)
from .forms import (
    CustomUserCreationForm,
    CustomUserChangeForm,
    PaymentMethodForm,
    CreditCardForm,
    BillingInfoForm,
)
from django.contrib.auth import logout
from django.contrib.auth.decorators import login_required
from django.http import JsonResponse
from django.views.decorators.http import require_POST
from .models import PreferenciasUsuario, Plano, AssinaturaUsuario
from django.views.decorators.csrf import csrf_protect
from django.utils import timezone
from datetime import datetime, timedelta
import logging
from django.core.exceptions import ValidationError
from django.db import IntegrityError
from financeiro.services.asaas import AsaasClient
from django.conf import settings
from .pix_views import PaymentPixView

# ========================================
# FUNÇÕES UTILITÁRIAS
# ========================================


def verificar_assinatura_expirada(user):
    """
    Verifica se o usuário tem assinatura ativa e não expirada.
    Retorna True se expirada, False se ativa.
    """
    if not user.is_authenticated:
        return False

    try:
        # Buscar assinatura ativa mais recente
        assinatura = (
            AssinaturaUsuario.objects.filter(usuario=user, status="ativa")
            .order_by("-data_inicio")
            .first()
        )

        if not assinatura:
            # Usuário não tem assinatura ativa
            return True

        # Verificar se a assinatura expirou
        agora = timezone.now()
        if assinatura.data_fim < agora:
            # Marcar como expirada
            assinatura.status = "expirada"
            assinatura.save()
            return True

        return False

    except Exception as e:
        logging.error(f"Erro ao verificar assinatura do usuário {user.id}: {e}")
        return True  # Em caso de erro, considerar como expirada por segurança


# ========================================
# VIEWS DE AUTENTICAÇÃO
# ========================================


class CustomLoginView(LoginView):
    """View personalizada para login"""

    template_name = "authentication/login.html"
    redirect_authenticated_user = True

    def get_success_url(self):
        return reverse_lazy("agendamentos:dashboard")

    def form_valid(self, form):
        user = form.get_user()

        # Verificar se o usuário está ativo
        if not user.is_active:
            messages.error(
                self.request,
                "Sua conta está inativa. Entre em contato com o suporte para reativar sua conta.",
            )
            return redirect("authentication:plan_selection")

        # Verificar se a assinatura expirou
        if verificar_assinatura_expirada(user):
            # Primeiro, fazer o login do usuário para salvar a sessão
            from django.contrib.auth import login

            login(self.request, user)

            # Redirecionar para seleção de planos com mensagem
            messages.warning(
                self.request,
                "Seu período gratuito expirou. Selecione um plano para continuar usando o sistema.",
            )
            return redirect("authentication:plan_selection")

        messages.success(
            self.request,
            f"Bem-vindo, {user.first_name or user.username}!",
        )
        return super().form_valid(form)

    def form_invalid(self, form):
        """Lidar com formulário inválido, incluindo usuários inativos"""
        # Verificar se é um problema de usuário inativo
        username = form.cleaned_data.get("username") if form.cleaned_data else None
        if username:
            try:
                user = User.objects.get(username=username)
                if not user.is_active:
                    messages.error(
                        self.request,
                        "Sua conta está inativa. Entre em contato com o suporte para reativar sua conta.",
                    )
                    return redirect("authentication:plan_selection")
            except User.DoesNotExist:
                pass

        return super().form_invalid(form)


def custom_logout_view(request):
    """View simples para logout"""
    logout(request)
    return redirect("agendamentos:home")  # Redireciona para página inicial


class RegisterView(CreateView):
    """View para registro de novos usuários"""

    model = User
    form_class = CustomUserCreationForm
    template_name = "authentication/register.html"
    success_url = reverse_lazy("authentication:plan_selection")

    def form_valid(self, form):
        """Processa o formulário válido com tratamento de erros"""
        try:
            # Salvar o usuário
            user = form.save()

            # Fazer login automático após registro
            from django.contrib.auth import login

            login(self.request, user)

            # Criar preferências padrão para o usuário
            try:
                PreferenciasUsuario.objects.create(
                    usuario=user, tema="claro", modo="normal"
                )
            except Exception as e:
                logging.warning(
                    f"Erro ao criar preferências para usuário {user.username}: {e}"
                )

            messages.success(
                self.request,
                f"Bem-vindo, {user.first_name or user.username}! Agora escolha seu plano.",
            )
            return super().form_valid(form)

        except IntegrityError as e:
            logging.error(f"Erro de integridade ao criar usuário: {e}")
            messages.error(
                self.request,
                "Erro interno do sistema. Tente novamente ou entre em contato com o suporte.",
            )
            return self.form_invalid(form)

        except ValidationError as e:
            logging.error(f"Erro de validação ao criar usuário: {e}")
            messages.error(
                self.request,
                "Dados inválidos. Verifique as informações e tente novamente.",
            )
            return self.form_invalid(form)

        except Exception as e:
            logging.error(f"Erro inesperado ao criar usuário: {e}")
            messages.error(
                self.request,
                "Ocorreu um erro inesperado. Tente novamente ou entre em contato com o suporte.",
            )
            return self.form_invalid(form)

    def form_invalid(self, form):
        """Processa formulário inválido com logs detalhados"""
        # Log dos erros para debugging
        for field, errors in form.errors.items():
            logging.warning(f"Erro no campo '{field}': {errors}")

        # Adicionar mensagem geral de erro
        if not messages.get_messages(self.request):
            messages.error(
                self.request, "Por favor, corrija os erros abaixo e tente novamente."
            )

        return super().form_invalid(form)


# ========================================
# VIEWS DE GERENCIAMENTO DE USUÁRIOS
# ========================================


class UserListView(LoginRequiredMixin, UserPassesTestMixin, ListView):
    """Lista todos os usuários (apenas para admins)"""

    model = User
    template_name = "authentication/user_list.html"
    context_object_name = "users"
    paginate_by = 20

    def test_func(self):
        return self.request.user.is_staff

    def get_queryset(self):
        return User.objects.all().order_by("username")


class UserCreateView(LoginRequiredMixin, UserPassesTestMixin, CreateView):
    """Criar novo usuário (apenas para admins)"""

    model = User
    form_class = CustomUserCreationForm
    template_name = "authentication/user_form.html"
    success_url = reverse_lazy("authentication:user_list")

    def test_func(self):
        return self.request.user.is_staff

    def form_valid(self, form):
        messages.success(self.request, "Usuário criado com sucesso!")
        return super().form_valid(form)


class UserUpdateView(LoginRequiredMixin, UserPassesTestMixin, UpdateView):
    """Atualizar usuário (apenas para admins)"""

    model = User
    form_class = CustomUserChangeForm
    template_name = "authentication/user_form.html"
    success_url = reverse_lazy("authentication:user_list")

    def test_func(self):
        return self.request.user.is_staff

    def form_valid(self, form):
        messages.success(self.request, "Usuário atualizado com sucesso!")
        return super().form_valid(form)


class UserDeleteView(LoginRequiredMixin, UserPassesTestMixin, DeleteView):
    """Deletar usuário (apenas para admins)"""

    model = User
    template_name = "authentication/user_confirm_delete.html"
    success_url = reverse_lazy("authentication:user_list")

    def test_func(self):
        return self.request.user.is_staff

    def delete(self, request, *args, **kwargs):
        messages.success(request, "Usuário deletado com sucesso!")
        return super().delete(request, *args, **kwargs)


class UserDetailView(LoginRequiredMixin, UserPassesTestMixin, DetailView):
    """Detalhes do usuário (apenas para admins)"""

    model = User
    template_name = "authentication/user_detail.html"
    context_object_name = "user_detail"

    def test_func(self):
        return self.request.user.is_staff


# ========================================
# VIEWS DE PERFIL
# ========================================


class ProfileView(LoginRequiredMixin, DetailView):
    """Visualizar perfil do usuário logado"""

    model = User
    template_name = "authentication/profile.html"
    context_object_name = "user_profile"

    def get_object(self):
        return self.request.user


class ProfileUpdateView(LoginRequiredMixin, UpdateView):
    """Atualizar perfil do usuário logado"""

    model = User
    fields = ["first_name", "last_name", "email"]
    template_name = "authentication/profile_update.html"
    success_url = reverse_lazy("authentication:profile")

    def get_object(self):
        return self.request.user

    def form_valid(self, form):
        messages.success(self.request, "Perfil atualizado com sucesso!")
        return super().form_valid(form)


@login_required
@require_POST
def alterar_tema(request):
    """AJAX para alterar tema do usuário"""
    tema = request.POST.get("tema")

    if tema not in ["default", "emerald", "sunset", "ocean", "purple"]:
        return JsonResponse({"error": "Tema inválido"}, status=400)

    preferencias = PreferenciasUsuario.get_or_create_for_user(request.user)
    preferencias.tema = tema
    preferencias.save()

    return JsonResponse(
        {
            "success": True,
            "tema": tema,
            "message": f"Tema alterado para {preferencias.get_tema_display()}",
        }
    )


@login_required
@require_POST
@csrf_protect
def alterar_modo(request):
    """AJAX para alterar modo claro/escuro"""
    try:
        modo = request.POST.get("modo")

        if modo not in ["light", "dark"]:
            return JsonResponse(
                {"success": False, "error": "Modo inválido"}, status=400
            )

        preferencias = PreferenciasUsuario.get_or_create_for_user(request.user)
        if not preferencias:
            return JsonResponse(
                {"success": False, "error": "Erro ao obter preferências"}, status=500
            )

        # CORRIGIDO: Salvar o modo atual antes de alterar
        modo_anterior = preferencias.modo
        preferencias.modo = modo
        preferencias.save()

        # CORRIGIDO: Mostrar mensagem baseada no novo modo
        modo_nome = "Escuro" if modo == "dark" else "Claro"

        return JsonResponse(
            {
                "success": True,
                "modo": modo,
                "modo_anterior": modo_anterior,
                "message": f"Modo alterado para {modo_nome} com sucesso!",
            }
        )

    except Exception as e:
        return JsonResponse({"success": False, "error": str(e)}, status=500)


# ========================================
# VIEWS DE SELEÇÃO DE PLANOS
# ========================================


class PlanSelectionView(LoginRequiredMixin, TemplateView):
    """View para seleção de planos após cadastro"""

    template_name = "authentication/plan_selection.html"

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context["planos"] = Plano.objects.filter(ativo=True).order_by("ordem")
        context["usuario"] = self.request.user

        # Verificar se o usuário já usou o período gratuito
        context["ja_usou_gratuito"] = self.verificar_ja_usou_gratuito()

        return context

    def verificar_ja_usou_gratuito(self):
        """Verifica se o usuário já usou o período gratuito"""
        try:
            # Buscar plano gratuito
            plano_gratuito = Plano.objects.filter(tipo="gratuito", ativo=True).first()
            if not plano_gratuito:
                return False

            # Verificar se o usuário já teve alguma assinatura gratuita
            assinaturas_gratuitas = AssinaturaUsuario.objects.filter(
                usuario=self.request.user, plano=plano_gratuito
            ).exists()

            return assinaturas_gratuitas

        except Exception as e:
            logging.error(
                f"Erro ao verificar período gratuito para usuário {self.request.user.id}: {e}"
            )
            return False


class PlanConfirmationView(LoginRequiredMixin, TemplateView):
    """View para confirmação de plano selecionado"""

    template_name = "authentication/plan_confirmation.html"

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        plano_id = self.kwargs.get("plano_id")
        try:
            context["plano"] = Plano.objects.get(id=plano_id, ativo=True)
        except Plano.DoesNotExist:
            context["plano"] = None
        context["usuario"] = self.request.user
        return context


@login_required
def select_plan(request, plano_id):
    """Processa a seleção de um plano"""
    try:
        plano = Plano.objects.get(id=plano_id, ativo=True)
        usuario = request.user

        # Verificar se já tem assinatura ativa
        assinatura_ativa = AssinaturaUsuario.objects.filter(
            usuario=usuario, status="ativa"
        ).first()

        if assinatura_ativa:
            messages.warning(request, "Você já possui uma assinatura ativa.")
            return redirect("authentication:plan_selection")

        # Criar nova assinatura
        data_fim = timezone.now() + timedelta(days=plano.duracao_dias)

        assinatura = AssinaturaUsuario.objects.create(
            usuario=usuario, plano=plano, data_fim=data_fim, status="ativa"
        )

        # Se for plano gratuito, ativar imediatamente
        if plano.tipo == "gratuito":
            messages.success(
                request,
                f"Período gratuito de {plano.duracao_dias} dias ativado com sucesso!",
            )
            return redirect("agendamentos:dashboard")

        # Para planos pagos, redirecionar para pagamento
        return redirect("authentication:plan_confirmation", plano_id=plano.id)

    except Plano.DoesNotExist:
        messages.error(request, "Plano não encontrado.")
        return redirect("authentication:plan_selection")


@login_required
def skip_plan_selection(request):
    """Pula a seleção de planos e ativa período gratuito"""
    try:
        # Buscar plano gratuito
        plano_gratuito = Plano.objects.get(tipo="gratuito", ativo=True)

        # Verificar se já tem assinatura ativa
        assinatura_ativa = AssinaturaUsuario.objects.filter(
            usuario=request.user, status="ativa"
        ).first()

        if assinatura_ativa:
            messages.warning(request, "Você já possui uma assinatura ativa.")
            return redirect("agendamentos:dashboard")

        # Criar assinatura gratuita
        data_fim = timezone.now() + timedelta(days=plano_gratuito.duracao_dias)

        AssinaturaUsuario.objects.create(
            usuario=request.user,
            plano=plano_gratuito,
            data_fim=data_fim,
            status="ativa",
        )

        messages.success(
            request, f"Período gratuito de {plano_gratuito.duracao_dias} dias ativado!"
        )
        return redirect("agendamentos:dashboard")

    except Plano.DoesNotExist:
        messages.error(request, "Plano gratuito não configurado.")
        return redirect("authentication:plan_selection")


@login_required
def get_plano_duracao(request, plano_id):
    """AJAX endpoint para obter duração do plano"""
    try:
        plano = Plano.objects.get(id=plano_id, ativo=True)
        return JsonResponse({"success": True, "duracao_dias": plano.duracao_dias})
    except Plano.DoesNotExist:
        return JsonResponse({"success": False, "error": "Plano não encontrado"})


# ========================================
# VIEWS DE CHECKOUT E PAGAMENTO
# ========================================


class CheckoutView(LoginRequiredMixin, TemplateView):
    """View para finalizar a compra do plano"""

    template_name = "authentication/checkout.html"

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        plano_id = self.kwargs.get("plano_id")

        try:
            plano = Plano.objects.get(id=plano_id, ativo=True)
            context["plano"] = plano
            context["payment_form"] = PaymentMethodForm()
            context["billing_form"] = BillingInfoForm()
            context["card_form"] = CreditCardForm()

            # Preencher dados do usuário se disponível
            if self.request.user.is_authenticated:
                billing_form = BillingInfoForm(
                    initial={
                        "nome_completo": f"{self.request.user.first_name} {self.request.user.last_name}".strip(),
                        "email": self.request.user.email,
                    }
                )
                context["billing_form"] = billing_form

        except Plano.DoesNotExist:
            messages.error(self.request, "Plano não encontrado.")
            return redirect("authentication:plan_selection")

        return context

    def post(self, request, *args, **kwargs):
        plano_id = self.kwargs.get("plano_id")

        try:
            plano = Plano.objects.get(id=plano_id, ativo=True)
        except Plano.DoesNotExist:
            messages.error(request, "Plano não encontrado.")
            return redirect("authentication:plan_selection")

        # Processar formulários
        payment_form = PaymentMethodForm(request.POST)
        billing_form = BillingInfoForm(request.POST)
        card_form = (
            CreditCardForm(request.POST)
            if request.POST.get("metodo_pagamento") == "cartao"
            else None
        )

        if payment_form.is_valid() and billing_form.is_valid():
            metodo_pagamento = payment_form.cleaned_data["metodo_pagamento"]

            # Validar formulário de cartão se necessário
            if metodo_pagamento == "cartao" and card_form:
                if not card_form.is_valid():
                    context = self.get_context_data()
                    context["payment_form"] = payment_form
                    context["billing_form"] = billing_form
                    context["card_form"] = card_form
                    context["plano"] = plano
                    return self.render_to_response(context)

            # Processar pagamento
            return self.processar_pagamento(
                request,
                plano,
                metodo_pagamento,
                billing_form.cleaned_data,
                card_form.cleaned_data if card_form else None,
            )

        # Se houver erros, renderizar novamente
        context = self.get_context_data()
        context["payment_form"] = payment_form
        context["billing_form"] = billing_form
        context["card_form"] = card_form
        context["plano"] = plano
        return self.render_to_response(context)

    def processar_pagamento(
        self, request, plano, metodo_pagamento, billing_data, card_data=None
    ):
        """Processa o pagamento do plano"""

        # Calcular valor baseado no método de pagamento
        if metodo_pagamento == "pix":
            valor = plano.preco_pix
        else:
            valor = plano.preco_cartao

        # Criar assinatura
        data_fim = timezone.now() + timedelta(days=plano.duracao_dias)

        assinatura = AssinaturaUsuario.objects.create(
            usuario=request.user,
            plano=plano,
            data_fim=data_fim,
            status="ativa",
            valor_pago=valor,
            metodo_pagamento=metodo_pagamento,
        )

        if metodo_pagamento == "pix":
            # Gerar QR Code PIX via Asaas
            qr_code_data = self.gerar_qr_code_pix(plano, valor, billing_data)

            # Armazenar dados do PIX na sessão
            request.session["pix_data"] = qr_code_data
            request.session["assinatura_id"] = assinatura.id

            return redirect("authentication:payment_pix", assinatura_id=assinatura.id)
        else:
            # Simular processamento de cartão
            return self.processar_cartao(request, assinatura, card_data, billing_data)

    def gerar_qr_code_pix(self, plano, valor, billing_data):
        """Gera dados para QR Code PIX (simulado)"""
        # Em um sistema real, aqui seria feita a integração com gateway de pagamento
        return {
            "qr_code": f"00020126580014br.gov.bcb.pix0136{plano.id}-{valor}-{billing_data['cpf']}",
            "chave_pix": "contato@sistema.com.br",
            # Converter Decimal para float para permitir serialização JSON na sessão
            "valor": float(valor),
            "descricao": f"Pagamento - {plano.nome}",
        }

    def processar_cartao(self, request, assinatura, card_data, billing_data):
        """Processa pagamento com cartão (simulado)"""
        # Em um sistema real, aqui seria feita a integração com gateway de pagamento
        # Simular processamento bem-sucedido
        messages.success(request, "Pagamento processado com sucesso!")
        return redirect("authentication:payment_success", assinatura_id=assinatura.id)


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

            # Gerar dados do PIX
            qr_data = self.gerar_qr_code_pix(
                assinatura.plano,
                assinatura.valor_pago,
                {
                    "cpf": "00000000000",  # Em um sistema real, pegaria dos dados de cobrança
                    "nome_completo": assinatura.usuario.get_full_name(),
                    "email": assinatura.usuario.email or "contato@sistema.com.br",
                    "telefone": "11999999999",  # Em um sistema real, pegaria dos dados de cobrança
                },
            )
            # Manter ambas as chaves por compatibilidade com templates existentes
            context["qr_data"] = qr_data
            context["pix_data"] = qr_data

        except AssinaturaUsuario.DoesNotExist:
            messages.error(self.request, "Assinatura não encontrada.")
            return redirect("authentication:plan_selection")

        return context

    def gerar_qr_code_pix(self, plano, valor, billing_data):
        """Gera dados para QR Code PIX usando API Asaas"""
        try:
            # Inicializar cliente Asaas
            asaas_client = AsaasClient()

            # Criar cliente no Asaas
            customer_data = asaas_client.create_customer(
                name=billing_data["nome_completo"],
                email=billing_data["email"],
                cpf_cnpj=billing_data["cpf"].replace(".", "").replace("-", ""),
                phone=billing_data["telefone"]
                .replace("(", "")
                .replace(")", "")
                .replace("-", "")
                .replace(" ", ""),
            )

            # Criar cobrança PIX
            due_date = (datetime.now() + timedelta(days=1)).strftime("%Y-%m-%d")

            payment_data = asaas_client.create_payment(
                customer_id=customer_data["id"],
                value=float(valor),
                due_date=due_date,
                billing_type="PIX",
                description=f"Pagamento - {plano.nome}",
            )

            # Obter QR Code PIX
            pix_data = asaas_client.get_pix_qr(payment_data["id"])

            return {
                "payment_id": payment_data["id"],
                "qr_code": pix_data.get("payload", ""),
                "qr_code_image": pix_data.get("encodedImage", ""),
                "chave_pix": pix_data.get("payload", ""),
                "valor": float(valor),
                "descricao": f"Pagamento - {plano.nome}",
                "vencimento": due_date,
                "status": payment_data.get("status", "PENDING"),
                "pix_copia_cola": pix_data.get("payload", ""),
            }

        except Exception as e:
            error_msg = str(e)
            logging.error(f"Erro ao gerar PIX via Asaas: {error_msg}")

            # Determinar tipo de erro para mensagem mais específica
            if "401" in error_msg:
                error_detail = "Chave API do Asaas inválida ou expirada. Entre em contato com o suporte."
            elif "403" in error_msg:
                error_detail = (
                    "Acesso negado à API do Asaas. Verifique as permissões da conta."
                )
            elif "404" in error_msg:
                error_detail = "Recurso não encontrado na API do Asaas."
            elif "500" in error_msg or "502" in error_msg or "503" in error_msg:
                error_detail = "Serviço do Asaas temporariamente indisponível. Tente novamente em alguns minutos."
            else:
                error_detail = f"Erro na integração com Asaas: {error_msg}"

            # Fallback para simulação em caso de erro
            return {
                "payment_id": f"sim_{plano.id}_{int(timezone.now().timestamp())}",
                "qr_code": f"00020126580014br.gov.bcb.pix0136{plano.id}-{valor}-{billing_data['cpf']}",
                "qr_code_image": "",
                "chave_pix": "contato@sistema.com.br",
                "valor": float(valor),
                "descricao": f"Pagamento - {plano.nome}",
                "vencimento": (timezone.now() + timedelta(days=1)).strftime("%Y-%m-%d"),
                "status": "PENDING",
                "pix_copia_cola": f"00020126580014br.gov.bcb.pix0136{plano.id}-{valor}-{billing_data['cpf']}5204000053039865405{valor:.2f}5802BR5913Sistema Agend6009SAO PAULO62070503***6304",
                "erro": error_detail,
            }


class PaymentSuccessView(LoginRequiredMixin, TemplateView):
    """View de sucesso do pagamento"""

    template_name = "authentication/payment_success.html"

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        assinatura_id = self.kwargs.get("assinatura_id")

        try:
            assinatura = AssinaturaUsuario.objects.get(
                id=assinatura_id, usuario=self.request.user
            )
            context["assinatura"] = assinatura
        except AssinaturaUsuario.DoesNotExist:
            messages.error(self.request, "Assinatura não encontrada.")
            return redirect("authentication:plan_selection")

        return context
