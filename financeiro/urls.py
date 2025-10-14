from django.urls import path
from . import views

app_name = 'financeiro'

urlpatterns = [
    path('gerar-pix/', views.create_pix_charge, name='create_pix_charge'),
    path('<str:payment_id>/qr/', views.pix_qr_view, name='pix_qr_view'),
    path('webhooks/asaas/', views.asaas_webhook, name='asaas_webhook'),
]
