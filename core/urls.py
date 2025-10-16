from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt


@csrf_exempt
def health_check(request):
    """Health check endpoint para monitoramento AWS"""
    return JsonResponse(
        {"status": "ok", "service": "sistema-agendamento", "version": "1.0.0"}
    )


urlpatterns = [
    path("health/", health_check, name="health_check"),  # Health check endpoint
    path("admin/", admin.site.urls),
    path("auth/", include("authentication.urls")),  # URLs de autenticação
    path("info/", include("info.urls")),
    path("financeiro/", include("financeiro.urls")),  # URLs do financeiro
    path("", include("agendamentos.urls")),
]

# Servir arquivos de media e estáticos
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
else:
    # Em produção, também servir arquivos estáticos via Django
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
