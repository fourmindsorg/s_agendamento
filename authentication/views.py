from django.shortcuts import render, redirect
from django.urls import reverse_lazy
from django.http import HttpResponse
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
from datetime import timedelta
import logging
from django.core.exceptions import ValidationError
from django.db import IntegrityError

# Importação condicional do AsaasClient
try:
    from financeiro.services.asaas import AsaasClient

    ASAAS_AVAILABLE = True
except RuntimeError as e:
    # Asaas não configurado - continuar sem ele
    AsaasClient = None
    ASAAS_AVAILABLE = False
    print(f"Asaas não disponível: {e}")
from django.conf import settings

# Importação condicional do PaymentPixView
try:
    from .pix_views import PaymentPixView
except ImportError as e:
    PaymentPixView = None
    print(f"PaymentPixView não disponível: {e}")

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
        # Verificar se o modelo existe e está acessível
        from django.db import connection
        from django.db.utils import DatabaseError

        # Testar conexão com banco
        cursor = connection.cursor()
        cursor.execute("SELECT 1")

        # Buscar assinatura ativa mais recente
        assinatura = (
            AssinaturaUsuario.objects.filter(usuario=user, status="ativa")
            .order_by("-data_inicio")
            .first()
        )

        if not assinatura:
            # Usuário não tem assinatura ativa - permitir acesso
            return False

        # Verificar se a assinatura expirou
        agora = timezone.now()
        if assinatura.data_fim < agora:
            # Marcar como expirada
            try:
                assinatura.status = "expirada"
                assinatura.save()
            except Exception as save_error:
                logging.error(f"Erro ao salvar assinatura expirada: {save_error}")
            return True

        return False

    except DatabaseError as e:
        logging.error(f"Erro de banco ao verificar assinatura: {e}")
        return False  # Em caso de erro de banco, permitir acesso
    except Exception as e:
        logging.error(f"Erro ao verificar assinatura do usuário {user.id}: {e}")
        return False  # Em caso de erro, permitir acesso (não bloquear)


# ========================================
# VIEWS DE AUTENTICAÇÃO
# ========================================


class TestLoginView(TemplateView):
    """View de teste - retorna apenas texto simples"""

    def get(self, request, *args, **kwargs):
        return HttpResponse("Teste funcionando! Sistema operacional.")

    def post(self, request, *args, **kwargs):
        return HttpResponse("POST funcionando! Sistema operacional.")


class SimpleLoginView(LoginView):
    """View de login super simples - apenas Django padrão"""

    template_name = "authentication/login.html"
    redirect_authenticated_user = True

    def get_success_url(self):
        return reverse_lazy("agendamentos:dashboard")

    def form_valid(self, form):
        """Login super simples - apenas Django padrão"""
        return super().form_valid(form)


class BasicLoginView(LoginView):
    """View de login básica sem verificações complexas"""

    template_name = "authentication/login.html"
    redirect_authenticated_user = True

    def get_success_url(self):
        return reverse_lazy("agendamentos:dashboard")

    def form_valid(self, form):
        """Login básico sem verificações extras"""
        try:
            # Login simples sem verificações
            return super().form_valid(form)
        except Exception as e:
            logging.error(f"Erro no login básico: {e}")
            # Em caso de erro, redirecionar para dashboard
            from django.contrib.auth import login

            user = form.get_user()
            login(self.request, user)
            return redirect(self.get_success_url())


