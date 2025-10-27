from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone
from datetime import timedelta


class PreferenciasUsuario(models.Model):
    """Preferências de tema e personalização do usuário"""

    TEMAS_CHOICES = [
        ("default", "Azul Clássico"),
        ("emerald", "Verde Esmeralda"),
        ("sunset", "Pôr do Sol"),
        ("ocean", "Oceano Profundo"),
        ("purple", "Roxo Elegante"),
    ]

    # NOVO: Opção de modo escuro
    MODO_CHOICES = [
        ("light", "Claro"),
        ("dark", "Escuro"),
    ]

    usuario = models.OneToOneField(
        User, on_delete=models.CASCADE, related_name="preferencias"
    )
    tema = models.CharField(max_length=20, choices=TEMAS_CHOICES, default="default")
    modo = models.CharField(
        max_length=10, choices=MODO_CHOICES, default="light"
    )  # NOVO
    criado_em = models.DateTimeField(auto_now_add=True)
    atualizado_em = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Preferência do Usuário"
        verbose_name_plural = "Preferências dos Usuários"

    def __str__(self):
        return f"{self.usuario.username} - {self.get_tema_display()} ({self.get_modo_display()})"

    @classmethod
    def get_or_create_for_user(cls, user):
        """Retorna ou cria preferências para o usuário"""
        if user.is_authenticated:
            preferencias, created = cls.objects.get_or_create(usuario=user)
            return preferencias
        return None


class Plano(models.Model):
    """Modelo para os planos disponíveis"""

    TIPO_CHOICES = [
        ("gratuito", "Período Gratuito"),
        ("mensal", "Mensal"),
        ("semestral", "Semestral"),
        ("anual", "Anual"),
    ]

    nome = models.CharField(max_length=50, verbose_name="Nome do Plano")
    tipo = models.CharField(
        max_length=20, choices=TIPO_CHOICES, unique=True, verbose_name="Tipo"
    )
    descricao = models.TextField(verbose_name="Descrição")
    preco_cartao = models.DecimalField(
        max_digits=10, decimal_places=2, verbose_name="Preço no Cartão"
    )
    preco_pix = models.DecimalField(
        max_digits=10, decimal_places=2, verbose_name="Preço no PIX"
    )
    duracao_dias = models.IntegerField(verbose_name="Duração em Dias")
    ativo = models.BooleanField(default=True, verbose_name="Ativo")
    destaque = models.BooleanField(default=False, verbose_name="Plano em Destaque")
    ordem = models.IntegerField(default=0, verbose_name="Ordem de Exibição")
    criado_em = models.DateTimeField(auto_now_add=True)
    atualizado_em = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Plano"
        verbose_name_plural = "Planos"
        ordering = ["ordem", "nome"]

    def __str__(self):
        preco = self.preco_pix if self.preco_pix is not None else 0
        return f"{self.nome} - R$ {preco} (PIX)"

    @property
    def economia_pix(self):
        """Calcula a economia do PIX em relação ao cartão"""
        preco_cartao = self.preco_cartao or 0
        preco_pix = self.preco_pix or 0
        return max(preco_cartao - preco_pix, 0)


class AssinaturaUsuario(models.Model):
    """Modelo para assinaturas dos usuários"""

    STATUS_CHOICES = [
        ("aguardando_pagamento", "Aguardando Pagamento"),
        ("ativa", "Ativa"),
        ("expirada", "Expirada"),
        ("cancelada", "Cancelada"),
        ("suspensa", "Suspensa"),
    ]

    usuario = models.ForeignKey(
        User, on_delete=models.CASCADE, related_name="assinaturas"
    )
    plano = models.ForeignKey(
        Plano, on_delete=models.CASCADE, related_name="assinaturas"
    )
    status = models.CharField(
        max_length=20, choices=STATUS_CHOICES, default="aguardando_pagamento"
    )
    data_inicio = models.DateTimeField(auto_now_add=True, verbose_name="Data de Início")
    data_fim = models.DateTimeField(verbose_name="Data de Fim")
    valor_pago = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name="Valor Pago",
    )
    metodo_pagamento = models.CharField(
        max_length=20, null=True, blank=True, verbose_name="Método de Pagamento"
    )
    asaas_payment_id = models.CharField(
        max_length=100, null=True, blank=True, verbose_name="ID Pagamento Asaas"
    )
    criado_em = models.DateTimeField(auto_now_add=True)
    atualizado_em = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Assinatura do Usuário"
        verbose_name_plural = "Assinaturas dos Usuários"
        ordering = ["-data_inicio"]

    def __str__(self):
        return f"{self.usuario.username} - {self.plano.nome} ({self.status})"

    @property
    def ativa(self):
        """Verifica se a assinatura está ativa"""
        from django.utils import timezone

        if not self.data_fim:
            return False
        return self.status == "ativa" and self.data_fim > timezone.now()

    @property
    def dias_restantes(self):
        """Calcula dias restantes da assinatura"""
        from django.utils import timezone

        if self.status == "ativa" and self.data_fim:
            delta = self.data_fim - timezone.now()
            return max(0, delta.days)
        return 0
