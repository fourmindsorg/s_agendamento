import os
from pathlib import Path
from .settings import *

# Carregar variáveis de ambiente do arquivo .env
try:
    from dotenv import load_dotenv

    load_dotenv()
except ImportError:
    pass

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = os.environ.get(
    "SECRET_KEY", "django-insecure-66zn5&gupp_qti161gwv@t5z1@h=vq5^o%mjf+*3e!l*ut&v(a"
)

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = os.environ.get("DEBUG", "False").lower() == "true"

# Hosts permitidos para produção
ALLOWED_HOSTS = [
    "localhost",
    "127.0.0.1",
    "0.0.0.0",
    "fourmindstech.com.br",
]

# Adicionar hosts da variável de ambiente
env_hosts = os.environ.get("ALLOWED_HOSTS", "")
if env_hosts:
    ALLOWED_HOSTS.extend(
        [host.strip() for host in env_hosts.split(",") if host.strip()]
    )

# Database - PostgreSQL para produção
DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": os.environ.get("DB_NAME", "agendamentos_db"),
        "USER": os.environ.get("DB_USER", "postgres"),
        "PASSWORD": os.environ.get("DB_PASSWORD", ""),
        "HOST": os.environ.get("DB_HOST", "localhost"),
        "PORT": os.environ.get("DB_PORT", "5432"),
    }
}

# Static files (CSS, JavaScript, Images)
STATIC_URL = "/static/"
STATIC_ROOT = os.path.join(BASE_DIR, "staticfiles")

# Verificar se o diretório static existe antes de adicionar
static_dir = os.path.join(BASE_DIR, "static")
if os.path.exists(static_dir):
    STATICFILES_DIRS = [static_dir]
else:
    STATICFILES_DIRS = []

# Media files
MEDIA_URL = "/media/"
MEDIA_ROOT = os.path.join(BASE_DIR, "media")

# Security settings para produção
SECURE_BROWSER_XSS_FILTER = True
SECURE_CONTENT_TYPE_NOSNIFF = True
X_FRAME_OPTIONS = "DENY"
SECURE_HSTS_SECONDS = 31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True

# HTTPS settings
SECURE_SSL_REDIRECT = os.environ.get("HTTPS_REDIRECT", "False").lower() == "true"
SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")

# Session settings
SESSION_COOKIE_SECURE = os.environ.get("HTTPS_REDIRECT", "False").lower() == "true"
CSRF_COOKIE_SECURE = os.environ.get("HTTPS_REDIRECT", "False").lower() == "true"

# CSRF Trusted Origins - Necessário para forms POST funcionarem
CSRF_TRUSTED_ORIGINS = [
    "https://fourmindstech.com.br",
    "https://www.fourmindstech.com.br",
    "http://fourmindstech.com.br",  # Temporário durante transição HTTP->HTTPS
]

# Email settings
EMAIL_BACKEND = "django.core.mail.backends.smtp.EmailBackend"
EMAIL_HOST = os.environ.get("SMTP_HOST", "smtp.gmail.com")
EMAIL_PORT = int(os.environ.get("SMTP_PORT", "587"))
EMAIL_USE_TLS = True
EMAIL_HOST_USER = os.environ.get("SMTP_USER", "")
EMAIL_HOST_PASSWORD = os.environ.get("SMTP_PASSWORD", "")
DEFAULT_FROM_EMAIL = os.environ.get(
    "DEFAULT_FROM_EMAIL", "Sistema de Agendamentos <noreply@agendamentos.com>"
)

# Logging
LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "handlers": {
        "console": {
            "class": "logging.StreamHandler",
        },
    },
    "root": {
        "handlers": ["console"],
        "level": "INFO",
    },
    "loggers": {
        "django": {
            "handlers": ["console"],
            "level": "INFO",
            "propagate": False,
        },
    },
}

# Cache (usar memória para instância única)
CACHES = {
    "default": {
        "BACKEND": "django.core.cache.backends.locmem.LocMemCache",
        "LOCATION": "unique-snowflake",
    }
}

# WhiteNoise para arquivos estáticos (se disponível)
try:
    import whitenoise

    MIDDLEWARE.insert(1, "whitenoise.middleware.WhiteNoiseMiddleware")
    STATICFILES_STORAGE = "whitenoise.storage.CompressedManifestStaticFilesStorage"
except ImportError:
    # Se WhiteNoise não estiver disponível, usar configuração básica
    STATICFILES_STORAGE = "django.contrib.staticfiles.storage.StaticFilesStorage"

# Configuração adicional para servir arquivos estáticos
STATICFILES_FINDERS = [
    "django.contrib.staticfiles.finders.FileSystemFinder",
    "django.contrib.staticfiles.finders.AppDirectoriesFinder",
]

# Forçar Django a servir arquivos estáticos em produção
if not DEBUG:
    # Adicionar URL para servir arquivos estáticos
    from django.conf.urls.static import static
    from django.conf import settings

    # Esta configuração será aplicada no urls.py
    STATIC_URL = "/static/"
    STATIC_ROOT = os.path.join(BASE_DIR, "staticfiles")