class CustomLoginView(LoginView):
    """View personalizada para login - mantida para compatibilidade"""

    template_name = "authentication/login.html"
    redirect_authenticated_user = True

    def get_success_url(self):
        return reverse_lazy("agendamentos:dashboard")

    def form_valid(self, form):
        try:
            user = form.get_user()

            # Verificar se o usuário está ativo
            if not user.is_active:
                messages.error(
                    self.request,
                    "Sua conta está inativa. Entre em contato com o suporte para reativar sua conta.",
                )
                return redirect("authentication:plan_selection")

            # Verificar se a assinatura expirou (com tratamento de erro)
            try:
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
            except Exception as e:
                # Se houver erro na verificação de assinatura, continuar com login normal
                logging.error(f"Erro ao verificar assinatura: {e}")
                pass

            messages.success(
                self.request,
                f"Bem-vindo, {user.first_name or user.username}!",
            )
            return super().form_valid(form)
        except Exception as e:
            logging.error(f"Erro no form_valid: {e}")
            # Em caso de erro, fazer login básico
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
    success_url = reverse_lazy("agendamentos:dashboard")

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

            # Criar assinatura gratuita automaticamente
            try:
                from .models import Plano, AssinaturaUsuario
                from datetime import timedelta

                # Buscar plano gratuito
                plano_gratuito = Plano.objects.filter(
                    tipo="gratuito", ativo=True
                ).first()

                if plano_gratuito:
                    # Calcular data de fim (14 dias)
                    data_fim = timezone.now() + timedelta(
                        days=plano_gratuito.duracao_dias
                    )

                    # Criar assinatura gratuita
                    AssinaturaUsuario.objects.create(
                        usuario=user,
                        plano=plano_gratuito,
                        status="ativa",
                        data_fim=data_fim,
                        valor_pago=0.00,
                        metodo_pagamento="gratuito",
                    )

                    logging.info(
                        f"Assinatura gratuita criada para usuário {user.username}"
                    )
                else:
                    logging.warning("Plano gratuito não encontrado no sistema")

            except Exception as e:
                logging.error(
                    f"Erro ao criar assinatura gratuita para usuário {user.username}: {e}"
                )

            messages.success(
                self.request,
                f"Bem-vindo, {user.first_name or user.username}! Seu cadastro foi realizado com sucesso. Você tem 14 dias gratuitos para testar o sistema.",
            )
            return redirect("agendamentos:dashboard")

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
        # Buscar os 3 últimos planos ativos ordenados do menor valor para o maior (excluindo o gratuito)
        context["planos"] = (
            Plano.objects.filter(ativo=True)
            .exclude(tipo="gratuito")
            .order_by("preco_cartao")[:3]
        )
        context["usuario"] = self.request.user

        # Verificar se o usuário já usou o período gratuito
        context["ja_usou_gratuito"] = self.verificar_ja_usou_gratuito()

        # Verificar se tem assinatura aguardando pagamento
        context["tem_assinatura_aguardando"] = (
            self.tem_assinatura_aguardando_pagamento()
        )

        # Histórico de assinaturas do usuário (inclui planos anteriores)
        try:
            context["assinaturas_historico"] = (
                AssinaturaUsuario.objects.filter(usuario=self.request.user)
                .select_related("plano")
                .order_by("-data_inicio")
            )
        except Exception:
            context["assinaturas_historico"] = []

        return context

    def verificar_ja_usou_gratuito(self):
        """Verifica se o usuário já usou e expirou o período gratuito"""
        try:
            # Buscar plano gratuito
            plano_gratuito = Plano.objects.filter(tipo="gratuito", ativo=True).first()
            if not plano_gratuito:
                return False

            # Verificar se o usuário já teve alguma assinatura gratuita expirada
            assinatura_gratuita = (
                AssinaturaUsuario.objects.filter(
                    usuario=self.request.user, plano=plano_gratuito
                )
                .order_by("-data_fim")
                .first()
            )

            # Só retorna True se tiver assinatura gratuita E a data fim for menor que hoje (expirado)
            if assinatura_gratuita and assinatura_gratuita.data_fim < timezone.now():
                return True

            return False

        except Exception as e:
            logging.error(
                f"Erro ao verificar período gratuito para usuário {self.request.user.id}: {e}"
            )
            return False

    def tem_assinatura_aguardando_pagamento(self):
        """Verifica se o usuário tem assinatura aguardando pagamento"""
        try:
            return AssinaturaUsuario.objects.filter(
                usuario=self.request.user, status="aguardando_pagamento"
            ).exists()
        except Exception as e:
            logging.error(
                f"Erro ao verificar assinatura aguardando para usuário {self.request.user.id}: {e}"
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

        # Se já existe uma assinatura aguardando pagamento, encaminhar para finalizar
        assinatura_aguardando = AssinaturaUsuario.objects.filter(
            usuario=usuario, status="aguardando_pagamento"
        ).order_by("-data_inicio").first()
        if assinatura_aguardando:
            messages.warning(
                request,
                "Você tem uma assinatura aguardando pagamento. Finalize o pagamento antes de assinar outro plano.",
            )
            return redirect(
                "authentication:payment_pix", assinatura_id=assinatura_aguardando.id
            )

        # Calcular início do novo plano: se existir assinatura ATIVA cujo fim ainda não passou,
        # o novo plano inicia no dia seguinte à data_fim; caso contrário, inicia agora
        assinatura_ativa = AssinaturaUsuario.objects.filter(
            usuario=usuario, status="ativa"
        ).order_by("-data_fim").first()

        if assinatura_ativa and assinatura_ativa.data_fim and assinatura_ativa.data_fim >= timezone.now():
            data_inicio = assinatura_ativa.data_fim + timedelta(days=1)
        else:
            data_inicio = timezone.now()

        # Fluxo para plano gratuito: ativa imediatamente (ou agenda para o dia seguinte ao fim do atual)
        if plano.tipo == "gratuito":
            data_fim = data_inicio + timedelta(days=plano.duracao_dias)
            AssinaturaUsuario.objects.create(
                usuario=usuario,
                plano=plano,
                data_fim=data_fim,
                status="ativa",
            )
            messages.success(
                request,
                f"Período gratuito de {plano.duracao_dias} dias ativado com sucesso!",
            )
            return redirect("agendamentos:dashboard")

        # Planos pagos: seguir para confirmação/pagamento (a lógica de agendamento do início
        # está em CheckoutView.processar_pagamento, que respeita a assinatura ativa)
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

        # Calcular início considerando assinatura ativa
        assinatura_ativa = AssinaturaUsuario.objects.filter(
            usuario=request.user, status="ativa"
        ).order_by("-data_fim").first()

        if assinatura_ativa and assinatura_ativa.data_fim and assinatura_ativa.data_fim >= timezone.now():
            data_inicio = assinatura_ativa.data_fim + timedelta(days=1)
        else:
            data_inicio = timezone.now()

        # Criar assinatura gratuita (ativa) com término calculado a partir do início decidido
        data_fim = data_inicio + timedelta(days=plano_gratuito.duracao_dias)

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

        # Verificar se já existe assinatura ativa
        assinatura_ativa = AssinaturaUsuario.objects.filter(
            usuario=request.user, status="ativa"
        ).first()

        # Se já tem assinatura ativa, começar nova assinatura no dia seguinte ao término da atual
        if assinatura_ativa and assinatura_ativa.data_fim:
            data_inicio = assinatura_ativa.data_fim + timedelta(days=1)
        else:
            data_inicio = timezone.now()

        # Criar assinatura com status aguardando_pagamento
        data_fim = data_inicio + timedelta(days=plano.duracao_dias)

        assinatura = AssinaturaUsuario.objects.create(
            usuario=request.user,
            plano=plano,
            data_fim=data_fim,
            status="aguardando_pagamento",
            valor_pago=valor,
            metodo_pagamento=metodo_pagamento,
        )

        if metodo_pagamento == "pix":
            # Gerar QR Code PIX via Asaas
            qr_code_data = self.gerar_qr_code_pix(
                plano, valor, billing_data, assinatura
            )

            # Armazenar dados do PIX na sessão
            request.session["pix_data"] = qr_code_data
            request.session["assinatura_id"] = assinatura.id

            return redirect("authentication:payment_pix", assinatura_id=assinatura.id)
        else:
            # Simular processamento de cartão
            return self.processar_cartao(request, assinatura, card_data, billing_data)

    def gerar_qr_code_pix(self, plano, valor, billing_data, assinatura):
        """Gera dados para QR Code PIX (simulado)"""
        # Em um sistema real, aqui seria feita a integração com gateway de pagamento
        return {
            "qr_code": f"00020126580014br.gov.bcb.pix0136{plano.id}-{valor}-{billing_data['cpf']}",
            "chave_pix": "contato@sistema.com.br",
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
                    "nome_completo": assinatura.usuario.get_full_name()
                    or assinatura.usuario.username,
                    "email": assinatura.usuario.email or "",
                    "telefone": "",
                },
                assinatura,
            )
            context["qr_data"] = qr_data

        except AssinaturaUsuario.DoesNotExist:
            messages.error(self.request, "Assinatura não encontrada.")
            return redirect("authentication:plan_selection")

        return context

    def gerar_qr_code_pix(self, plano, valor, billing_data, assinatura):
        """Gera dados para QR Code PIX usando API Asaas"""

        # Se já tem payment_id, não precisa criar novamente
        if assinatura.asaas_payment_id:
            logging.info(f"Usando payment_id existente: {assinatura.asaas_payment_id}")
            return {
                "payment_id": assinatura.asaas_payment_id,
                "qr_code": "qr_code_existente",
                "qr_code_image": "",
                "chave_pix": "chave_pix_existente",
                "valor": float(valor),
                "descricao": f"Pagamento - {plano.nome}",
                "vencimento": "",
                "status": "PENDING",
                "pix_copia_cola": "qr_code_existente",
            }

        if not ASAAS_AVAILABLE:
            raise RuntimeError("Serviço de pagamento Asaas não está configurado")

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
            from datetime import datetime, timedelta

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

            # Salvar payment_id na assinatura
            assinatura.asaas_payment_id = payment_data["id"]
            assinatura.save()

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
            logging.error(f"Erro ao gerar PIX via Asaas: {str(e)}")
            # Fallback para simulação em caso de erro
            valor_float = float(valor)
            return {
                "payment_id": f"sim_{plano.id}_{int(timezone.now().timestamp())}",
                "qr_code": f"00020126580014br.gov.bcb.pix0136{plano.id}-{valor_float}-{billing_data['cpf']}",
                "qr_code_image": "",
                "chave_pix": "contato@sistema.com.br",
                "valor": valor_float,
                "descricao": f"Pagamento - {plano.nome}",
                "vencimento": (timezone.now() + timedelta(days=1)).strftime("%Y-%m-%d"),
                "status": "PENDING",
                "pix_copia_cola": f"00020126580014br.gov.bcb.pix0136{plano.id}-{valor_float}-{billing_data['cpf']}5204000053039865405{valor_float:.2f}5802BR5913Sistema Agend6009SAO PAULO62070503***6304",
                "erro": "Modo simulação ativado",
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


# ========================================
# GERENCIAMENTO DE ASSINATURAS
# ========================================


@login_required
@require_POST
def delete_assinatura(request, assinatura_id):
    """Deleta uma assinatura com validação de status"""
    try:
        # Buscar assinatura do usuário
        assinatura = AssinaturaUsuario.objects.get(
            id=assinatura_id, usuario=request.user
        )

        # Não permitir deletar se estiver ativa ou expirada
        if assinatura.status in ["ativa", "expirada"]:
            messages.error(
                request,
                f"Não é possível deletar uma assinatura com status '{assinatura.get_status_display()}'.",
            )
            return redirect("authentication:plan_selection")

        # Permitir deletar apenas se estiver aguardando pagamento, cancelada ou suspensa
        assinatura.delete()
        messages.success(request, "Assinatura deletada com sucesso.")

        return redirect("authentication:plan_selection")

    except AssinaturaUsuario.DoesNotExist:
        messages.error(request, "Assinatura não encontrada.")
        return redirect("authentication:plan_selection")
    except Exception as e:
        logging.error(f"Erro ao deletar assinatura {assinatura_id}: {e}")
        messages.error(request, "Erro ao deletar assinatura.")
        return redirect("authentication:plan_selection")


# ========================================
# WEBHOOK PARA CONFIRMAÇÃO DE PAGAMENTO
# ========================================


@csrf_protect
@require_POST
def asaas_webhook(request):
    """
    Webhook para receber notificações de pagamento do Asaas.
    Atualiza o status da assinatura quando o pagamento é confirmado.
    """
    try:
        import json

        # Receber dados do Asaas
        if request.content_type == "application/json":
            data = json.loads(request.body)
        else:
            data = request.POST.dict()

        event_type = data.get("event")
        payment_data = data.get("payment", {})

        logging.info(f"Webhook Asaas recebido: {event_type}")
        logging.info(f"Dados: {data}")

        if event_type not in [
            "PAYMENT_CONFIRMED",
            "PAYMENT_RECEIVED",
            "PAYMENT_OVERDUE",
        ]:
            return JsonResponse(
                {"status": "ignored", "message": f"Evento {event_type} ignorado"}
            )

        # Buscar assinatura pelo ID do pagamento Asaas
        payment_id = payment_data.get("id")
        if not payment_id:
            return JsonResponse(
                {"status": "error", "message": "ID do pagamento não encontrado"}
            )

        # Buscar assinatura correspondente
        assinatura = AssinaturaUsuario.objects.filter(
            asaas_payment_id=payment_id
        ).first()

        if not assinatura:
            logging.warning(f"Assinatura não encontrada para payment_id: {payment_id}")
            return JsonResponse(
                {"status": "error", "message": "Assinatura não encontrada"}
            )

        # Atualizar status da assinatura baseado no evento
        if event_type in ["PAYMENT_CONFIRMED", "PAYMENT_RECEIVED"]:
            # Pagamento confirmado - ativar assinatura
            assinatura.status = "ativa"
            assinatura.save()
            logging.info(f"Assinatura {assinatura.id} ativada - Pagamento confirmado")

            # Notificar usuário (opcional)
            # Aqui você pode enviar email, notificação push, etc.

        elif event_type == "PAYMENT_OVERDUE":
            # Pagamento vencido - manter como aguardando_pagamento
            logging.warning(f"Assinatura {assinatura.id} - Pagamento vencido")

        return JsonResponse(
            {"status": "success", "message": "Webhook processado com sucesso"}
        )

    except json.JSONDecodeError:
        logging.error("Erro ao decodificar JSON do webhook")
        return JsonResponse({"status": "error", "message": "JSON inválido"})
    except Exception as e:
        logging.error(f"Erro no webhook Asaas: {str(e)}")
        return JsonResponse({"status": "error", "message": str(e)})
