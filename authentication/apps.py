from django.apps import AppConfig


class AuthenticationConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "authentication"

    def ready(self):
        # Importa sinais para registro de atividades
        try:
            from . import signals  # noqa: F401
        except ImportError as exc:
            import logging

            logging.getLogger(__name__).warning(
                "Não foi possível carregar sinais do app 'authentication': %s", exc
            )
