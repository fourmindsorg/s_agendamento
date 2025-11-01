"""
Validadores de segurança para dados da API Asaas
"""

import re
from datetime import datetime
from decimal import Decimal, InvalidOperation
from typing import Optional, Tuple, Any
from django.core.exceptions import ValidationError


class SecurityValidator:
    """Validador de segurança para dados de entrada"""

    # Limites de tamanho
    MAX_DESCRIPTION_LENGTH = 5000  # 5KB
    MAX_CUSTOMER_ID_LENGTH = 100
    MAX_PAYMENT_ID_LENGTH = 100
    MAX_REQUEST_SIZE = 1024 * 100  # 100KB

    # Padrões permitidos
    CUSTOMER_ID_PATTERN = re.compile(r'^[a-zA-Z0-9_\-]+$')
    PAYMENT_ID_PATTERN = re.compile(r'^[a-zA-Z0-9_\-]+$')
    DATE_PATTERN = re.compile(r'^\d{4}-\d{2}-\d{2}$')

    @staticmethod
    def validate_customer_id(customer_id: Any) -> Tuple[bool, Optional[str]]:
        """
        Valida ID de cliente.
        
        Returns:
            Tuple[bool, Optional[str]]: (is_valid, error_message)
        """
        if not customer_id:
            return False, "customer_id é obrigatório"
        
        customer_id = str(customer_id).strip()
        
        if len(customer_id) > SecurityValidator.MAX_CUSTOMER_ID_LENGTH:
            return False, f"customer_id muito longo (máximo {SecurityValidator.MAX_CUSTOMER_ID_LENGTH} caracteres)"
        
        if not SecurityValidator.CUSTOMER_ID_PATTERN.match(customer_id):
            return False, "customer_id contém caracteres inválidos"
        
        # Verificar padrões perigosos
        dangerous_patterns = [
            r'<script',
            r'javascript:',
            r'onerror=',
            r'onload=',
            r'\.\./',  # Path traversal
            r';',  # SQL injection attempt
            r'--',  # SQL comment
            r'union\s+select',  # SQL injection
        ]
        
        customer_id_lower = customer_id.lower()
        for pattern in dangerous_patterns:
            if re.search(pattern, customer_id_lower, re.IGNORECASE):
                return False, "customer_id contém padrões inválidos"
        
        return True, None

    @staticmethod
    def validate_payment_id(payment_id: Any) -> Tuple[bool, Optional[str]]:
        """
        Valida ID de pagamento.
        
        Returns:
            Tuple[bool, Optional[str]]: (is_valid, error_message)
        """
        if not payment_id:
            return False, "payment_id é obrigatório"
        
        payment_id = str(payment_id).strip()
        
        if len(payment_id) > SecurityValidator.MAX_PAYMENT_ID_LENGTH:
            return False, f"payment_id muito longo (máximo {SecurityValidator.MAX_PAYMENT_ID_LENGTH} caracteres)"
        
        if not SecurityValidator.PAYMENT_ID_PATTERN.match(payment_id):
            return False, "payment_id contém caracteres inválidos"
        
        return True, None

    @staticmethod
    def validate_amount(value: Any) -> Tuple[bool, Optional[str], Optional[Decimal]]:
        """
        Valida valor monetário.
        
        Returns:
            Tuple[bool, Optional[str], Optional[Decimal]]: (is_valid, error_message, decimal_value)
        """
        if value is None:
            return False, "value é obrigatório", None
        
        try:
            # Converter para float primeiro para aceitar int e float
            float_value = float(value)
            
            # Verificar se é número válido
            if not (float_value == float_value):  # NaN check
                return False, "value não é um número válido", None
            
            if float_value != float_value or abs(float_value) == float('inf'):
                return False, "value não é um número válido", None
            
            # Verificar se é positivo
            if float_value <= 0:
                return False, "value deve ser maior que zero", None
            
            # Verificar se não é muito grande
            if float_value > 999999999.99:
                return False, "value muito grande (máximo 999.999.999,99)", None
            
            # Converter para Decimal com 2 casas decimais
            decimal_value = Decimal(str(float_value)).quantize(Decimal('0.01'))
            
            return True, None, decimal_value
            
        except (ValueError, TypeError, InvalidOperation) as e:
            return False, f"value inválido: {str(e)}", None

    @staticmethod
    def validate_due_date(due_date: Any) -> Tuple[bool, Optional[str]]:
        """
        Valida data de vencimento.
        
        Returns:
            Tuple[bool, Optional[str]]: (is_valid, error_message)
        """
        if not due_date:
            return False, "due_date é obrigatório"
        
        due_date = str(due_date).strip()
        
        # Verificar formato
        if not SecurityValidator.DATE_PATTERN.match(due_date):
            return False, "due_date deve estar no formato YYYY-MM-DD"
        
        try:
            # Tentar parsear a data
            date_obj = datetime.strptime(due_date, "%Y-%m-%d").date()
            
            # Verificar se não é muito antiga (mais de 10 anos)
            min_date = datetime.now().date().replace(year=datetime.now().year - 10)
            if date_obj < min_date:
                return False, "due_date muito antiga"
            
            # Verificar se não é muito futura (mais de 10 anos)
            max_date = datetime.now().date().replace(year=datetime.now().year + 10)
            if date_obj > max_date:
                return False, "due_date muito futura"
            
            return True, None
            
        except ValueError:
            return False, "due_date inválida"

    @staticmethod
    def validate_description(description: Optional[Any]) -> Tuple[bool, Optional[str], Optional[str]]:
        """
        Valida descrição, sanitizando conteúdo perigoso.
        
        Returns:
            Tuple[bool, Optional[str], Optional[str]]: (is_valid, error_message, sanitized_description)
        """
        if description is None:
            return True, None, None
        
        description = str(description)
        
        # Verificar tamanho
        if len(description) > SecurityValidator.MAX_DESCRIPTION_LENGTH:
            return False, f"description muito longa (máximo {SecurityValidator.MAX_DESCRIPTION_LENGTH} caracteres)", None
        
        # Remover padrões perigosos (sanitização básica)
        sanitized = description
        
        # Remover tags HTML perigosas
        dangerous_tags = [
            r'<script[^>]*>.*?</script>',
            r'<iframe[^>]*>.*?</iframe>',
            r'javascript:',
            r'onerror\s*=',
            r'onload\s*=',
            r'onclick\s*=',
        ]
        
        for pattern in dangerous_tags:
            sanitized = re.sub(pattern, '', sanitized, flags=re.IGNORECASE | re.DOTALL)
        
        return True, None, sanitized

    @staticmethod
    def validate_request_size(body: bytes) -> Tuple[bool, Optional[str]]:
        """
        Valida tamanho da requisição.
        
        Returns:
            Tuple[bool, Optional[str]]: (is_valid, error_message)
        """
        if len(body) > SecurityValidator.MAX_REQUEST_SIZE:
            return False, f"Requisição muito grande (máximo {SecurityValidator.MAX_REQUEST_SIZE / 1024}KB)"
        return True, None

    @staticmethod
    def sanitize_string(value: Any) -> str:
        """
        Sanitiza string removendo caracteres perigosos.
        
        Args:
            value: Valor a ser sanitizado
        
        Returns:
            String sanitizada
        """
        if value is None:
            return ""
        
        value = str(value)
        
        # Remover caracteres de controle exceto quebras de linha e tabs
        value = re.sub(r'[\x00-\x08\x0B-\x0C\x0E-\x1F\x7F]', '', value)
        
        return value.strip()

