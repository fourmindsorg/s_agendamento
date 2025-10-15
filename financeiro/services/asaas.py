# Serviço para encapsular chamadas à API Asaas


import os
import requests
from django.conf import settings
from urllib.parse import urljoin


ASAAS_BASE = {
'sandbox': 'https://api-sandbox.asaas.com/v3/',
'production': 'https://www.asaas.com/api/v3/'
}


class AsaasClient:
    def __init__(self, api_key=None, env=None):
        self.api_key = api_key or getattr(settings, 'ASAAS_API_KEY')
        self.env = env or getattr(settings, 'ASAAS_ENV', 'sandbox')
        self.base = ASAAS_BASE.get(self.env, ASAAS_BASE['sandbox'])
        if not self.api_key:
            raise RuntimeError('ASAAS_API_KEY não configurada nas variáveis de ambiente')
        self.session = requests.Session()
        self.session.headers.update({'access_token': self.api_key, 'Content-Type': 'application/json'})

    def _url(self, path: str) -> str:
        return urljoin(self.base, path)

    def create_customer(self, name: str, email: str | None = None, cpf_cnpj: str | None = None, phone: str | None = None):
        """Cria cliente no Asaas (retorna o objeto JSON)."""
        payload = {'name': name}
        if email:
            payload['email'] = email
        if cpf_cnpj:
            payload['cpfCnpj'] = cpf_cnpj
        if phone:
            payload['phone'] = phone
        response = self.session.post(self._url('customers'), json=payload, timeout=15)
        response.raise_for_status()
        return response.json()

    def create_payment(self, customer_id: str, value: float, due_date: str, billing_type: str = 'PIX', description: str | None = None):
        """Cria cobrança (payment). billing_type: 'PIX','BOLETO','CREDIT_CARD'"""
        payload = {
            'customer': customer_id,
            'value': float(value),
            'dueDate': due_date,  # formato YYYY-MM-DD
            'billingType': billing_type,
        }
        if description:
            payload['description'] = description

        response = self.session.post(self._url('payments'), json=payload, timeout=15)
        response.raise_for_status()
        return response.json()

    def get_pix_qr(self, payment_id: str):
        """Recupera o QR Code (base64) e copy/paste payload para um pagamento PIX."""
        response = self.session.get(self._url(f'payments/{payment_id}/pix'), timeout=15)
        response.raise_for_status()
        return response.json()

    def pay_with_credit_card(self, payment_id: str, credit_card_payload: dict):
        """Efetua pagamento com cartão.
        credit_card_payload: dict com creditCardNumber, creditCardHolderName, creditCardExpiryDate, creditCardCvv, installmentCount.
        """
        # Endpoint baseado na documentação do Asaas
        # https://docs.asaas.com/reference/realizar-pagamento-com-cartao-de-credito
        response = self.session.post(
            self._url(f'payments/{payment_id}/pay'),
            json={'creditCard': credit_card_payload},
            timeout=30,
        )
        response.raise_for_status()
        return response.json()