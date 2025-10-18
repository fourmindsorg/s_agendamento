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
from .forms import CustomUserCreationForm, CustomUserChangeForm
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
        messages.success(
            self.request,
            f"Bem-vindo, {form.get_user().first_name or form.get_user().username}!",
        )
        return super().form_valid(form)


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
                    usuario=user,
                    tema='claro',
                    modo='normal'
                )
            except Exception as e:
                logging.warning(f"Erro ao criar preferências para usuário {user.username}: {e}")
            
            messages.success(
                self.request,
                f"Bem-vindo, {user.first_name or user.username}! Agora escolha seu plano.",
            )
            return super().form_valid(form)
            
        except IntegrityError as e:
            logging.error(f"Erro de integridade ao criar usuário: {e}")
            messages.error(
                self.request,
                "Erro interno do sistema. Tente novamente ou entre em contato com o suporte."
            )
            return self.form_invalid(form)
            
        except ValidationError as e:
            logging.error(f"Erro de validação ao criar usuário: {e}")
            messages.error(
                self.request,
                "Dados inválidos. Verifique as informações e tente novamente."
            )
            return self.form_invalid(form)
            
        except Exception as e:
            logging.error(f"Erro inesperado ao criar usuário: {e}")
            messages.error(
                self.request,
                "Ocorreu um erro inesperado. Tente novamente ou entre em contato com o suporte."
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
                self.request,
                "Por favor, corrija os erros abaixo e tente novamente."
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
        return context


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
