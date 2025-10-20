from django.core.management.base import BaseCommand
from authentication.models import Plano


class Command(BaseCommand):
    help = "Garante que o plano gratuito existe no sistema"

    def handle(self, *args, **options):
        self.stdout.write("Verificando plano gratuito...")

        # Buscar ou criar plano gratuito
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

        # Verificar se está ativo
        if not plano_gratuito.ativo:
            plano_gratuito.ativo = True
            plano_gratuito.save()
            self.stdout.write(self.style.WARNING("⚠️ Plano Gratuito estava inativo - ativado"))

        self.stdout.write("")
        self.stdout.write(self.style.SUCCESS("🎉 Plano Gratuito configurado com sucesso!"))
        self.stdout.write(f"  • Nome: {plano_gratuito.nome}")
        self.stdout.write(f"  • Duração: {plano_gratuito.duracao_dias} dias")
        self.stdout.write(f"  • Preço: R$ {plano_gratuito.preco_pix}")
        self.stdout.write(f"  • Ativo: {'Sim' if plano_gratuito.ativo else 'Não'}")
