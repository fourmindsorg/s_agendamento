"""
Comando Django para verificar status dos usuários e período de teste
Sistema de Agendamento - 4Minds

Uso:
    python manage.py check_user_status
    python manage.py check_user_status --username usuario123
    python manage.py check_user_status --expiring-soon  # Usuários próximos do vencimento
"""

from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from django.utils import timezone
from datetime import timedelta

User = get_user_model()


class Command(BaseCommand):
    help = "Verifica status dos usuários e período de teste"

    def add_arguments(self, parser):
        parser.add_argument(
            "--username",
            type=str,
            help="Verificar status de um usuário específico",
        )
        parser.add_argument(
            "--expiring-soon",
            action="store_true",
            help="Mostrar apenas usuários próximos do vencimento (10-30 dias)",
        )
        parser.add_argument(
            "--days",
            type=int,
            default=14,
            help="Número de dias do período de teste (padrão: 14)",
        )

    def handle(self, *args, **options):
        username = options.get("username")
        expiring_soon = options["expiring_soon"]
        days = options["days"]

        if username:
            self.check_specific_user(username, days)
        elif expiring_soon:
            self.check_expiring_users(days)
        else:
            self.check_all_users(days)

    def check_specific_user(self, username, days):
        """Verifica status de um usuário específico"""
        try:
            usuario = User.objects.get(username=username)
            self.show_user_details(usuario, days)
        except User.DoesNotExist:
            self.stdout.write(
                self.style.ERROR(f'❌ Usuário "{username}" não encontrado.')
            )

    def check_expiring_users(self, days):
        """Mostra usuários próximos do vencimento"""
        data_limite = timezone.now() - timedelta(days=days)
        data_aviso = timezone.now() - timedelta(days=days - 4)  # 4 dias antes

        usuarios_proximos = User.objects.filter(
            date_joined__gte=data_limite, date_joined__lt=data_aviso, is_active=True
        ).order_by("date_joined")

        total = usuarios_proximos.count()

        if total == 0:
            self.stdout.write(
                self.style.SUCCESS("Nenhum usuário próximo do vencimento.")
            )
            return

        self.stdout.write(
            self.style.WARNING(f"{total} usuário(s) próximo(s) do vencimento:")
        )
        self.stdout.write("")

        for usuario in usuarios_proximos:
            dias_restantes = days - (timezone.now() - usuario.date_joined).days
            self.show_user_summary(usuario, dias_restantes)

    def check_all_users(self, days):
        """Mostra estatísticas gerais dos usuários"""
        data_limite = timezone.now() - timedelta(days=days)

        # Estatísticas gerais
        total_usuarios = User.objects.count()
        usuarios_ativos = User.objects.filter(is_active=True).count()
        usuarios_inativos = User.objects.filter(is_active=False).count()

        # Usuários no período de teste
        usuarios_teste = User.objects.filter(
            date_joined__gte=data_limite, is_active=True
        ).count()

        # Usuários expirados mas ainda ativos
        usuarios_expirados = User.objects.filter(
            date_joined__lt=data_limite, is_active=True
        ).count()

        # Usuários próximos do vencimento (últimos 4 dias)
        data_aviso = timezone.now() - timedelta(days=days - 4)
        usuarios_proximos = User.objects.filter(
            date_joined__gte=data_limite, date_joined__lt=data_aviso, is_active=True
        ).count()

        self.stdout.write(self.style.SUCCESS("Estatísticas dos Usuários"))
        self.stdout.write("=" * 50)
        self.stdout.write(f"Total de usuários: {total_usuarios}")
        self.stdout.write(f"Usuários ativos: {usuarios_ativos}")
        self.stdout.write(f"Usuários inativos: {usuarios_inativos}")
        self.stdout.write("")
        self.stdout.write(f"Período de teste: {days} dias")
        self.stdout.write(f"Usuários no período de teste: {usuarios_teste}")
        self.stdout.write(f"Usuários próximos do vencimento: {usuarios_proximos}")
        self.stdout.write(f"Usuários expirados (ainda ativos): {usuarios_expirados}")

        if usuarios_expirados > 0:
            self.stdout.write("")
            self.stdout.write(
                self.style.WARNING(
                    f"{usuarios_expirados} usuário(s) expirado(s) ainda ativo(s)!"
                )
            )
            self.stdout.write("Execute: python manage.py deactivate_expired_users")

    def show_user_details(self, usuario, days):
        """Mostra detalhes completos de um usuário"""
        dias_cadastrado = (timezone.now() - usuario.date_joined).days
        dias_restantes = max(0, days - dias_cadastrado)

        status = "ATIVO" if usuario.is_active else "INATIVO"
        periodo = "TESTE" if dias_restantes > 0 else "EXPIRADO"

        self.stdout.write("")
        self.stdout.write(f"👤 Usuário: {usuario.username}")
        self.stdout.write(f"📧 Email: {usuario.email}")
        self.stdout.write(f"👨‍💼 Nome: {usuario.get_full_name()}")
        self.stdout.write(
            f'📅 Cadastrado em: {usuario.date_joined.strftime("%d/%m/%Y %H:%M")}'
        )
        self.stdout.write(
            f'🕒 Último login: {usuario.last_login.strftime("%d/%m/%Y %H:%M") if usuario.last_login else "Nunca"}'
        )
        self.stdout.write(f"🔐 Status: {status}")
        self.stdout.write(f"⏰ Período: {periodo}")
        self.stdout.write(f"📊 Dias cadastrado: {dias_cadastrado}")
        self.stdout.write(f"⏳ Dias restantes: {dias_restantes}")

        if usuario.is_superuser:
            self.stdout.write("SUPERUSER")
        if usuario.is_staff:
            self.stdout.write("STAFF")

    def show_user_summary(self, usuario, dias_restantes):
        """Mostra resumo de um usuário"""
        status_icon = "[AVISO]" if dias_restantes > 0 else "[EXPIRADO]"

        self.stdout.write(
            f"{status_icon} {usuario.username} - {usuario.get_full_name()} - "
            f"{dias_restantes} dias restantes"
        )
