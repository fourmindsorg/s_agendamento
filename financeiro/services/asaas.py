# Serviço para encapsular chamadas à API Asaas

import logging
import os
import requests
from django.conf import settings
from urllib.parse import urljoin
from typing import Optional, Dict, Any, List

logger = logging.getLogger(__name__)

ASAAS_BASE = {
    "sandbox": "https://api-sandbox.asaas.com/v3/",
    "production": "https://www.asaas.com/api/v3/",
}


class AsaasAPIError(Exception):
    """Exceção personalizada para erros da API Asaas"""

    def __init__(self, message: str, status_code: Optional[int] = None, response: Optional[Dict] = None):
        self.message = message
        self.status_code = status_code
        self.response = response
        super().__init__(self.message)


class AsaasClient:
    """
    Cliente para integração com a API do Asaas.
    
    Documentação: https://docs.asaas.com/
    """

    def __init__(self, api_key=None, env=None):
        self.api_key = api_key or getattr(settings, "ASAAS_API_KEY", None)
        self.env = env or getattr(settings, "ASAAS_ENV", "sandbox")
        self.base = ASAAS_BASE.get(self.env, ASAAS_BASE["sandbox"])
        
        if not self.api_key:
            raise RuntimeError(
                "ASAAS_API_KEY não configurada nas variáveis de ambiente. "
                "Configure a variável ASAAS_API_KEY no arquivo .env"
            )
        
        self.session = requests.Session()
        # Asaas API usa 'access_token' no header, não Authorization
        # A chave pode começar com '$' ou não, ambos são válidos
        api_key_clean = self.api_key.strip()
        self.session.headers.update(
            {"access_token": api_key_clean, "Content-Type": "application/json"}
        )
        
        logger.info(f"AsaasClient inicializado - Ambiente: {self.env}")

    def _url(self, path: str) -> str:
        """Constrói a URL completa para um endpoint"""
        return urljoin(self.base, path)

    def _request(
        self, method: str, endpoint: str, **kwargs
    ) -> requests.Response:
        """
        Realiza uma requisição HTTP com tratamento de erros.
        
        Args:
            method: Método HTTP (GET, POST, PUT, DELETE)
            endpoint: Endpoint da API (sem a base URL)
            **kwargs: Argumentos adicionais para requests (json, timeout, etc.)
        
        Returns:
            Response object
        
        Raises:
            AsaasAPIError: Em caso de erro na requisição
        """
        url = self._url(endpoint)
        timeout = kwargs.pop("timeout", 30)
        
        try:
            response = self.session.request(
                method, url, timeout=timeout, **kwargs
            )
            
            if not response.ok:
                error_data = {}
                try:
                    error_data = response.json()
                except:
                    error_data = {"message": response.text}
                
                logger.error(
                    f"Erro na API Asaas [{response.status_code}]: {endpoint} - {error_data}"
                )
                raise AsaasAPIError(
                    message=error_data.get("message", f"Erro HTTP {response.status_code}"),
                    status_code=response.status_code,
                    response=error_data,
                )
            
            return response
            
        except requests.exceptions.Timeout:
            logger.error(f"Timeout na requisição para {endpoint}")
            raise AsaasAPIError(
                message="Timeout na comunicação com a API Asaas",
                status_code=None,
            )
        except requests.exceptions.ConnectionError as e:
            logger.error(f"Erro de conexão com a API Asaas: {e}")
            raise AsaasAPIError(
                message="Erro de conexão com a API Asaas",
                status_code=None,
            )
        except AsaasAPIError:
            raise
        except Exception as e:
            logger.error(f"Erro inesperado na requisição para {endpoint}: {e}")
            raise AsaasAPIError(
                message=f"Erro inesperado: {str(e)}",
                status_code=None,
            )

    def create_customer(
        self,
        name: str,
        email: Optional[str] = None,
        cpf_cnpj: Optional[str] = None,
        phone: Optional[str] = None,
        external_reference: Optional[str] = None,
        postal_code: Optional[str] = None,
        address: Optional[str] = None,
        address_number: Optional[str] = None,
        complement: Optional[str] = None,
        province: Optional[str] = None,
        city: Optional[str] = None,
        state: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Cria ou atualiza um cliente no Asaas.
        
        Args:
            name: Nome completo do cliente
            email: Email do cliente
            cpf_cnpj: CPF ou CNPJ (com ou sem formatação)
            phone: Telefone do cliente
            external_reference: Referência externa (ID do cliente no seu sistema)
            postal_code: CEP
            address: Endereço
            address_number: Número do endereço
            complement: Complemento
            province: Bairro
            city: Cidade
            state: Estado (UF)
        
        Returns:
            Dict com dados do cliente criado
        """
        payload = {"name": name}
        if email:
            payload["email"] = email
        if cpf_cnpj:
            payload["cpfCnpj"] = cpf_cnpj.replace(".", "").replace("-", "").replace("/", "")
        if phone:
            payload["phone"] = phone
        if external_reference:
            payload["externalReference"] = external_reference
        if postal_code:
            payload["postalCode"] = postal_code
        if address:
            payload["address"] = address
        if address_number:
            payload["addressNumber"] = address_number
        if complement:
            payload["complement"] = complement
        if province:
            payload["province"] = province
        if city:
            payload["city"] = city
        if state:
            payload["state"] = state
        
        response = self._request("POST", "customers", json=payload, timeout=15)
        logger.info(f"Cliente criado no Asaas: {response.json().get('id')}")
        return response.json()

    def get_customer(self, customer_id: str) -> Dict[str, Any]:
        """
        Busca um cliente pelo ID.
        
        Args:
            customer_id: ID do cliente no Asaas
        
        Returns:
            Dict com dados do cliente
        """
        response = self._request("GET", f"customers/{customer_id}", timeout=15)
        return response.json()

    def find_customer_by_cpf_cnpj(self, cpf_cnpj: str) -> Optional[Dict[str, Any]]:
        """
        Busca um cliente pelo CPF/CNPJ.
        
        Args:
            cpf_cnpj: CPF ou CNPJ (com ou sem formatação)
        
        Returns:
            Dict com dados do cliente ou None se não encontrado
        """
        cpf_cnpj_clean = cpf_cnpj.replace(".", "").replace("-", "").replace("/", "")
        response = self._request(
            "GET", "customers", params={"cpfCnpj": cpf_cnpj_clean}, timeout=15
        )
        data = response.json()
        customers = data.get("data", [])
        return customers[0] if customers else None

    def update_customer(
        self, customer_id: str, **kwargs
    ) -> Dict[str, Any]:
        """
        Atualiza dados de um cliente.
        
        Args:
            customer_id: ID do cliente no Asaas
            **kwargs: Campos para atualizar (name, email, phone, etc.)
        
        Returns:
            Dict com dados atualizados do cliente
        """
        if "cpf_cnpj" in kwargs:
            kwargs["cpfCnpj"] = kwargs.pop("cpf_cnpj").replace(".", "").replace("-", "").replace("/", "")
        
        response = self._request("PUT", f"customers/{customer_id}", json=kwargs, timeout=15)
        logger.info(f"Cliente atualizado no Asaas: {customer_id}")
        return response.json()

    def create_payment(
        self,
        customer_id: str,
        value: float,
        due_date: str,
        billing_type: str = "PIX",
        description: Optional[str] = None,
        external_reference: Optional[str] = None,
        installment_count: Optional[int] = None,
        installment_value: Optional[float] = None,
    ) -> Dict[str, Any]:
        """
        Cria uma cobrança (payment) no Asaas.
        
        Args:
            customer_id: ID do cliente no Asaas
            value: Valor da cobrança
            due_date: Data de vencimento (formato YYYY-MM-DD)
            billing_type: Tipo de cobrança ('PIX', 'BOLETO', 'CREDIT_CARD', 'DEBIT_CARD')
            description: Descrição da cobrança
            external_reference: Referência externa (ID da cobrança no seu sistema)
            installment_count: Número de parcelas (para cartão de crédito)
            installment_value: Valor de cada parcela
        
        Returns:
            Dict com dados da cobrança criada
        """
        payload = {
            "customer": customer_id,
            "value": float(value),
            "dueDate": due_date,
            "billingType": billing_type,
        }
        if description:
            payload["description"] = description
        if external_reference:
            payload["externalReference"] = external_reference
        if installment_count:
            payload["installmentCount"] = installment_count
        if installment_value:
            payload["installmentValue"] = float(installment_value)

        response = self._request("POST", "payments", json=payload, timeout=15)
        payment_data = response.json()
        logger.info(f"Pagamento criado no Asaas: {payment_data.get('id')}")
        return payment_data

    def get_payment(self, payment_id: str) -> Dict[str, Any]:
        """
        Recupera dados de um pagamento.
        
        Args:
            payment_id: ID do pagamento no Asaas
        
        Returns:
            Dict com dados do pagamento
        """
        response = self._request("GET", f"payments/{payment_id}", timeout=15)
        return response.json()

    def list_payments(
        self,
        customer: Optional[str] = None,
        subscription: Optional[str] = None,
        status: Optional[str] = None,
        limit: int = 100,
        offset: int = 0,
    ) -> Dict[str, Any]:
        """
        Lista pagamentos com filtros opcionais.
        
        Args:
            customer: Filtrar por ID do cliente
            subscription: Filtrar por ID da assinatura
            status: Filtrar por status (PENDING, CONFIRMED, RECEIVED, OVERDUE, etc.)
            limit: Quantidade de resultados por página
            offset: Offset para paginação
        
        Returns:
            Dict com lista de pagamentos e informações de paginação
        """
        params = {"limit": limit, "offset": offset}
        if customer:
            params["customer"] = customer
        if subscription:
            params["subscription"] = subscription
        if status:
            params["status"] = status

        response = self._request("GET", "payments", params=params, timeout=15)
        return response.json()

    def delete_payment(self, payment_id: str) -> Dict[str, Any]:
        """
        Remove um pagamento (apenas se ainda não foi confirmado).
        
        Args:
            payment_id: ID do pagamento no Asaas
        
        Returns:
            Dict com resultado da operação
        """
        response = self._request("DELETE", f"payments/{payment_id}", timeout=15)
        logger.info(f"Pagamento removido no Asaas: {payment_id}")
        return response.json()

    def get_pix_qr(self, payment_id: str) -> Dict[str, Any]:
        """
        Recupera o QR Code (base64) e copy/paste payload para um pagamento PIX.
        
        Args:
            payment_id: ID do pagamento no Asaas
        
        Returns:
            Dict com qrCode (base64), payload e expiresAt
        """
        response = self._request("GET", f"payments/{payment_id}/pix", timeout=15)
        return response.json()

    def get_payment_barcode(self, payment_id: str) -> Dict[str, Any]:
        """
        Recupera código de barras para pagamento via boleto.
        
        Args:
            payment_id: ID do pagamento no Asaas
        
        Returns:
            Dict com código de barras e outros dados do boleto
        """
        response = self._request("GET", f"payments/{payment_id}/identificationField", timeout=15)
        return response.json()

    def pay_with_credit_card(
        self, payment_id: str, credit_card_payload: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        Efetua pagamento com cartão de crédito.
        
        Args:
            payment_id: ID do pagamento no Asaas
            credit_card_payload: Dict com dados do cartão:
                - creditCardNumber: Número do cartão
                - creditCardHolderName: Nome do portador
                - creditCardExpiryDate: Data de expiração (MM/YYYY)
                - creditCardCvv: CVV
                - installmentCount: Número de parcelas (opcional)
        
        Returns:
            Dict com resultado do pagamento
        
        Documentation:
            https://docs.asaas.com/reference/realizar-pagamento-com-cartao-de-credito
        """
        response = self._request(
            "POST",
            f"payments/{payment_id}/pay",
            json={"creditCard": credit_card_payload},
            timeout=30,
        )
        logger.info(f"Pagamento com cartão processado: {payment_id}")
        return response.json()

    def create_subscription(
        self,
        customer_id: str,
        billing_type: str,
        value: float,
        next_due_date: str,
        cycle: str = "MONTHLY",
        description: Optional[str] = None,
        external_reference: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Cria uma assinatura recorrente.
        
        Args:
            customer_id: ID do cliente no Asaas
            billing_type: Tipo de cobrança ('PIX', 'BOLETO', 'CREDIT_CARD')
            value: Valor da assinatura
            next_due_date: Data do próximo vencimento (YYYY-MM-DD)
            cycle: Ciclo de cobrança ('WEEKLY', 'BIWEEKLY', 'MONTHLY', 'QUARTERLY', 'SEMIANNUALLY', 'YEARLY')
            description: Descrição da assinatura
            external_reference: Referência externa
        
        Returns:
            Dict com dados da assinatura criada
        """
        payload = {
            "customer": customer_id,
            "billingType": billing_type,
            "value": float(value),
            "nextDueDate": next_due_date,
            "cycle": cycle,
        }
        if description:
            payload["description"] = description
        if external_reference:
            payload["externalReference"] = external_reference

        response = self._request("POST", "subscriptions", json=payload, timeout=15)
        subscription_data = response.json()
        logger.info(f"Assinatura criada no Asaas: {subscription_data.get('id')}")
        return subscription_data

    def get_subscription(self, subscription_id: str) -> Dict[str, Any]:
        """
        Busca uma assinatura pelo ID.
        
        Args:
            subscription_id: ID da assinatura no Asaas
        
        Returns:
            Dict com dados da assinatura
        """
        response = self._request("GET", f"subscriptions/{subscription_id}", timeout=15)
        return response.json()

    def cancel_subscription(self, subscription_id: str) -> Dict[str, Any]:
        """
        Cancela uma assinatura.
        
        Args:
            subscription_id: ID da assinatura no Asaas
        
        Returns:
            Dict com resultado da operação
        """
        response = self._request("DELETE", f"subscriptions/{subscription_id}", timeout=15)
        logger.info(f"Assinatura cancelada no Asaas: {subscription_id}")
        return response.json()
