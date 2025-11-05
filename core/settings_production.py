import os
from pathlib import Path
from .settings import *

# Carregar variáveis de ambiente do arquivo .env
# IMPORTANTE: settings_production herda de settings, mas recarrega o .env aqui
# para garantir que funcione mesmo se settings.py não tiver carregado
try:
    from dotenv import load_dotenv
    import logging
    
    logger = logging.getLogger(__name__)
    
    # BASE_DIR ainda não está definido aqui, então usar Path(__file__)
    BASE_DIR = Path(__file__).resolve().parent.parent
    env_path = BASE_DIR / '.env'
    
    if env_path.exists():
        # Usar caminho absoluto e override=True para garantir que funcione
        load_dotenv(dotenv_path=str(env_path.absolute()), override=True)
        logger.info(f"✅ [PRODUCTION] Arquivo .env carregado de: {env_path.absolute()}")
    else:
        # Fallback: tentar carregar do diretório atual
        load_dotenv(override=True)
        logger.warning(f"⚠️ [PRODUCTION] Arquivo .env não encontrado em {env_path.absolute()}, tentando diretório atual")
        
    # Verificar se ASAAS_API_KEY foi carregada (log sempre em produção para diagnóstico)
    asaas_key_loaded = bool(os.environ.get("ASAAS_API_KEY"))
    if asaas_key_loaded:
        logger.info("✅ [PRODUCTION] ASAAS_API_KEY carregada com sucesso")
    else:
        logger.error("❌ [PRODUCTION] ASAAS_API_KEY NÃO foi carregada! Verifique o arquivo .env")
        
except ImportError:
    import logging
    logger = logging.getLogger(__name__)
    logger.warning("⚠️ [PRODUCTION] python-dotenv não instalado, variáveis de ambiente devem ser configuradas manualmente")
except Exception as e:
    import logging
    logger = logging.getLogger(__name__)
    logger.error(f"❌ [PRODUCTION] Erro ao carregar .env: {e}", exc_info=True)

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = os.environ.get(
    "SECRET_KEY", "django-insecure-66zn5&gupp_qti161gwv@t5z1@h=vq5^o%mjf+*3e!l*ut&v(a"
)

# SECURITY WARNING: don't run with debug turned on in production!
# Forçar DEBUG=False em produção (não permitir sobrescrever via env)
DEBUG = False

# Hosts permitidos para produção
ALLOWED_HOSTS = [
    "localhost",
    "127.0.0.1",
    "0.0.0.0",
    "3.80.178.120",
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
    # Usar storage simples para evitar problemas com arquivos faltando
    STATICFILES_STORAGE = "whitenoise.storage.StaticFilesStorage"
except ImportError:
    # Se WhiteNoise não estiver disponível, usar configuração básica
    STATICFILES_STORAGE = "django.contrib.staticfiles.storage.StaticFilesStorage"

# Configuração adicional para servir arquivos estáticos
STATICFILES_FINDERS = [
    "django.contrib.staticfiles.finders.FileSystemFinder",
    "django.contrib.staticfiles.finders.AppDirectoriesFinder",
]

# AWS / S3 settings (caso necessário no futuro)
AWS_ACCESS_KEY_ID = os.environ.get("AWS_ACCESS_KEY_ID", "")
AWS_SECRET_ACCESS_KEY = os.environ.get("AWS_SECRET_ACCESS_KEY", "")
AWS_STORAGE_BUCKET_NAME = os.environ.get("AWS_STORAGE_BUCKET_NAME", "")

# Configurações da API Asaas
# Forçar ambiente de produção neste arquivo de settings
# O settings.py já contém a lógica para carregar chaves.
# Como este arquivo faz "from .settings import *", as configurações do Asaas
# já estão herdadas. Forçamos ambiente de produção aqui.
# 
# IMPORTANTE: Configure a variável de ambiente no servidor:
# - ASAAS_API_KEY=$aact_SUA_CHAVE_AQUI

# Forçar ambiente de produção
ASAAS_ENV = "production"

# Recarregar chave de API para produção após forçar ambiente
ASAAS_API_KEY = os.environ.get("ASAAS_API_KEY")

# Garantir que Asaas está habilitado se a chave estiver configurada
ASAAS_ENABLED = bool(ASAAS_API_KEY)
