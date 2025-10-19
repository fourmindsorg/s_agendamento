"""
Configuração do pytest para o projeto
"""
import os
import django
from django.conf import settings

# Configurar Django para testes
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')

def pytest_configure():
    """Configurações do pytest antes dos testes"""
    # Garantir que o EMAIL_BACKEND seja locmem para testes
    from django.conf import settings
    settings.EMAIL_BACKEND = 'django.core.mail.backends.locmem.EmailBackend'

