import logging
from datetime import datetime, timedelta
from decimal import Decimal
from typing import Iterable, Optional, Set, Tuple

from django.core.management.base import BaseCommand
from django.db import transaction
from django.utils import timezone
from django.utils.dateparse import parse_datetime

from authentication.models import AssinaturaUsuario
from financeiro.models import AsaasPayment
from financeiro.services.asaas import AsaasAPIError, AsaasClient

logger = logging.getLogger(__name__)


CONFIRMED_STATUSES_DEFAULT = {
    "RECEIVED",
    "RECEIVED_IN_CASH",
    "CONFIRMED",
    "PAYMENT_CONFIRMED",
}


class Command(BaseCommand):
    help = (
        "Atualiza o status das assinaturas para 'ativa' quando o pagamento foi confirmado no Asaas. "
        "Recomenda-se executar diariamente (ex.: via cron) para cobrir pagamentos confirmados na última semana."
    )

    def add_arguments(self, parser):
        parser.add_argument(
            "--days",
            type=int,
            default=7,
            help="Janela de dias a partir de hoje para buscar pagamentos confirmados (padrão: 7).",
        )
        parser.add_argument(
            "--dry-run",
            action="store_true",
            help="Executa a rotina sem persistir alterações, exibindo apenas o que seria feito.",
        )
        parser.add_argument(
            "--status",
            action="append",
            dest="statuses",
            help=(
                "Status adicionais do Asaas que devem ser considerados como confirmado. "
                "Pode ser informado múltiplas vezes. "
                "Por padrão utiliza: RECEIVED, RECEIVED_IN_CASH, CONFIRMED, PAYMENT_CONFIRMED."
            ),
        )

    def handle(self, *args, **options):
        days = options["days"]
        dry_run = options["dry_run"]
        statuses = self._resolve_statuses(options.get("statuses"))

        window_end = timezone.now()
        window_start = window_end - timedelta(days=days)

        self.stdout.write(
            self.style.MIGRATE_HEADING(
                f"Iniciando sincronização de assinaturas pagas (janela: {window_start.date()} → {window_end.date()}, "
                f"status considerados: {', '.join(sorted(statuses))})"
            )
        )

        try:
            client = AsaasClient()
        except RuntimeError as exc:
            self.stderr.write(self.style.ERROR(f"Falha ao inicializar AsaasClient: {exc}"))
            return

        payments_processed = 0
        payments_confirmed = 0
        assinaturas_ativadas = 0
        assinaturas_atualizadas = 0
        payments_without_subscription = 0

        limit = 100
        offset = 0

        extra_params = {
            "paymentDate[ge]": window_start.date().isoformat(),
            "paymentDate[le]": window_end.date().isoformat(),
        }

        while True:
            try:
                response = client.list_payments(
                    limit=limit,
                    offset=offset,
                    extra_params=extra_params,
                )
            except AsaasAPIError as exc:
                self.stderr.write(
                    self.style.ERROR(
                        f"Erro ao buscar pagamentos no Asaas (offset={offset}): {exc.message}"
                    )
                )
                break

            data = response.get("data", [])
            if not data:
                break

            for payment in data:
                payments_processed += 1
                status = (payment.get("status") or "").upper()

                if status not in statuses:
                    continue

                payments_confirmed += 1
                updated, activated = self._process_payment(
                    payment,
                    window_start,
                    window_end,
                    dry_run=dry_run,
                )

                assinaturas_atualizadas += updated
                assinaturas_ativadas += activated

                if updated == 0:
                    payments_without_subscription += 1

            if len(data) < limit:
                break

            offset += limit

        self.stdout.write("")
        self.stdout.write(self.style.HTTP_INFO("Resumo da execução"))
        self.stdout.write(f"Pagamentos recuperados: {payments_processed}")
        self.stdout.write(f"Pagamentos confirmados considerados: {payments_confirmed}")
        self.stdout.write(
            f"Assinaturas atualizadas: {assinaturas_atualizadas} (ativadas: {assinaturas_ativadas})"
        )
        if payments_without_subscription:
            self.stdout.write(
                f"Pagamentos sem assinatura correspondente: {payments_without_subscription}"
            )
        if dry_run:
            self.stdout.write(self.style.WARNING("Execução em modo dry-run: nenhuma alteração persistida."))

    def _resolve_statuses(self, statuses: Optional[Iterable[str]]) -> Set[str]:
        base = set(CONFIRMED_STATUSES_DEFAULT)
        if statuses:
            base.update(s.upper() for s in statuses if s)
        return base

    def _process_payment(self, payment: dict, window_start, window_end, dry_run: bool) -> Tuple[int, int]:
        """
        Retorna uma tupla (assinaturas_atualizadas, assinaturas_ativadas).
        """
        payment_id = payment.get("id")
        if not payment_id:
            logger.warning("Pagamento ignorado: não possui ID.")
            return (0, 0)

        payment_date = self._parse_payment_datetime(payment)
        if payment_date and not (window_start <= payment_date <= window_end):
            logger.debug(
                "Pagamento %s fora da janela (%s). Ignorando.",
                payment_id,
                payment_date.isoformat(),
            )
            return (0, 0)

        amount = self._safe_decimal(payment.get("value"))
        billing_type = payment.get("billingType") or ""
        customer = payment.get("customer") or ""
        external_reference = payment.get("externalReference") or ""
        updated_assinaturas = 0
        activated_assinaturas = 0

        amount_for_default = amount if amount is not None else Decimal("0")

        payment_obj, _ = AsaasPayment.objects.get_or_create(
            asaas_id=payment_id,
            defaults={
                "customer_id": customer,
                "amount": amount_for_default,
                "billing_type": billing_type,
                "status": payment.get("status", ""),
            },
        )

        fields_to_update = []
        if payment_obj.customer_id != customer and customer:
            payment_obj.customer_id = customer
            fields_to_update.append("customer_id")
        if payment_obj.amount != amount and amount is not None:
            payment_obj.amount = amount
            fields_to_update.append("amount")
        if billing_type and payment_obj.billing_type != billing_type:
            payment_obj.billing_type = billing_type
            fields_to_update.append("billing_type")

        status = payment.get("status")
        if status and payment_obj.status != status:
            payment_obj.status = status
            fields_to_update.append("status")

        if payment_date and payment_obj.paid_at != payment_date:
            payment_obj.paid_at = payment_date
            fields_to_update.append("paid_at")

        invoice_url = payment.get("invoiceUrl")
        if invoice_url and payment_obj.invoice_url != invoice_url:
            payment_obj.invoice_url = invoice_url
            fields_to_update.append("invoice_url")

        if fields_to_update and not dry_run:
            payment_obj.save(update_fields=fields_to_update + ["updated_at"])

        assinaturas = AssinaturaUsuario.objects.filter(asaas_payment_id=payment_id)

        if not assinaturas.exists() and external_reference.startswith("assinatura_"):
            try:
                assinatura_id = int(external_reference.replace("assinatura_", ""))
            except ValueError:
                assinatura_id = None

            if assinatura_id:
                assinaturas = AssinaturaUsuario.objects.filter(id=assinatura_id)
                if assinaturas.exists() and not dry_run:
                    assinaturas.update(asaas_payment_id=payment_id)

        if not assinaturas.exists():
            logger.info(
                "Pagamento %s confirmado, mas nenhuma assinatura correspondente foi encontrada.",
                payment_id,
            )
            return (0, 0)

        for assinatura in assinaturas:
            atualizada, ativada = self._activate_subscription_if_needed(
                assinatura,
                payment_obj,
                payment_date,
                amount,
                billing_type,
                dry_run=dry_run,
            )
            if atualizada:
                updated_assinaturas += 1
                if ativada:
                    activated_assinaturas += 1

        return (updated_assinaturas, activated_assinaturas)

    def _activate_subscription_if_needed(
        self,
        assinatura: AssinaturaUsuario,
        payment_obj: AsaasPayment,
        payment_date,
        amount: Optional[Decimal],
        billing_type: str,
        dry_run: bool,
    ) -> Tuple[bool, bool]:
        """
        Retorna (assinatura_atualizada, assinatura_ativada).
        """
        if assinatura.status != "aguardando_pagamento":
            logger.debug(
                "Assinatura %s ignorada: status atual '%s'.",
                assinatura.id,
                assinatura.status,
            )
            return (0, 0)

        ativada = False
        assinatura_atualizada = False

        nova_data_inicio = payment_date or timezone.now()
        nova_data_fim = nova_data_inicio + timedelta(days=assinatura.plano.duracao_dias)

        assinatura.status = "ativa"
        assinatura_atualizada = True
        ativada = True

        if assinatura.data_inicio is None or assinatura.data_inicio < nova_data_inicio:
            assinatura.data_inicio = nova_data_inicio
        if assinatura.data_fim is None or assinatura.data_fim < nova_data_fim:
            assinatura.data_fim = nova_data_fim

        if amount is not None:
            assinatura.valor_pago = amount
        if billing_type:
            assinatura.metodo_pagamento = billing_type

        assinatura.asaas_payment_id = payment_obj.asaas_id

        if not dry_run:
            with transaction.atomic():
                assinatura.save()

        logger.info(
            "Assinatura %s atualizada para 'ativa' com pagamento %s (valor=%s, método=%s).",
            assinatura.id,
            payment_obj.asaas_id,
            amount if amount is not None else "n/d",
            billing_type or "n/d",
        )

        return (assinatura_atualizada, ativada)

    def _safe_decimal(self, value) -> Optional[Decimal]:
        if value in (None, ""):
            return None
        try:
            return Decimal(str(value))
        except (ArithmeticError, ValueError, TypeError):
            logger.warning("Não foi possível converter valor '%s' para Decimal.", value)
            return None

    def _parse_payment_datetime(self, payment: dict):
        payment_date_str = payment.get("paymentDate") or payment.get("confirmedDate") or payment.get("dateCreated")
        if not payment_date_str:
            return None

        dt = parse_datetime(payment_date_str)
        if dt:
            if dt.tzinfo is None:
                dt = timezone.make_aware(dt, timezone=timezone.get_current_timezone())
            return dt

        try:
            parsed_date = datetime.strptime(payment_date_str, "%Y-%m-%d").date()
            naive_dt = datetime.combine(parsed_date, datetime.min.time())
            return timezone.make_aware(
                naive_dt,
                timezone=timezone.get_current_timezone(),
            )
        except ValueError:
            logger.warning("Data de pagamento em formato inesperado: %s", payment_date_str)
            return None

