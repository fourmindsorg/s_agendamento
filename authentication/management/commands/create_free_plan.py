from django.core.management.base import BaseCommand
from authentication.models import Plano


class Command(BaseCommand):
    help = "Cria o plano gratuito padrão de 14 dias"

    def handle(self, *args, **options):
        try:
            # Verificar se já existe um plano gratuito
            plano_gratuito = Plano.objects.filter(tipo="gratuito").first()

            if plano_gratuito:
                self.stdout.write(
                    self.style.WARNING(
                        "Plano gratuito já existe: %s" % plano_gratuito.nome
                    )
                )
                return

            # Criar plano gratuito
            plano_gratuito = Plano.objects.create(
                nome="Período Gratuito",
                tipo="gratuito",
                descricao="Período de teste gratuito de 14 dias para novos usuários",
                preco_cartao=0.00,
                preco_pix=0.00,
                duracao_dias=14,
                ativo=True,
                destaque=False,
                ordem=0,
            )

            self.stdout.write(
                self.style.SUCCESS(
                    "Plano gratuito criado com sucesso: %s" % plano_gratuito.nome
                )
            )

        except Exception as e:
            self.stdout.write(
                self.style.ERROR("Erro ao criar plano gratuito: %s" % str(e))
            )
