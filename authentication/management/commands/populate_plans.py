from django.core.management.base import BaseCommand
from authentication.models import Plano


class Command(BaseCommand):
    help = "Popula o banco de dados com os planos iniciais"

    def handle(self, *args, **options):
        self.stdout.write("Criando planos iniciais...")

        # Plano Gratuito
        plano_gratuito, created = Plano.objects.get_or_create(
            tipo="gratuito",
            defaults={
                "nome": "Período Gratuito",
                "descricao": "Teste todas as funcionalidades do sistema por 14 dias sem compromisso.",
                "preco_cartao": 0.00,
                "preco_pix": 0.00,
                "duracao_dias": 14,
                "ativo": True,
                "destaque": False,
                "ordem": 0,
            },
        )

        if created:
            self.stdout.write(self.style.SUCCESS("✅ Plano Gratuito criado"))
        else:
            self.stdout.write("ℹ️ Plano Gratuito já existe")

        # Plano Mensal
        plano_mensal, created = Plano.objects.get_or_create(
            tipo="mensal",
            defaults={
                "nome": "Plano Mensal",
                "descricao": "Ideal para quem quer começar sem compromisso e testar nossos recursos.",
                "preco_cartao": 49.00,
                "preco_pix": 45.00,
                "duracao_dias": 30,
                "ativo": True,
                "destaque": False,
                "ordem": 1,
            },
        )

        if created:
            self.stdout.write(self.style.SUCCESS("✅ Plano Mensal criado"))
        else:
            self.stdout.write("ℹ️ Plano Mensal já existe")

        # Plano Semestral (Destaque)
        plano_semestral, created = Plano.objects.get_or_create(
            tipo="semestral",
            defaults={
                "nome": "Plano Semestral",
                "descricao": "O melhor custo-benefício! Mais economia e acesso completo por 6 meses.",
                "preco_cartao": 280.00,
                "preco_pix": 250.00,
                "duracao_dias": 180,
                "ativo": True,
                "destaque": True,
                "ordem": 2,
            },
        )

        if created:
            self.stdout.write(self.style.SUCCESS("✅ Plano Semestral criado"))
        else:
            self.stdout.write("ℹ️ Plano Semestral já existe")

        # Plano Anual
        plano_anual, created = Plano.objects.get_or_create(
            tipo="anual",
            defaults={
                "nome": "Plano Anual",
                "descricao": "Para quem pensa a longo prazo. Pague menos e mantenha sua operação tranquila o ano inteiro.",
                "preco_cartao": 560.00,
                "preco_pix": 500.00,
                "duracao_dias": 365,
                "ativo": True,
                "destaque": False,
                "ordem": 3,
            },
        )

        if created:
            self.stdout.write(self.style.SUCCESS("✅ Plano Anual criado"))
        else:
            self.stdout.write("ℹ️ Plano Anual já existe")

        self.stdout.write("")
        self.stdout.write(self.style.SUCCESS("🎉 Planos configurados com sucesso!"))
        self.stdout.write("")
        self.stdout.write("Planos disponíveis:")
        for plano in Plano.objects.filter(ativo=True).order_by("ordem"):
            self.stdout.write(
                f"  • {plano.nome} - R$ {plano.preco_pix} (PIX) - {plano.duracao_dias} dias"
            )
