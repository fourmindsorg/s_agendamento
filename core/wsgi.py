"""
WSGI config for core project.

It exposes the WSGI callable as a module-level variable named ``application``.

For more information on this file, see
https://docs.djangoproject.com/en/5.2/howto/deployment/wsgi/
"""

import os
from django.core.wsgi import get_wsgi_application

# Usar settings de desenvolvimento por padrão
# Pode ser sobrescrito pela variável de ambiente DJANGO_SETTINGS_MODULE
# Para produção, configure via systemd: Environment=DJANGO_SETTINGS_MODULE=core.settings_production
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "core.settings")

application = get_wsgi_application()
