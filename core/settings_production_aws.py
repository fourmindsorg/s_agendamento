"""
Configurações de produção para AWS
"""

import os
from .settings import *

# Debug
DEBUG = False

# Hosts permitidos
ALLOWED_HOSTS = [
    "52.20.60.108",
    "fourmindstech.com.br",
    "localhost",
    "127.0.0.1",
]

# Database - PostgreSQL RDS
DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": os.environ.get("DB_NAME", "agendamento_db"),
        "USER": os.environ.get("DB_USER", "agendamento_user"),
        "PASSWORD": os.environ.get("DB_PASSWORD", "Agendamento123!"),
        "HOST": os.environ.get(
            "DB_HOST", "s-agendamento-db.c1234567890.us-east-1.rds.amazonaws.com"
        ),
        "PORT": os.environ.get("DB_PORT", "5432"),
        "OPTIONS": {
            "sslmode": "require",
        },
    }
}

# S3 Storage
AWS_ACCESS_KEY_ID = os.environ.get("AWS_ACCESS_KEY_ID")
AWS_SECRET_ACCESS_KEY = os.environ.get("AWS_SECRET_ACCESS_KEY")
AWS_STORAGE_BUCKET_NAME_STATIC = os.environ.get(
    "AWS_STORAGE_BUCKET_NAME_STATIC", "s-agendamento-static-exxyawpx"
)
AWS_STORAGE_BUCKET_NAME_MEDIA = os.environ.get(
    "AWS_STORAGE_BUCKET_NAME_MEDIA", "s-agendamento-media-exxyawpx"
)
AWS_S3_REGION_NAME = os.environ.get("AWS_S3_REGION_NAME", "us-east-1")
AWS_S3_CUSTOM_DOMAIN = f"{AWS_STORAGE_BUCKET_NAME_STATIC}.s3.amazonaws.com"
AWS_DEFAULT_ACL = None
AWS_S3_OBJECT_PARAMETERS = {
    "CacheControl": "max-age=86400",
}

# Static files
STATICFILES_STORAGE = "storages.backends.s3boto3.S3Boto3Storage"
STATIC_URL = f"https://{AWS_S3_CUSTOM_DOMAIN}/static/"

# Media files
DEFAULT_FILE_STORAGE = "storages.backends.s3boto3.S3Boto3Storage"
MEDIA_URL = f"https://{AWS_STORAGE_BUCKET_NAME_MEDIA}.s3.amazonaws.com/media/"

# Security
SECURE_BROWSER_XSS_FILTER = True
SECURE_CONTENT_TYPE_NOSNIFF = True
X_FRAME_OPTIONS = "DENY"

# CSRF Trusted Origins - Necessário para forms POST funcionarem
CSRF_TRUSTED_ORIGINS = [
    "https://fourmindstech.com.br",
    "https://www.fourmindstech.com.br",
    "http://fourmindstech.com.br",  # Temporário durante transição HTTP->HTTPS
]

# HTTPS settings
SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True

# Logging
LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "handlers": {
        "file": {
            "level": "INFO",
            "class": "logging.FileHandler",
            "filename": "/opt/s-agendamento/logs/django.log",
        },
        "console": {
            "level": "INFO",
            "class": "logging.StreamHandler",
        },
    },
    "root": {
        "handlers": ["file", "console"],
        "level": "INFO",
    },
    "loggers": {
        "django": {
            "handlers": ["file", "console"],
            "level": "INFO",
            "propagate": False,
        },
    },
}

# Cache - Redis (se disponível)
CACHES = {
    "default": {
        "BACKEND": "django.core.cache.backends.locmem.LocMemCache",
        "LOCATION": "unique-snowflake",
    }
}

# Email (configurar conforme necessário)
EMAIL_BACKEND = "django.core.mail.backends.console.EmailBackend"

# Configurações da API Asaas (desabilitada)
ASAAS_API_KEY = os.environ.get("ASAAS_API_KEY", "")
ASAAS_ENV = os.environ.get("ASAAS_ENV", "sandbox")
ASAAS_WEBHOOK_TOKEN = os.environ.get("ASAAS_WEBHOOK_TOKEN", "")

# Desabilitar funcionalidades pagas
ASAAS_ENABLED = False
