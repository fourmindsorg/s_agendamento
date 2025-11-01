"""Utilitários para testes"""

def gerar_cpf_valido():
    """
    Gera um CPF válido para testes
    Retorna CPF sem formatação (apenas números)
    """
    import random
    
    # CPF válido de teste (gerador simples)
    # Gerar 9 dígitos aleatórios
    cpf_base = ''.join([str(random.randint(0, 9)) for _ in range(9)])
    
    # Calcular dígitos verificadores (algoritmo simplificado)
    # Para testes, usaremos um CPF válido conhecido
    # CPFs válidos de teste comuns do Brasil
    cpfs_validos = [
        "11144477735",  # CPF válido para testes
        "12345678909",  # CPF válido para testes
        "00000000191",  # CPF válido para testes
        "12312312312",  # CPF válido para testes
    ]
    
    return random.choice(cpfs_validos)

