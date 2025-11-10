"""
Comando Django para desativar usuários após 30 dias de cadastro
Sistema de Agendamento - 4Minds

Uso:
    python manage.py deactivate_expired_users
    python manage.py deactivate_expired_users --dry-run  # Apenas simula
    python manage.py deactivate_expired_users --days 7   # Personalizar dias
"""

from django.core.management.base import BaseCommand, CommandError
from django.contrib.auth import get_user_model
from django.utils import timezone
from datetime import timedelta
from django.db import transaction

User = get_user_model()


class Command(BaseCommand):
    help = "Desativa usuários que completaram 30 dias de cadastro (período de teste)"

    def add_arguments(self, parser):
        parser.add_argument(
            "--dry-run",
            action="store_true",
            help="Apenas simula a operação sem fazer alterações reais",
        )
        parser.add_argument(
            "--days",
            type=int,
            default=14,
            help="Número de dias para considerar usuário expirado (padrão: 14)",
        )
        parser.add_argument(
            "--force",
            action="store_true",
            help="Força a desativação mesmo de superusers (use com cuidado)",
        )

    def handle(self, *args, **options):
        days = options["days"]
        dry_run = options["dry_run"]
        force = options["force"]

        # Calcular data limite
        data_limite = timezone.now() - timedelta(days=days)

        self.stdout.write(
            self.style.SUCCESS(
                f'Verificando usuários cadastrados antes de {data_limite.strftime("%d/%m/%Y %H:%M")}...'
            )
        )

        # Buscar usuários que devem ser desativados
        usuarios_para_desativar = User.objects.filter(
            date_joined__lt=data_limite, is_active=True
        )

        # Excluir superusers a menos que force seja usado
        if not force:
            usuarios_para_desativar = usuarios_para_desativar.filter(is_superuser=False)

        total_usuarios = usuarios_para_desativar.count()

        if total_usuarios == 0:
            self.stdout.write(
                self.style.SUCCESS("Nenhum usuário encontrado para desativação.")
            )
            return

        # Mostrar usuários que serão afetados
        self.stdout.write(
            self.style.WARNING(
                f"Encontrados {total_usuarios} usuário(s) para desativação:"
            )
        )

        for usuario in usuarios_para_desativar:
            dias_cadastrado = (timezone.now() - usuario.date_joined).days
            status_superuser = " (SUPERUSER)" if usuario.is_superuser else ""

            self.stdout.write(
                f"  • {usuario.username} - {usuario.get_full_name()} - "
                f'Cadastrado em {usuario.date_joined.strftime("%d/%m/%Y")} '
                f"({dias_cadastrado} dias atrás){status_superuser}"
            )

        if dry_run:
            self.stdout.write(
                self.style.WARNING("MODO DRY-RUN: Nenhuma alteração foi feita.")
            )
            return

        # Confirmar operação
        if not force:
            self.stdout.write("")
            confirmacao = input(
                f"Deseja realmente desativar {total_usuarios} usuário(s)? "
                'Digite "CONFIRMAR" para prosseguir: '
            )

            if confirmacao != "CONFIRMAR":
                self.stdout.write(
                    self.style.WARNING("Operação cancelada pelo usuário.")
                )
                return

        # Executar desativação
        try:
            with transaction.atomic():
                usuarios_desativados = 0

                for usuario in usuarios_para_desativar:
                    usuario.is_active = False
                    usuario.save(update_fields=["is_active"])
                    usuarios_desativados += 1

                    self.stdout.write(f"  {usuario.username} desativado")

                self.stdout.write("")
                self.stdout.write(
                    self.style.SUCCESS(
                        f"Sucesso! {usuarios_desativados} usuário(s) desativado(s)."
                    )
                )

                # Estatísticas adicionais
                usuarios_ativos = User.objects.filter(is_active=True).count()
                usuarios_inativos = User.objects.filter(is_active=False).count()

                self.stdout.write("")
                self.stdout.write("Estatísticas atuais:")
                self.stdout.write(f"  - Usuários ativos: {usuarios_ativos}")
                self.stdout.write(f"  - Usuários inativos: {usuarios_inativos}")
                self.stdout.write(
                    f"  - Total de usuários: {usuarios_ativos + usuarios_inativos}"
                )

        except Exception as e:
            raise CommandError(f"Erro ao desativar usuários: {e}")

    def get_help_text(self):
        return """
Este comando desativa usuários que completaram o período de teste de 30 dias.

Funcionalidades:
- Desativa usuários cadastrados há mais de 30 dias (configurável)
- Protege superusers por padrão (use --force para incluir)
- Modo dry-run para simular sem alterar dados
- Confirmação de segurança antes de executar
- Estatísticas detalhadas após execução

Exemplos de uso:
  python manage.py deactivate_expired_users
  python manage.py deactivate_expired_users --dry-run
  python manage.py deactivate_expired_users --days 7
  python manage.py deactivate_expired_users --force
        """
