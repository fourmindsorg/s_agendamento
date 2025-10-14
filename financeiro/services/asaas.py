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


def _url(self, path):
    return urljoin(self.base, path)


def create_customer(self, name, email=None, cpf_cnpj=None, phone=None):
    """Cria cliente no Asaas (retorna o objeto JSON)."""
    payload = {'name': name}
    if email: payload['email'] = email
    if cpf_cnpj: payload['cpfCnpj'] = cpf_cnpj
    if phone: payload['phone'] = phone
    r = self.session.post(self._url('customers'), json=payload, timeout=15)
    r.raise_for_status()
    return r.json()


def create_payment(self, customer_id, value, due_date, billing_type='PIX', description=None):
    """Cria cobrança (payment). billing_type: 'PIX','BOLETO','CREDIT_CARD'"""
    payload = {
    'customer': customer_id,
    'value': float(value),
    'dueDate': due_date, # formato YYYY-MM-DD
    'billingType': billing_type,
    }
    if description:
        payload['description'] = description
        r = self.session.post(self._url('payments'), json=payload, timeout=15)
        r.raise_for_status()
    return r.json()


def get_pix_qr(self, payment_id):
    """Recupera o QR Code (base64) e copy/paste payload para um pagamento PIX."""
    r = self.session.get(self._url(f'payments/{payment_id}/pix'), timeout=15)
    r.raise_for_status()
    return r.json()


def pay_with_credit_card(self, payment_id, credit_card_payload):
    """Paga uma cobrança com cartão enviando dados do cartão (evitar no prod; prefira tokenização/checkout).
    credit_card_payload: dict com creditCardNumber, creditCardHolderName, creditCardExpiryDate, creditCardCvv, installmentCount
    """
    return r.json()