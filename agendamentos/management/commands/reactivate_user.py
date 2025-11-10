"""
Comando Django para reativar usuários desativados
Sistema de Agendamento - 4Minds

Uso:
    python manage.py reactivate_user --username usuario123
    python manage.py reactivate_user --username usuario123 --extend-days 30
"""

from django.core.management.base import BaseCommand, CommandError
from django.contrib.auth import get_user_model
from django.utils import timezone
from datetime import timedelta

User = get_user_model()


class Command(BaseCommand):
    help = "Reativa usuários desativados e opcionalmente estende o período de teste"

    def add_arguments(self, parser):
        parser.add_argument(
            "--username",
            type=str,
            required=True,
            help="Username do usuário a ser reativado",
        )
        parser.add_argument(
            "--extend-days",
            type=int,
            default=0,
            help="Estender período de teste por N dias (atualiza date_joined)",
        )
        parser.add_argument(
            "--force",
            action="store_true",
            help="Força reativação mesmo de superusers",
        )

    def handle(self, *args, **options):
        username = options["username"]
        extend_days = options["extend_days"]
        force = options["force"]

        try:
            usuario = User.objects.get(username=username)
        except User.DoesNotExist:
            raise CommandError(f'❌ Usuário "{username}" não encontrado.')

        # Verificar se já está ativo
        if usuario.is_active:
            self.stdout.write(
                self.style.WARNING(f'Usuário "{username}" já está ativo.')
            )
            return

        # Verificar se é superuser
        if usuario.is_superuser and not force:
            self.stdout.write(
                self.style.ERROR(
                    f'Usuário "{username}" é superuser. Use --force para reativar.'
                )
            )
            return

        # Mostrar informações do usuário
        dias_desativado = (timezone.now() - usuario.date_joined).days
        self.stdout.write(f"👤 Usuário: {usuario.username}")
        self.stdout.write(f"📧 Email: {usuario.email}")
        self.stdout.write(f"👨‍💼 Nome: {usuario.get_full_name()}")
        self.stdout.write(
            f'📅 Cadastrado em: {usuario.date_joined.strftime("%d/%m/%Y %H:%M")}'
        )
        self.stdout.write(f"📊 Dias desde cadastro: {dias_desativado}")

        if extend_days > 0:
            # Atualizar date_joined para estender período
            nova_data = timezone.now() - timedelta(days=30 - extend_days)
            usuario.date_joined = nova_data
            self.stdout.write(
                f'⏰ Nova data de cadastro: {nova_data.strftime("%d/%m/%Y %H:%M")}'
            )
            self.stdout.write(f"📅 Período de teste estendido por {extend_days} dias")

        # Confirmar operação
        confirmacao = input(
            f'Deseja reativar o usuário "{username}"? '
            'Digite "CONFIRMAR" para prosseguir: '
        )

        if confirmacao != "CONFIRMAR":
            self.stdout.write(self.style.WARNING("Operação cancelada pelo usuário."))
            return

        # Reativar usuário
        try:
            usuario.is_active = True
            usuario.save()

            self.stdout.write(
                self.style.SUCCESS(f'Usuário "{username}" reativado com sucesso!')
            )

            if extend_days > 0:
                self.stdout.write(
                    self.style.SUCCESS(
                        f"Período de teste estendido por {extend_days} dias!"
                    )
                )

        except Exception as e:
            raise CommandError(f"Erro ao reativar usuário: {e}")
