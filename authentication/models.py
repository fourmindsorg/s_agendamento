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


class UserActivityLog(models.Model):
    """Registra métricas agregadas de uso por usuário autenticado."""

    user = models.OneToOneField(
        User, on_delete=models.CASCADE, related_name="activity_log"
    )
    total_requests = models.PositiveBigIntegerField(default=0)
    total_get_requests = models.PositiveBigIntegerField(default=0)
    total_post_requests = models.PositiveBigIntegerField(default=0)
    total_put_requests = models.PositiveBigIntegerField(default=0)
    total_delete_requests = models.PositiveBigIntegerField(default=0)
    total_login_success = models.PositiveIntegerField(default=0)
    total_login_failed = models.PositiveIntegerField(default=0)
    last_activity = models.DateTimeField(null=True, blank=True)
    last_request_path = models.CharField(max_length=512, blank=True)
    last_user_agent = models.CharField(max_length=512, blank=True)
    last_login_ip = models.GenericIPAddressField(null=True, blank=True)
    estimated_data_volume_bytes = models.BigIntegerField(default=0)
    last_data_volume_calculated = models.DateTimeField(null=True, blank=True)
    first_seen = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Registro de Atividade do Usuário"
        verbose_name_plural = "Registros de Atividades dos Usuários"

    def __str__(self):
        return f"Atividade de {self.user.username}"

    def increment_request(self, method, path=None, user_agent=None, ip=None):
        """Atualiza contadores de requisições de acordo com o método HTTP."""
        method = (method or "").upper()
        now = timezone.now()
        updates = {
            "total_requests": models.F("total_requests") + 1,
            "last_activity": now,
            "updated_at": now,
        }

        if method == "GET":
            updates["total_get_requests"] = models.F("total_get_requests") + 1
        elif method == "POST":
            updates["total_post_requests"] = models.F("total_post_requests") + 1
        elif method == "PUT":
            updates["total_put_requests"] = models.F("total_put_requests") + 1
        elif method == "DELETE":
            updates["total_delete_requests"] = models.F("total_delete_requests") + 1

        if path:
            updates["last_request_path"] = path[:512]
        if user_agent:
            updates["last_user_agent"] = user_agent[:512]
        if ip:
            updates["last_login_ip"] = ip

        type(self).objects.filter(pk=self.pk).update(**updates)
        self.refresh_from_db(fields=[
            "total_requests",
            "total_get_requests",
            "total_post_requests",
            "total_put_requests",
            "total_delete_requests",
            "last_activity",
            "last_request_path",
            "last_user_agent",
            "last_login_ip",
            "updated_at",
        ])

    def increment_login_success(self, ip=None, user_agent=None):
        now = timezone.now()
        updates = {
            "total_login_success": models.F("total_login_success") + 1,
            "last_activity": now,
            "updated_at": now,
        }
        if ip:
            updates["last_login_ip"] = ip
        if user_agent:
            updates["last_user_agent"] = user_agent[:512]

        type(self).objects.filter(pk=self.pk).update(**updates)
        self.refresh_from_db(fields=[
            "total_login_success",
            "last_activity",
            "last_login_ip",
            "last_user_agent",
            "updated_at",
        ])

    def increment_login_failed(self):
        type(self).objects.filter(pk=self.pk).update(
            total_login_failed=models.F("total_login_failed") + 1,
            updated_at=timezone.now(),
        )
        self.refresh_from_db(fields=["total_login_failed", "updated_at"])

    @property
    def activity_score(self):
        """Retorna uma pontuação simples baseada no volume de requisições."""
        if not self.last_activity:
            return 0
        days_active = max((timezone.now() - self.first_seen).days, 1)
        return int(self.total_requests / days_active)


class LegalDocument(models.Model):
    """Armazena versões de documentos legais (termos, políticas, contratos)."""

    DOCUMENT_TYPE_CHOICES = [
        ("terms_of_use", "Termos de Uso"),
        ("privacy_policy", "Política de Privacidade"),
        ("service_contract", "Contrato de Adesão"),
    ]

    slug = models.SlugField(unique=True, max_length=80)
    document_type = models.CharField(
        max_length=40, choices=DOCUMENT_TYPE_CHOICES, default="terms_of_use"
    )
    title = models.CharField(max_length=150)
    summary = models.CharField(max_length=255, blank=True)
    content = models.TextField()
    version = models.CharField(max_length=20, default="1.0.0")
    is_active = models.BooleanField(default=True)
    requires_explicit_acceptance = models.BooleanField(default=True)
    published_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Documento Legal"
        verbose_name_plural = "Documentos Legais"
        ordering = ["document_type", "-published_at"]

    def __str__(self):
        return f"{self.title} (v{self.version})"

    @classmethod
    def get_active_documents(cls):
        return cls.objects.filter(is_active=True).order_by("title")

    @classmethod
    def get_active_by_slug(cls, slug):
        return cls.objects.filter(slug=slug, is_active=True).order_by("-published_at").first()


class UserLegalAcceptance(models.Model):
    """Registra o aceite dos documentos legais por usuário e versão."""

    user = models.ForeignKey(
        User, on_delete=models.CASCADE, related_name="legal_acceptances"
    )
    document = models.ForeignKey(
        LegalDocument, on_delete=models.CASCADE, related_name="acceptances"
    )
    version = models.CharField(max_length=20)
    accepted_at = models.DateTimeField(auto_now_add=True)
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    user_agent = models.CharField(max_length=512, blank=True)
    record_source = models.CharField(
        max_length=100, blank=True, help_text="Origem do aceite (ex: cadastro web)."
    )

    class Meta:
        verbose_name = "Aceite de Documento Legal"
        verbose_name_plural = "Aceites de Documentos Legais"
        unique_together = ("user", "document", "version")
        ordering = ["-accepted_at"]

    def __str__(self):
        return f"Aceite de {self.document.title} por {self.user.username}"

    @property
    def is_current(self):
        """Indica se o aceite corresponde à versão ativa atual."""
        active = LegalDocument.get_active_by_slug(self.document.slug)
        if not active:
            return False
        return active.version == self.version
