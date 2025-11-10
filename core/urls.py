from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.http import JsonResponse
from django.shortcuts import redirect
from django.urls import include, path
from django.views.decorators.csrf import csrf_exempt

from .admin_views import (
    CustomAdminLoginView,
    custom_admin_dashboard,
    user_activity_dashboard,
)


@csrf_exempt
def health_check(request):
    """Health check endpoint para monitoramento AWS"""
    return JsonResponse(
        {"status": "ok", "service": "sistema-agendamento", "version": "1.0.0"}
    )


urlpatterns = [
    path("health/", health_check, name="health_check"),  # Health check endpoint
    path("admin/login/", CustomAdminLoginView.as_view(), name="admin_login"),  # Login personalizado
    path(
        "admin/dashboard/",
        custom_admin_dashboard,
        name="admin_dashboard",
    ),
    path(
        "admin/user-activity/",
        user_activity_dashboard,
        name="admin_user_activity",
    ),
    path("admin/", admin.site.urls),
    path("authentication/", include("authentication.urls")),  # URLs de autenticação
    path("info/", include("info.urls")),
    path("financeiro/", include("financeiro.urls")),  # URLs do financeiro
    path("s_agendamentos/", include("agendamentos.urls")),  # URLs do sistema de agendamentos
    path("", lambda request: redirect('/s_agendamentos/'), name="home_redirect"),  # Redirecionar raiz para s_agendamentos
]

# Servir arquivos de media e estáticos
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
else:
    # Em produção, também servir arquivos estáticos via Django
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
