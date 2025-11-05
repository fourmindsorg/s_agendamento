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
from datetime import timedelta, datetime
import logging
from django.core.exceptions import ValidationError
from django.db import IntegrityError


def traduzir_status_asaas(status_en: str) -> str:
    """
    Traduz o status do Asaas (em inglês) para português.
    
    Args:
        status_en: Status em inglês do Asaas (PENDING, RECEIVED, etc.)
    
    Returns:
        Status traduzido para português
    """
    traducao_status = {
        "PENDING": "PENDENTE",
        "RECEIVED": "RECEBIDO",
        "OVERDUE": "VENCIDO",
        "REFUNDED": "REEMBOLSADO",
        "RECEIVED_IN_CASH_UNDONE": "RECEBIDO EM ESPÉCIE (DESFEITO)",
        "CHARGEBACK_REQUESTED": "CHARGEBACK SOLICITADO",
        "CHARGEBACK_DISPUTE": "DISPUTA DE CHARGEBACK",
        "AWAITING_CHARGEBACK_REVERSAL": "AGUARDANDO REVERSÃO DE CHARGEBACK",
        "DUNNING_REQUESTED": "COBRANÇA SOLICITADA",
        "DUNNING_RECEIVED": "COBRANÇA RECEBIDA",
        "AWAITING_RISK_ANALYSIS": "AGUARDANDO ANÁLISE DE RISCO",
        "APPROVED": "APROVADO",
        "CANCELLED": "CANCELADO",
        "DELETED": "DELETADO",
    }
    return traducao_status.get(status_en.upper(), status_en.upper())


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
            assinaturas_historico = (
                AssinaturaUsuario.objects.filter(usuario=self.request.user)
                .select_related("plano")
                .order_by("-data_inicio")
            )
            
            # Verificar e atualizar assinaturas pendentes antes de exibir
            assinaturas_pendentes = assinaturas_historico.filter(status="aguardando_pagamento")
            if assinaturas_pendentes.exists():
                logging.info(f"🔄 Verificando {assinaturas_pendentes.count()} assinatura(s) pendente(s) antes de exibir histórico")
                assinaturas_atualizadas = self.verificar_e_atualizar_pagamentos_pendentes(assinaturas_pendentes)
                if assinaturas_atualizadas:
                    logging.info(f"✅ {len(assinaturas_atualizadas)} assinatura(s) atualizada(s) antes de exibir histórico")
                # Recarregar assinaturas para ter os status atualizados
                assinaturas_historico = (
                    AssinaturaUsuario.objects.filter(usuario=self.request.user)
                    .select_related("plano")
                    .order_by("-data_inicio")
                )
                logging.info(f"📋 Histórico recarregado com status atualizados")
            
            context["assinaturas_historico"] = assinaturas_historico
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
        """
        Verifica se o usuário tem assinatura aguardando pagamento.
        Antes de retornar, verifica via API do Asaas se algum pagamento foi confirmado.
        """
        try:
            logging.info(f"🔍 Verificando assinaturas pendentes para usuário {self.request.user.id}")
            
            # Buscar assinaturas aguardando pagamento
            assinaturas_pendentes = AssinaturaUsuario.objects.filter(
                usuario=self.request.user, status="aguardando_pagamento"
            )
            
            if not assinaturas_pendentes.exists():
                logging.info(f"✅ Usuário {self.request.user.id} não tem assinaturas pendentes")
                return False
            
            logging.info(f"🔍 Encontradas {assinaturas_pendentes.count()} assinatura(s) pendente(s) para usuário {self.request.user.id}")
            
            # Verificar via API do Asaas se algum pagamento foi confirmado
            assinaturas_atualizadas = self.verificar_e_atualizar_pagamentos_pendentes(assinaturas_pendentes)
            
            # Recarregar do banco para ter certeza que temos os dados atualizados
            # Se todas as assinaturas foram atualizadas para "ativa", retornar False
            assinaturas_ainda_pendentes = AssinaturaUsuario.objects.filter(
                usuario=self.request.user, status="aguardando_pagamento"
            )
            
            if assinaturas_ainda_pendentes.exists():
                logging.info(f"⚠️ Ainda há {assinaturas_ainda_pendentes.count()} assinatura(s) pendente(s) para usuário {self.request.user.id}")
                return True
            else:
                logging.info(f"✅ Todas as assinaturas foram atualizadas! Não há mais pendentes para usuário {self.request.user.id}")
                return False
            
        except Exception as e:
            logging.error(
                f"❌ Erro ao verificar assinatura aguardando para usuário {self.request.user.id}: {e}",
                exc_info=True
            )
            # Em caso de erro, retornar o status atual do banco
            tem_pendentes = AssinaturaUsuario.objects.filter(
                usuario=self.request.user, status="aguardando_pagamento"
            ).exists()
            if tem_pendentes:
                logging.warning(f"⚠️ Retornando True devido a erro (há pendentes no banco)")
            return tem_pendentes
    
    def verificar_e_atualizar_pagamentos_pendentes(self, assinaturas):
        """
        Verifica via API do Asaas se os pagamentos das assinaturas foram confirmados
        e atualiza o status automaticamente.
        
        Args:
            assinaturas: QuerySet de AssinaturaUsuario com status "aguardando_pagamento"
        
        Returns:
            Lista de assinaturas que foram atualizadas
        """
        assinaturas_atualizadas = []
        
        try:
            from financeiro.services.asaas import AsaasClient, AsaasAPIError
            from financeiro.models import AsaasPayment
            
            # Verificar se Asaas está configurado (tem API key)
            from django.conf import settings
            asaas_api_key = getattr(settings, "ASAAS_API_KEY", None)
            if not asaas_api_key:
                logging.warning("⚠️ Asaas API key não configurada, pulando verificação de pagamentos")
                return assinaturas_atualizadas
            
            logging.info(f"🔍 Iniciando verificação de {assinaturas.count()} assinatura(s) pendente(s)")
            asaas_client = AsaasClient()
            
            for assinatura in assinaturas:
                logging.info(f"🔍 Verificando assinatura ID {assinatura.id}, status atual: {assinatura.status}")
                
                # Só verificar se tem payment_id
                if not assinatura.asaas_payment_id:
                    logging.warning(f"⚠️ Assinatura {assinatura.id} não tem asaas_payment_id, pulando verificação")
                    continue
                
                logging.info(f"🔍 Assinatura {assinatura.id} tem payment_id: {assinatura.asaas_payment_id}")
                
                try:
                    payment_status = None
                    
                    # Primeiro tentar buscar no banco local
                    try:
                        payment = AsaasPayment.objects.get(asaas_id=assinatura.asaas_payment_id)
                        payment_status = payment.status
                        logging.info(f"📦 Status encontrado no banco local: {payment_status} para payment_id {assinatura.asaas_payment_id}")
                    except AsaasPayment.DoesNotExist:
                        # Se não existe no banco, buscar na API
                        logging.info(f"📡 Payment_id {assinatura.asaas_payment_id} não encontrado no banco local, buscando na API...")
                        try:
                            payment_data = asaas_client.get_payment(assinatura.asaas_payment_id)
                            payment_status = payment_data.get("status", "UNKNOWN")
                            logging.info(f"📡 Status obtido da API: {payment_status} para payment_id {assinatura.asaas_payment_id}")
                            
                            # Salvar no banco local
                            AsaasPayment.objects.update_or_create(
                                asaas_id=assinatura.asaas_payment_id,
                                defaults={
                                    "customer_id": payment_data.get("customer", ""),
                                    "amount": payment_data.get("value", assinatura.valor_pago or 0),
                                    "billing_type": payment_data.get("billingType", "PIX"),
                                    "status": payment_status,
                                }
                            )
                            logging.info(f"💾 Dados do pagamento salvos no banco local")
                        except AsaasAPIError as e:
                            # Se erro 404, pagamento ainda não disponível ou não existe
                            if e.status_code == 404:
                                logging.warning(f"⚠️ Pagamento {assinatura.asaas_payment_id} retornou 404 na API (não encontrado ou ainda não disponível)")
                                continue
                            else:
                                logging.error(f"❌ Erro ao buscar pagamento {assinatura.asaas_payment_id} na API: {e.message} (status_code: {e.status_code})")
                                continue
                    
                    if not payment_status:
                        logging.warning(f"⚠️ Não foi possível obter status do pagamento {assinatura.asaas_payment_id}")
                        continue
                    
                    # Verificar se pagamento foi confirmado
                    status_confirmados = ["RECEIVED", "CONFIRMED", "RECEIVED_IN_CASH_UNDONE"]
                    if payment_status in status_confirmados:
                        logging.info(f"✅ Pagamento {assinatura.asaas_payment_id} confirmado! Status: {payment_status}")
                        
                        # Atualizar assinatura para "ativa"
                        if assinatura.status == "aguardando_pagamento":
                            # Recarregar do banco para garantir que temos a versão mais recente
                            assinatura.refresh_from_db()
                            
                            # Verificar novamente o status (pode ter sido atualizado por outro processo)
                            if assinatura.status == "aguardando_pagamento":
                                assinatura.status = "ativa"
                                
                                # Se data_inicio ainda não foi definida ou está no passado, definir como agora
                                if not assinatura.data_inicio or assinatura.data_inicio < timezone.now():
                                    assinatura.data_inicio = timezone.now()
                                
                                # Recalcular data_fim baseada na data_inicio atual
                                from datetime import timedelta
                                assinatura.data_fim = assinatura.data_inicio + timedelta(days=assinatura.plano.duracao_dias)
                                
                                assinatura.save()
                                assinaturas_atualizadas.append(assinatura)
                                
                                logging.info(
                                    f"✅✅✅ Assinatura {assinatura.id} ATUALIZADA para 'ativa' após verificação via API! "
                                    f"Payment ID: {assinatura.asaas_payment_id}, "
                                    f"Status pagamento: {payment_status}, "
                                    f"Data início: {assinatura.data_inicio}, "
                                    f"Data fim: {assinatura.data_fim}"
                                )
                            else:
                                logging.info(f"ℹ️ Assinatura {assinatura.id} já foi atualizada por outro processo, status atual: {assinatura.status}")
                        else:
                            logging.info(f"ℹ️ Assinatura {assinatura.id} já não está mais 'aguardando_pagamento', status atual: {assinatura.status}")
                    else:
                        logging.info(f"⏳ Pagamento {assinatura.asaas_payment_id} ainda não confirmado. Status atual: {payment_status}")
                    
                except Exception as e:
                    logging.error(
                        f"❌ Erro ao verificar pagamento {assinatura.asaas_payment_id} para assinatura {assinatura.id}: {e}",
                        exc_info=True
                    )
                    continue
            
            logging.info(f"✅ Verificação concluída. {len(assinaturas_atualizadas)} assinatura(s) atualizada(s)")
            
        except Exception as e:
            logging.error(
                f"❌ Erro geral ao verificar pagamentos pendentes via API Asaas: {e}",
                exc_info=True
            )
        
        return assinaturas_atualizadas


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
        assinatura_aguardando = (
            AssinaturaUsuario.objects.filter(
                usuario=usuario, status="aguardando_pagamento"
            )
            .order_by("-data_inicio")
            .first()
        )
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
        assinatura_ativa = (
            AssinaturaUsuario.objects.filter(usuario=usuario, status="ativa")
            .order_by("-data_fim")
            .first()
        )

        if (
            assinatura_ativa
            and assinatura_ativa.data_fim
            and assinatura_ativa.data_fim >= timezone.now()
        ):
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
        assinatura_ativa = (
            AssinaturaUsuario.objects.filter(usuario=request.user, status="ativa")
            .order_by("-data_fim")
            .first()
        )

        if (
            assinatura_ativa
            and assinatura_ativa.data_fim
            and assinatura_ativa.data_fim >= timezone.now()
        ):
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

        # Verificar se já existe assinatura aguardando pagamento
        assinatura_aguardando = AssinaturaUsuario.objects.filter(
            usuario=request.user, status="aguardando_pagamento"
        ).first()

        if assinatura_aguardando:
            # Redirecionar para a página de pagamento da assinatura pendente
            messages.warning(
                request,
                f"Você já possui uma assinatura aguardando pagamento. "
                f"Finalize o pagamento pendente antes de criar uma nova assinatura."
            )
            if metodo_pagamento == "pix":
                return redirect("authentication:payment_pix", assinatura_id=assinatura_aguardando.id)
            else:
                # Se for cartão, redirecionar para a seleção de planos ou mostrar erro
                messages.error(
                    request,
                    "Não é possível criar uma nova assinatura enquanto há uma aguardando pagamento."
                )
                return redirect("authentication:plan_selection")

        # Calcular valor baseado no método de pagamento
        if metodo_pagamento == "pix":
            valor = plano.preco_pix
        else:
            valor = plano.preco_cartao

        # Verificar se já existe assinatura ativa
        # Buscar a assinatura ativa com a data_fim mais recente que ainda não expirou
        assinatura_ativa = (
            AssinaturaUsuario.objects.filter(
                usuario=request.user, status="ativa"
            )
            .order_by("-data_fim")
            .first()
        )

        # Se já tem assinatura ativa e ainda não expirou,
        # começar nova assinatura no dia seguinte ao término da atual
        if (
            assinatura_ativa
            and assinatura_ativa.data_fim
            and assinatura_ativa.data_fim >= timezone.now()
        ):
            data_inicio = assinatura_ativa.data_fim + timedelta(days=1)
            logging.info(
                f"Nova assinatura será iniciada em {data_inicio.strftime('%Y-%m-%d')} "
                f"(1 dia após o término da assinatura atual que termina em {assinatura_ativa.data_fim.strftime('%Y-%m-%d')})"
            )
        else:
            data_inicio = timezone.now()
            if assinatura_ativa:
                logging.info(
                    f"Assinatura ativa encontrada mas já expirou ou sem data_fim. "
                    f"Nova assinatura será iniciada imediatamente."
                )

        # Criar assinatura com status aguardando_pagamento
        # Calcular data_fim baseada na data_inicio calculada
        data_fim = data_inicio + timedelta(days=plano.duracao_dias)

        # Criar assinatura (data_inicio será definida depois devido a auto_now_add=True)
        assinatura = AssinaturaUsuario.objects.create(
            usuario=request.user,
            plano=plano,
            data_fim=data_fim,
            status="aguardando_pagamento",
            valor_pago=valor,
            metodo_pagamento=metodo_pagamento,
        )
        
        # Atualizar data_inicio manualmente (já que tem auto_now_add=True)
        # Isso permite definir uma data futura se necessário
        if assinatura.data_inicio != data_inicio:
            AssinaturaUsuario.objects.filter(id=assinatura.id).update(data_inicio=data_inicio)
            # Recarregar o objeto para ter a data_inicio atualizada
            assinatura.refresh_from_db()
        
        logging.info(
            f"Assinatura criada: ID={assinatura.id}, "
            f"Início={assinatura.data_inicio.strftime('%Y-%m-%d %H:%M:%S')}, "
            f"Fim={assinatura.data_fim.strftime('%Y-%m-%d %H:%M:%S')}, "
            f"Plano={plano.nome}, "
            f"Status={assinatura.status}"
        )

        if metodo_pagamento == "pix":
            # Salvar dados de cobrança na sessão para usar na página de pagamento
            # O QR Code real será gerado na PaymentPixView, não aqui
            request.session["billing_data"] = billing_data
            request.session["cpf_temporario"] = billing_data.get("cpf", "")
            request.session["telefone_temporario"] = billing_data.get("telefone", "")
            request.session["assinatura_id"] = assinatura.id

            # NÃO gerar QR Code aqui - PaymentPixView fará a geração real via Asaas
            # Isso garante que sempre usaremos o payload real do Asaas, não mockado
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

    def dispatch(self, request, *args, **kwargs):
        """Verificar assinatura e CPF antes de processar"""
        assinatura_id = self.kwargs.get("assinatura_id")
        
        try:
            assinatura = AssinaturaUsuario.objects.get(
                id=assinatura_id, usuario=request.user
            )
            
            # Recuperar dados de cobrança da sessão ou usar dados do usuário
            billing_data = request.session.get("billing_data", {})
            
            # Se não houver dados na sessão, usar dados do usuário como fallback
            if not billing_data.get("cpf"):
                # Tentar buscar CPF do cliente se disponível
                from agendamentos.models import Cliente
                try:
                    cliente = Cliente.objects.filter(usuario=assinatura.usuario).first()
                    if cliente and cliente.cpf:
                        billing_data["cpf"] = cliente.cpf.replace(".", "").replace("-", "")
                except:
                    pass
            
            # Se ainda não tiver CPF, usar dados mínimos do usuário
            if not billing_data.get("cpf"):
                billing_data = {
                    "cpf": request.session.get("cpf_temporario", ""),
                    "nome_completo": assinatura.usuario.get_full_name()
                    or assinatura.usuario.username,
                    "email": assinatura.usuario.email or "",
                    "telefone": request.session.get("telefone_temporario", ""),
                }
            
            # Validar que temos CPF válido
            if not billing_data.get("cpf") or len(billing_data.get("cpf", "").replace(".", "").replace("-", "")) != 11:
                messages.error(
                    request,
                    "CPF não encontrado. Por favor, preencha os dados de cobrança novamente."
                )
                from django.shortcuts import redirect
                return redirect("authentication:checkout", plano_id=assinatura.plano.id)
                
        except AssinaturaUsuario.DoesNotExist:
            messages.error(request, "Assinatura não encontrada.")
            from django.shortcuts import redirect
            return redirect("authentication:plan_selection")
        
        return super().dispatch(request, *args, **kwargs)

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        assinatura_id = self.kwargs.get("assinatura_id")

        assinatura = AssinaturaUsuario.objects.get(
            id=assinatura_id, usuario=self.request.user
        )
        context["assinatura"] = assinatura

        # Recuperar dados de cobrança da sessão ou usar dados do usuário
        billing_data = self.request.session.get("billing_data", {})
        
        # Se não houver dados na sessão, usar dados do usuário como fallback
        if not billing_data.get("cpf"):
            # Tentar buscar CPF do cliente se disponível
            from agendamentos.models import Cliente
            try:
                cliente = Cliente.objects.filter(usuario=assinatura.usuario).first()
                if cliente and cliente.cpf:
                    billing_data["cpf"] = cliente.cpf.replace(".", "").replace("-", "")
            except:
                pass
        
        # Se ainda não tiver CPF, usar dados mínimos do usuário
        if not billing_data.get("cpf"):
            billing_data = {
                "cpf": self.request.session.get("cpf_temporario", ""),
                "nome_completo": assinatura.usuario.get_full_name()
                or assinatura.usuario.username,
                "email": assinatura.usuario.email or "",
                "telefone": self.request.session.get("telefone_temporario", ""),
            }
        
        # Gerar dados do PIX
        try:
            pix_data = self.gerar_qr_code_pix(
                assinatura.plano,
                assinatura.valor_pago,
                billing_data,
                assinatura,
            )
            context["pix_data"] = pix_data
        except Exception as e:
            # Se houver erro ao gerar QR Code, mostrar mensagem
            logging.error(f"Erro ao gerar QR Code na PaymentPixView: {e}", exc_info=True)
            from financeiro.services.asaas import AsaasAPIError
            
            if isinstance(e, AsaasAPIError):
                error_msg = e.message
                if e.response and e.response.get("errors"):
                    errors = e.response["errors"]
                    if isinstance(errors, list) and len(errors) > 0:
                        error_msg = errors[0].get("description", error_msg)
            else:
                error_msg = str(e)
            
            messages.error(
                self.request,
                f"Erro ao gerar QR Code: {error_msg}. Por favor, tente novamente."
            )
            
            # Retornar dados vazios para o template mostrar erro
            context["pix_data"] = {
                "payment_id": "",
                "qr_code": "",
                "qr_code_image": "",
                "valor": float(assinatura.valor_pago),
                "descricao": f"Pagamento - {assinatura.plano.nome}",
                "status": "ERRO",
                "pix_copia_cola": "",
                "erro": error_msg,
            }

        return context

    def gerar_qr_code_pix(self, plano, valor, billing_data, assinatura):
        """Gera dados para QR Code PIX usando API Asaas"""

        # Se já tem payment_id, buscar dados do Asaas novamente
        if assinatura.asaas_payment_id:
            logging.info(f"Usando payment_id existente: {assinatura.asaas_payment_id}")
            
            if ASAAS_AVAILABLE:
                try:
                    # Buscar dados atualizados do pagamento
                    asaas_client = AsaasClient()
                    payment_data = asaas_client.get_payment(assinatura.asaas_payment_id)
                    pix_data = asaas_client.get_pix_qr(assinatura.asaas_payment_id)
                    
                    # Verificar múltiplos campos possíveis para o payload
                    payload = (
                        pix_data.get("payload") or 
                        pix_data.get("copyPaste") or 
                        pix_data.get("pixCopiaECola") or
                        ""
                    )
                    
                    # Verificar múltiplos campos possíveis para a imagem do QR code
                    qr_code_image = (
                        pix_data.get("qrCode") or 
                        pix_data.get("encodedImage") or 
                        pix_data.get("qrCodeBase64") or
                        ""
                    )
                    
                    # Validar que o payload é válido (deve começar com 000201)
                    if payload:
                        if not payload.startswith("000201") or len(payload) < 50:
                            logging.error(f"❌ Payload inválido recebido do Asaas para pagamento existente: {payload[:100]}...")
                            raise Exception("Payload PIX inválido do Asaas")
                        
                        # SEMPRE gerar QR Code a partir do payload se disponível
                        try:
                            from financeiro.utils import generate_qr_code_from_payload
                            qr_code_gerado = generate_qr_code_from_payload(payload)
                            if qr_code_gerado:
                                qr_code_image = qr_code_gerado
                                logging.info(f"✅ QR Code regenerado a partir do payload REAL do Asaas")
                            else:
                                logging.warning("Função generate_qr_code_from_payload retornou None para payment_id existente")
                        except ImportError as e:
                            logging.error(f"Biblioteca qrcode não instalada: {e}")
                        except Exception as e:
                            logging.error(f"Erro ao gerar QR Code do payload existente: {e}", exc_info=True)
                    else:
                        # Se não tem payload, tentar obter novamente (pode ter ficado disponível)
                        from financeiro.services.asaas import AsaasAPIError
                        import time
                        
                        logging.info("Payload não disponível, tentando obter novamente...")
                        # Quando já existe payment_id, tentar mais vezes (pode ter ficado disponível)
                        for retry in range(6):  # Aumentado de 3 para 6 tentativas
                            try:
                                time.sleep(3)  # Aguardar 3 segundos entre tentativas
                                pix_data_retry = asaas_client.get_pix_qr(assinatura.asaas_payment_id)
                                payload = pix_data_retry.get("payload", "")
                                if payload:
                                    logging.info(f"✅ Payload obtido na tentativa {retry + 1}")
                                    break
                            except AsaasAPIError as e:
                                if e.status_code == 404:
                                    logging.info(f"QR Code ainda não disponível (tentativa {retry + 1}/6)")
                                    continue
                                else:
                                    raise
                        
                        if not payload:
                            # Não bloquear - permitir que página seja exibida com mensagem de aguardo
                            logging.warning(f"QR Code ainda não disponível após recarregar. Payment ID: {assinatura.asaas_payment_id}")
                            return {
                                "payment_id": assinatura.asaas_payment_id,
                                "qr_code": "",
                                "qr_code_image": "",
                                "chave_pix": "",
                                "valor": float(valor),
                                "descricao": f"Pagamento - {plano.nome}",
                                "vencimento": payment_data.get("dueDate", ""),
                                "status": traduzir_status_asaas(payment_data.get("status", "PENDING")),
                                "pix_copia_cola": "",  # Vazio porque ainda não está disponível
                                "qr_code_aguardando": True,
                                "payment_id_asaas": assinatura.asaas_payment_id,
                                "payment_info": f"ID do Pagamento: {assinatura.asaas_payment_id}",  # Para mostrar ao usuário
                            }
                    
                    # Extrair data de vencimento do pagamento
                    due_date = payment_data.get("dueDate", "")
                    
                    status_en = payment_data.get("status", "PENDING")
                    return {
                        "payment_id": assinatura.asaas_payment_id,
                        "qr_code": payload,
                        "qr_code_image": qr_code_image or "",
                        "chave_pix": payload,
                        "valor": float(valor),
                        "descricao": f"Pagamento - {plano.nome}",
                        "vencimento": due_date,
                        "status": traduzir_status_asaas(status_en),
                        "pix_copia_cola": payload,
                    }
                except Exception as e:
                    # Se houver erro ao buscar dados (ex: QR Code ainda não disponível), não criar novo pagamento
                    # Retornar dados de aguardo para permitir que usuário recarregue
                    from financeiro.services.asaas import AsaasAPIError
                    
                    if isinstance(e, AsaasAPIError) and e.status_code == 404:
                        logging.info(f"QR Code ainda não disponível ao recarregar. Payment ID: {assinatura.asaas_payment_id}")
                    else:
                        logging.warning(f"Erro ao buscar dados do Asaas: {e}")
                    
                    # Retornar dados de aguardo em vez de criar novo pagamento
                    return {
                        "payment_id": assinatura.asaas_payment_id or "",
                        "qr_code": "",
                        "qr_code_image": "",
                        "chave_pix": "",
                        "valor": float(valor),
                        "descricao": f"Pagamento - {plano.nome}",
                        "vencimento": "",
                        "status": traduzir_status_asaas("PENDING"),
                        "pix_copia_cola": "",
                        "qr_code_aguardando": True,
                        "payment_id_asaas": assinatura.asaas_payment_id or "",
                    }
            
            # Fallback se não conseguir buscar dados
            return {
                "payment_id": assinatura.asaas_payment_id,
                "qr_code": "",
                "qr_code_image": "",
                "chave_pix": "",
                "valor": float(valor),
                "descricao": f"Pagamento - {plano.nome}",
                "vencimento": "",
                "status": traduzir_status_asaas("PENDING"),
                "pix_copia_cola": "",
            }

        if not ASAAS_AVAILABLE:
            raise RuntimeError("Serviço de pagamento Asaas não está configurado")

        try:
            # Inicializar cliente Asaas
            asaas_client = AsaasClient()

            # Limpar e validar CPF antes de enviar ao Asaas
            cpf_limpo = billing_data.get("cpf", "").replace(".", "").replace("-", "").replace("/", "").strip()
            
            # Validar que o CPF tem 11 dígitos
            if not cpf_limpo or len(cpf_limpo) != 11 or not cpf_limpo.isdigit():
                raise ValueError(
                    f"CPF inválido: '{billing_data.get('cpf', '')}'. "
                    f"O CPF deve ter 11 dígitos numéricos."
                )
            
            # Validar dados antes de enviar ao Asaas
            nome_completo = billing_data.get("nome_completo", "").strip()
            email = billing_data.get("email", "").strip()
            
            if not nome_completo:
                raise ValueError("Nome completo é obrigatório")
            if not email or "@" not in email:
                raise ValueError("Email válido é obrigatório")
            
            # Limpar telefone
            telefone_limpo = billing_data.get("telefone", "").replace("(", "").replace(")", "").replace("-", "").replace(" ", "").strip()
            
            logging.info(f"Criando cliente no Asaas:")
            logging.info(f"   Nome: {nome_completo}")
            logging.info(f"   Email: {email}")
            logging.info(f"   CPF: {cpf_limpo[:3]}***{cpf_limpo[-2:]}")
            logging.info(f"   Telefone: {telefone_limpo if telefone_limpo else 'Não informado'}")
            
            # Criar cliente no Asaas
            try:
                customer_data = asaas_client.create_customer(
                    name=nome_completo,
                    email=email,
                    cpf_cnpj=cpf_limpo,
                    phone=telefone_limpo if telefone_limpo else None,
                )
                logging.info(f"✅ Cliente criado no Asaas: {customer_data.get('id')}")
            except Exception as customer_error:
                logging.error(f"❌ Erro ao criar cliente no Asaas: {customer_error}")
                # Re-raise para ser capturado pelo except externo com tratamento apropriado
                raise

            # Criar cobrança PIX
            due_date = (timezone.now() + timedelta(days=1)).strftime("%Y-%m-%d")
            
            # Validar valor
            if valor <= 0:
                raise ValueError(f"Valor inválido: {valor}. O valor deve ser maior que zero.")
            
            logging.info(f"Criando pagamento PIX no Asaas:")
            logging.info(f"   Customer ID: {customer_data.get('id')}")
            logging.info(f"   Valor: R$ {valor:.2f}")
            logging.info(f"   Vencimento: {due_date}")
            logging.info(f"   Descrição: Pagamento - {plano.nome}")

            try:
                # Criar pagamento com external_reference para vincular à assinatura
                payment_data = asaas_client.create_payment(
                    customer_id=customer_data["id"],
                    value=float(valor),
                    due_date=due_date,
                    billing_type="PIX",
                    description=f"Pagamento - {plano.nome}",
                    external_reference=f"assinatura_{assinatura.id}",  # Vincular à assinatura
                )
                logging.info(f"✅ Pagamento criado no Asaas: {payment_data.get('id')}")
                logging.info(f"   Status: {payment_data.get('status')}")
                logging.info(f"   Valor: R$ {payment_data.get('value')}")
                logging.info(f"   Tipo de Cobrança: {payment_data.get('billingType')}")
                
                # Validar que o pagamento foi criado como PIX
                if payment_data.get('billingType') != 'PIX':
                    logging.warning(f"⚠️ ATENÇÃO: Pagamento criado com tipo '{payment_data.get('billingType')}' em vez de 'PIX'")
            except Exception as payment_error:
                logging.error(f"❌ Erro ao criar pagamento no Asaas: {payment_error}")
                # Re-raise para ser capturado pelo except externo
                raise

            # Aguardar um pouco antes de começar a buscar o QR Code (pode levar alguns segundos)
            import time
            logging.info("Aguardando 1 segundo antes de começar a buscar QR Code...")
            time.sleep(1)  # Reduzido de 2s para 1s
            
            # Obter QR Code PIX - pode levar alguns segundos para ficar disponível
            # TIMEOUT OTIMIZADO: Tentar 5 vezes com intervalo de 3 segundos (total: ~15 segundos)
            # Se não conseguir em 15s, retornar página para usuário recarregar (QR code pode ainda estar sendo gerado)
            from financeiro.services.asaas import AsaasAPIError
            
            pix_data = None
            payload = ""
            max_tentativas = 5  # Aumentado para 5 tentativas (melhor chance de obter QR code)
            max_wait_seconds = 15  # Timeout aumentado para 15 segundos
            tentativa = 0
            start_time = time.time()
            
            logging.info(f"Aguardando QR Code PIX ficar disponível para pagamento {payment_data['id']}...")
            logging.info(f"Configuração: até {max_tentativas} tentativas, máximo {max_wait_seconds}s")
            
            while (tentativa < max_tentativas) and (time.time() - start_time < max_wait_seconds) and not payload:
                tentativa += 1
                elapsed = time.time() - start_time
                
                # Log de progresso a cada tentativa
                logging.info(f"Tentativa {tentativa}/{max_tentativas} - Tempo decorrido: {elapsed:.1f}s/{max_wait_seconds}s")
                
                try:
                    pix_data = asaas_client.get_pix_qr(payment_data["id"])
                    logging.info(f"✅ Tentativa {tentativa}: Dados retornados do Asaas get_pix_qr: {list(pix_data.keys())}")
                    
                    # Verificar múltiplos campos possíveis para o payload
                    payload = (
                        pix_data.get("payload") or 
                        pix_data.get("copyPaste") or 
                        pix_data.get("pixCopiaECola") or
                        ""
                    )
                    
                    if payload:
                        logging.info(f"✅ Payload obtido com sucesso na tentativa {tentativa} (após {elapsed:.1f}s)")
                        logging.info(f"   Tamanho do payload: {len(payload)} caracteres")
                        break
                    else:
                        logging.warning(f"⚠️ Payload vazio na tentativa {tentativa}, aguardando... (elapsed: {elapsed:.1f}s)")
                        logging.warning(f"   Chaves disponíveis no pix_data: {list(pix_data.keys())}")
                        if tentativa < max_tentativas and (time.time() - start_time < max_wait_seconds):
                            time.sleep(3)  # Aguardar 3 segundos antes de tentar novamente
                            
                except AsaasAPIError as e:
                    # Se for erro 404, o QR Code ainda não está disponível - continuar tentando
                    if e.status_code == 404:
                        logging.info(f"⚠️ Tentativa {tentativa}: QR Code ainda não disponível (404) - aguardando... (elapsed: {elapsed:.1f}s)")
                        if tentativa < max_tentativas and (time.time() - start_time < max_wait_seconds):
                            time.sleep(3)  # Aguardar 3 segundos antes de tentar novamente
                            continue
                        else:
                            # Timeout atingido - não bloquear, permitir que usuário recarregue a página
                            elapsed = time.time() - start_time
                            logging.warning(
                                f"⚠️ QR Code não ficou disponível após {elapsed:.1f}s ({tentativa} tentativas). "
                                f"Pagamento criado: {payment_data['id']}. Permitindo acesso à página para recarregar."
                            )
                            # Não levantar exceção - permitir que a página seja exibida
                            break
                    else:
                        # Outro erro (não é 404) - relançar
                        logging.error(f"❌ Erro ao obter QR Code na tentativa {tentativa}: {e.message} (status: {e.status_code})")
                        raise
                        
                except Exception as e:
                    logging.warning(f"Erro inesperado ao obter QR Code na tentativa {tentativa}: {e}")
                    if tentativa < max_tentativas and (time.time() - start_time < max_wait_seconds):
                        time.sleep(3)  # Aguardar 3 segundos antes de tentar novamente
                    else:
                        raise Exception(
                            f"Erro ao obter QR Code PIX após {elapsed:.1f} segundos: {str(e)}. "
                            f"O pagamento foi criado com sucesso (ID: {payment_data['id']}). "
                            f"Tente recarregar a página em alguns instantes."
                        )
            
            # Se não conseguiu obter QR Code, permitir que a página seja exibida mesmo assim
            # O usuário pode recarregar a página para tentar novamente
            if not pix_data or not payload:
                elapsed = time.time() - start_time
                logging.warning(
                    f"⚠️ QR Code não disponível após {elapsed:.1f}s. "
                    f"Pagamento criado: {payment_data['id']}. "
                    f"Retornando dados vazios para permitir recarregamento da página."
                )
                
                # Salvar payment_id na assinatura para que possa tentar novamente ao recarregar
                assinatura.asaas_payment_id = payment_data["id"]
                assinatura.save()
                logging.info(f"✅ Payment ID salvo na assinatura: {payment_data['id']}")
                
                # Retornar dados com payment_id para que possa tentar novamente
                # IMPORTANTE: Se não conseguiu o payload em 10s, ainda pode estar sendo gerado
                # O usuário pode recarregar a página para tentar novamente
                return {
                    "payment_id": payment_data["id"],
                    "qr_code": "",
                    "qr_code_image": "",
                    "chave_pix": "",
                    "valor": float(valor),
                    "descricao": f"Pagamento - {plano.nome}",
                    "vencimento": due_date,
                    "status": traduzir_status_asaas(payment_data.get("status", "PENDING")),
                    "pix_copia_cola": "",  # Vazio porque ainda não está disponível
                    "qr_code_aguardando": True,  # Flag para indicar que está aguardando
                    "payment_id_asaas": payment_data["id"],  # Para tentar novamente
                    "payment_info": f"ID do Pagamento: {payment_data['id']}",  # Para mostrar ao usuário
                    "mensagem_aguardo": "O código PIX está sendo gerado. Aguarde alguns segundos e recarregue a página.",
                }
            
            # Verificar múltiplos campos possíveis para a imagem do QR code
            qr_code_image = (
                pix_data.get("qrCode") or 
                pix_data.get("encodedImage") or 
                pix_data.get("qrCodeBase64") or
                ""
            )
            
            logging.info(f"Payload recebido: SIM (tamanho: {len(payload)})")
            logging.info(f"QR Code do Asaas (imagem): {'SIM' if qr_code_image else 'NÃO (será gerado localmente)'}")
            logging.info(f"Chaves disponíveis no pix_data: {list(pix_data.keys())}")
            
            # Validar que o payload parece ser um payload PIX válido
            if not payload.startswith("000201") or len(payload) < 50:
                raise Exception(f"Payload PIX inválido recebido do Asaas. Payload: {payload[:100]}...")
            
            logging.info(f"✅ Payload PIX válido confirmado (inicia com '000201')")
            
            # SEMPRE gerar QR Code a partir do payload se disponível
            # Isso garante que sempre teremos um QR Code válido para pagamento
            if payload:
                try:
                    from financeiro.utils import generate_qr_code_from_payload
                    logging.info("Tentando gerar QR Code a partir do payload...")
                    qr_code_gerado = generate_qr_code_from_payload(payload)
                    if qr_code_gerado:
                        qr_code_image = qr_code_gerado
                        logging.info(f"✅ QR Code gerado com sucesso! Tamanho: {len(qr_code_gerado)} caracteres")
                    else:
                        logging.error("❌ Função generate_qr_code_from_payload retornou None")
                except ImportError as e:
                    logging.error(f"❌ Biblioteca qrcode não instalada: {e}")
                    logging.error("Execute: pip install qrcode[pil]")
                except Exception as e:
                    logging.error(f"❌ Erro ao gerar QR Code do payload: {e}", exc_info=True)
            else:
                logging.error("❌ Payload não disponível! Não é possível gerar QR Code")
                logging.error(f"Dados completos do pix_data: {pix_data}")
            
            # Validação final
            if not qr_code_image:
                logging.error(f"❌ CRÍTICO: QR Code não disponível após todas as tentativas!")
                logging.error(f"   - Payload presente: {bool(payload)}")
                logging.error(f"   - Payload: {payload[:100] if payload else 'N/A'}...")
                logging.error(f"   - Chaves do pix_data: {list(pix_data.keys())}")
            else:
                logging.info(f"✅ QR Code disponível para exibição (tamanho: {len(qr_code_image)} caracteres)")

            # Salvar payment_id na assinatura
            assinatura.asaas_payment_id = payment_data["id"]
            assinatura.save()
            
            # Salvar também no banco de dados (AsaasPayment) para persistência
            try:
                from financeiro.models import AsaasPayment
                payment_db, created = AsaasPayment.objects.get_or_create(
                    asaas_id=payment_data["id"],
                    defaults={
                        "customer_id": customer_data["id"],
                        "amount": valor,
                        "billing_type": "PIX",
                        "status": payment_data.get("status", "PENDING"),
                        "qr_code_base64": qr_code_image,
                        "copy_paste_payload": payload,
                    }
                )
                if not created:
                    # Atualizar se já existir
                    payment_db.qr_code_base64 = qr_code_image
                    payment_db.copy_paste_payload = payload
                    payment_db.status = payment_data.get("status", "PENDING")
                    payment_db.save()
                logging.info(f"Pagamento salvo no banco: {payment_db.asaas_id}")
            except Exception as e:
                logging.warning(f"Erro ao salvar pagamento no banco: {e}")

            status_en = payment_data.get("status", "PENDING")
            
            # ÚLTIMA TENTATIVA: Se ainda não tiver QR Code mas tem payload, FORÇAR geração
            if not qr_code_image and payload:
                logging.warning("⚠️ QR Code não gerado, tentando novamente...")
                try:
                    from financeiro.utils import generate_qr_code_from_payload
                    qr_code_image = generate_qr_code_from_payload(payload, size=12)  # Tamanho maior
                    if qr_code_image:
                        logging.info(f"✅ QR Code gerado na última tentativa! Tamanho: {len(qr_code_image)}")
                    else:
                        logging.error("❌ Falha na última tentativa de gerar QR Code")
                except Exception as e:
                    logging.error(f"❌ Erro na última tentativa: {e}", exc_info=True)
            
            # Validação final antes de retornar
            if not qr_code_image:
                logging.error("❌ CRÍTICO: QR Code não disponível após todas as tentativas!")
                logging.error(f"   - Payload presente: {bool(payload)}")
                logging.error(f"   - Payload: {payload[:100] if payload else 'N/A'}...")
            else:
                logging.info(f"✅ CONFIRMADO: QR Code pronto para exibição (tamanho: {len(qr_code_image)} caracteres)")
            
            return {
                "payment_id": payment_data["id"],
                "qr_code": payload,
                "qr_code_image": qr_code_image or "",
                "chave_pix": payload,
                "valor": float(valor),
                "descricao": f"Pagamento - {plano.nome}",
                "vencimento": due_date,
                "status": traduzir_status_asaas(status_en),
                "pix_copia_cola": payload,
            }

        except Exception as e:
            logging.error(f"Erro ao gerar PIX via Asaas: {str(e)}", exc_info=True)
            
            # Extrair mensagem de erro específica do Asaas se disponível
            from financeiro.services.asaas import AsaasAPIError
            
            error_message = str(e)
            error_details = ""
            
            # Se for erro da API Asaas, extrair detalhes
            if isinstance(e, AsaasAPIError):
                error_message = e.message
                if e.response:
                    # Tentar extrair mensagens de erro específicas do Asaas
                    errors = e.response.get("errors", [])
                    if errors:
                        error_details = "; ".join([err.get("description", "") for err in errors if isinstance(err, dict)])
                        error_message = error_details or error_message
                    else:
                        error_message = e.response.get("message", e.message)
                logging.error(f"Detalhes do erro Asaas: {e.response}")
            
            # Mensagens de erro mais específicas para o usuário
            if "CPF" in error_message.upper() or "cpf" in error_message.lower() or "invalid_object" in error_message.lower():
                user_message = "Erro: CPF inválido. Por favor, verifique o CPF informado e tente novamente."
            elif "email" in error_message.lower():
                user_message = "Erro: Email inválido. Por favor, verifique o email informado."
            elif "name" in error_message.lower() or "nome" in error_message.lower():
                user_message = "Erro: Nome obrigatório. Por favor, preencha o nome completo."
            elif "value" in error_message.lower() or "valor" in error_message.lower():
                user_message = "Erro: Valor inválido. Por favor, verifique o valor do plano."
            elif "customer" in error_message.lower() or "cliente" in error_message.lower():
                user_message = "Erro ao criar cliente. Verifique os dados informados e tente novamente."
            else:
                # Mensagem genérica mas com detalhes do erro
                user_message = f"Erro ao processar pagamento: {error_message}. Por favor, verifique os dados e tente novamente."
            
            messages.error(self.request, user_message)
            
            # Log detalhado para debug
            logging.error(f"Mensagem de erro para usuário: {user_message}")
            logging.error(f"Erro completo: {error_message}")
            
            # Retornar dados vazios - não usar payload mockado
            return {
                "payment_id": "",
                "qr_code": "",
                "qr_code_image": "",
                "chave_pix": "",
                "valor": float(valor),
                "descricao": f"Pagamento - {plano.nome}",
                "vencimento": "",
                "status": "ERRO",
                "pix_copia_cola": "",
                "erro": error_message,
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


@login_required
def check_payment_status(request, assinatura_id):
    """
    Endpoint AJAX para verificar status do pagamento de uma assinatura.
    Retorna status atual da assinatura e do pagamento.
    """
    try:
        assinatura = AssinaturaUsuario.objects.get(
            id=assinatura_id, usuario=request.user
        )
        
        response_data = {
            "status": "success",
            "assinatura_status": assinatura.status,
            "payment_id": assinatura.asaas_payment_id,
            "pagamento_confirmado": False,
        }
        
        # Se já está ativa, pagamento foi confirmado
        if assinatura.status == "ativa":
            response_data["pagamento_confirmado"] = True
            response_data["message"] = "Pagamento confirmado! Sua assinatura está ativa."
            response_data["data_inicio"] = assinatura.data_inicio.isoformat() if assinatura.data_inicio else None
            response_data["data_fim"] = assinatura.data_fim.isoformat() if assinatura.data_fim else None
            return JsonResponse(response_data)
        
        # Se tem payment_id, verificar status no Asaas
        if assinatura.asaas_payment_id:
            try:
                from financeiro.services.asaas import AsaasClient, AsaasAPIError
                from financeiro.models import AsaasPayment
                
                # Primeiro tentar buscar no banco local
                try:
                    payment = AsaasPayment.objects.get(asaas_id=assinatura.asaas_payment_id)
                    if payment.status in ["RECEIVED", "CONFIRMED", "RECEIVED_IN_CASH_UNDONE"]:
                        # Pagamento confirmado - atualizar assinatura
                        if assinatura.status == "aguardando_pagamento":
                            assinatura.status = "ativa"
                            from django.utils import timezone
                            from datetime import timedelta
                            if not assinatura.data_inicio or assinatura.data_inicio < timezone.now():
                                assinatura.data_inicio = timezone.now()
                            assinatura.data_fim = assinatura.data_inicio + timedelta(days=assinatura.plano.duracao_dias)
                            assinatura.save()
                            logging.info(f"✅ Assinatura {assinatura.id} atualizada para 'ativa' via verificação AJAX")
                        
                        response_data["pagamento_confirmado"] = True
                        response_data["assinatura_status"] = assinatura.status
                        response_data["message"] = "Pagamento confirmado! Sua assinatura está ativa."
                        response_data["data_inicio"] = assinatura.data_inicio.isoformat() if assinatura.data_inicio else None
                        response_data["data_fim"] = assinatura.data_fim.isoformat() if assinatura.data_fim else None
                        return JsonResponse(response_data)
                    else:
                        response_data["payment_status"] = payment.status
                        response_data["message"] = f"Pagamento ainda não confirmado. Status: {payment.status}"
                except AsaasPayment.DoesNotExist:
                    # Se não existe no banco, buscar na API
                    try:
                        client = AsaasClient()
                        payment_data = client.get_payment(assinatura.asaas_payment_id)
                        payment_status = payment_data.get("status", "UNKNOWN")
                        
                        # Salvar no banco local
                        from financeiro.models import AsaasPayment
                        AsaasPayment.objects.update_or_create(
                            asaas_id=assinatura.asaas_payment_id,
                            defaults={
                                "customer_id": payment_data.get("customer", ""),
                                "amount": payment_data.get("value", assinatura.valor_pago or 0),
                                "billing_type": payment_data.get("billingType", "PIX"),
                                "status": payment_status,
                            }
                        )
                        
                        if payment_status in ["RECEIVED", "CONFIRMED", "RECEIVED_IN_CASH_UNDONE"]:
                            # Pagamento confirmado - atualizar assinatura
                            if assinatura.status == "aguardando_pagamento":
                                assinatura.status = "ativa"
                                from django.utils import timezone
                                from datetime import timedelta
                                if not assinatura.data_inicio or assinatura.data_inicio < timezone.now():
                                    assinatura.data_inicio = timezone.now()
                                assinatura.data_fim = assinatura.data_inicio + timedelta(days=assinatura.plano.duracao_dias)
                                assinatura.save()
                                logging.info(f"✅ Assinatura {assinatura.id} atualizada para 'ativa' via verificação AJAX (API)")
                            
                            response_data["pagamento_confirmado"] = True
                            response_data["assinatura_status"] = assinatura.status
                            response_data["message"] = "Pagamento confirmado! Sua assinatura está ativa."
                            response_data["data_inicio"] = assinatura.data_inicio.isoformat() if assinatura.data_inicio else None
                            response_data["data_fim"] = assinatura.data_fim.isoformat() if assinatura.data_fim else None
                            return JsonResponse(response_data)
                        else:
                            response_data["payment_status"] = payment_status
                            response_data["message"] = f"Pagamento ainda não confirmado. Status: {payment_status}"
                    except AsaasAPIError as e:
                        response_data["status"] = "error"
                        response_data["message"] = f"Erro ao verificar pagamento: {e.message}"
                        return JsonResponse(response_data, status=500)
            except Exception as e:
                logging.error(f"Erro ao verificar pagamento: {e}", exc_info=True)
                response_data["status"] = "error"
                response_data["message"] = f"Erro ao verificar pagamento: {str(e)}"
                return JsonResponse(response_data, status=500)
        else:
            response_data["message"] = "Aguardando criação do pagamento..."
        
        return JsonResponse(response_data)
        
    except AssinaturaUsuario.DoesNotExist:
        return JsonResponse(
            {"status": "error", "message": "Assinatura não encontrada"},
            status=404
        )
    except Exception as e:
        logging.error(f"Erro ao verificar status do pagamento: {e}", exc_info=True)
        return JsonResponse(
            {"status": "error", "message": f"Erro interno: {str(e)}"},
            status=500
        )
