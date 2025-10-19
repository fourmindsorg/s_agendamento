from django.core.management.base import BaseCommand
from django.contrib.auth.models import User
from django.utils import timezone
from datetime import timedelta
from agendamentos.models import Cliente, TipoServico, Agendamento
from authentication.models import AssinaturaUsuario
import logging

logger = logging.getLogger(__name__)


class Command(BaseCommand):
    help = "Remove usuários expirados e seus dados após 180 dias de inatividade"

    def add_arguments(self, parser):
        parser.add_argument(
            "--dry-run",
            action="store_true",
            help="Executa sem deletar dados, apenas mostra o que seria removido",
        )
        parser.add_argument(
            "--days",
            type=int,
            default=180,
            help="Número de dias para considerar usuário expirado (padrão: 180)",
        )

    def handle(self, *args, **options):
        dry_run = options["dry_run"]
        days = options["days"]

        self.stdout.write(
            self.style.SUCCESS(
                f"Iniciando limpeza de usuários expirados há mais de {days} dias..."
            )
        )

        # Data limite para considerar usuário expirado
        cutoff_date = timezone.now() - timedelta(days=days)

        # Buscar usuários com assinatura expirada há mais de X dias
        expired_users = self.get_expired_users(cutoff_date)

        if not expired_users:
            self.stdout.write(
                self.style.SUCCESS("Nenhum usuário expirado encontrado para remoção.")
            )
            return

        self.stdout.write(
            self.style.WARNING(
                f"Encontrados {len(expired_users)} usuários para remoção:"
            )
        )

        total_data_removed = {
            "clientes": 0,
            "servicos": 0,
            "agendamentos": 0,
            "assinaturas": 0,
            "usuarios": 0,
        }

        for user in expired_users:
            self.process_user_cleanup(user, dry_run, total_data_removed)

        # Relatório final
        self.print_cleanup_report(total_data_removed, dry_run)

        if dry_run:
            self.stdout.write(
                self.style.WARNING(
                    "Execução em modo DRY-RUN - nenhum dado foi removido."
                )
            )
        else:
            self.stdout.write(self.style.SUCCESS("Limpeza concluída com sucesso!"))

    def get_expired_users(self, cutoff_date):
        """Busca usuários com assinatura expirada há mais de X dias"""
        expired_users = []

        # Buscar usuários com assinatura expirada
        expired_assinaturas = AssinaturaUsuario.objects.filter(
            status="expirada", data_fim__lt=cutoff_date
        ).select_related("usuario")

        for assinatura in expired_assinaturas:
            user = assinatura.usuario

            # Verificar se o usuário não tem assinatura ativa
            has_active_subscription = AssinaturaUsuario.objects.filter(
                usuario=user, status="ativa"
            ).exists()

            if not has_active_subscription:
                expired_users.append(user)

        return expired_users

    def process_user_cleanup(self, user, dry_run, total_data_removed):
        """Processa a limpeza de dados de um usuário específico"""
        self.stdout.write(f"  - {user.username} ({user.get_full_name()})")

        # Contar dados do usuário
        clientes_count = Cliente.objects.filter(criado_por=user).count()
        servicos_count = TipoServico.objects.filter(criado_por=user).count()
        agendamentos_count = Agendamento.objects.filter(criado_por=user).count()
        assinaturas_count = AssinaturaUsuario.objects.filter(usuario=user).count()

        self.stdout.write(f"    Clientes: {clientes_count}")
        self.stdout.write(f"    Serviços: {servicos_count}")
        self.stdout.write(f"    Agendamentos: {agendamentos_count}")
        self.stdout.write(f"    Assinaturas: {assinaturas_count}")

        if not dry_run:
            # Remover dados do usuário (exceto assinaturas e pagamentos)
            Cliente.objects.filter(criado_por=user).delete()
            TipoServico.objects.filter(criado_por=user).delete()
            Agendamento.objects.filter(criado_por=user).delete()

            # Manter apenas assinaturas e pagamentos para histórico
            # (não deletar AssinaturaUsuario)

            # Desativar usuário em vez de deletar
            user.is_active = False
            user.save()

            logger.info(f"Usuário {user.username} desativado e dados removidos")

        # Atualizar contadores
        total_data_removed["clientes"] += clientes_count
        total_data_removed["servicos"] += servicos_count
        total_data_removed["agendamentos"] += agendamentos_count
        total_data_removed["assinaturas"] += assinaturas_count
        total_data_removed["usuarios"] += 1

    def print_cleanup_report(self, total_data_removed, dry_run):
        """Imprime relatório da limpeza"""
        self.stdout.write("\n" + "=" * 50)
        self.stdout.write("RELATÓRIO DE LIMPEZA")
        self.stdout.write("=" * 50)

        if dry_run:
            self.stdout.write("MODO DRY-RUN - Dados que seriam removidos:")
        else:
            self.stdout.write("Dados removidos:")

        self.stdout.write(f'  Usuários: {total_data_removed["usuarios"]}')
        self.stdout.write(f'  Clientes: {total_data_removed["clientes"]}')
        self.stdout.write(f'  Serviços: {total_data_removed["servicos"]}')
        self.stdout.write(f'  Agendamentos: {total_data_removed["agendamentos"]}')
        self.stdout.write(
            f'  Assinaturas: {total_data_removed["assinaturas"]} (mantidas para histórico)'
        )

        self.stdout.write("\nDados preservados:")
        self.stdout.write("  - Assinaturas e histórico de pagamentos")
        self.stdout.write("  - Dados de período gratuito")
        self.stdout.write("  - Dados de planos contratados")

        self.stdout.write("=" * 50)
