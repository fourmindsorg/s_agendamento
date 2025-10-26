# Custom Admin Views
from django.contrib.admin.views.decorators import staff_member_required
from django.contrib.auth import authenticate, login
from django.contrib.auth.views import LoginView
from django.shortcuts import render, redirect
from django.contrib import messages
from django.views.decorators.csrf import csrf_protect
from django.utils.decorators import method_decorator


@method_decorator(csrf_protect, name='dispatch')
class CustomAdminLoginView(LoginView):
    """View personalizada para login do admin com template customizado"""
    template_name = 'admin/login.html'
    
    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['site_title'] = 'Admin Django'
        context['site_header'] = 'Sistema de Agendamento - 4Minds'
        return context
    
    def form_valid(self, form):
        """Override para adicionar mensagens personalizadas"""
        response = super().form_valid(form)
        messages.success(self.request, 'Login realizado com sucesso!')
        return response
    
    def form_invalid(self, form):
        """Override para mensagens de erro personalizadas"""
        messages.error(self.request, 'Usuário ou senha incorretos. Tente novamente.')
        return super().form_invalid(form)


@staff_member_required
def custom_admin_dashboard(request):
    """Dashboard personalizado para admin"""
    return render(request, 'admin/dashboard.html', {
        'site_title': 'Admin Dashboard',
        'site_header': 'Sistema de Agendamento - 4Minds'
    })
