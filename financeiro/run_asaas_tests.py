#!/usr/bin/env python3
"""
Script para executar testes funcionais da API Asaas

Uso:
    python financeiro/run_asaas_tests.py
    python financeiro/run_asaas_tests.py --quick  # Apenas testes que não precisam de API
    python financeiro/run_asaas_tests.py --all    # Todos os testes (requer API key)
"""

import os
import sys

# Adicionar diretório do projeto ao path
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, BASE_DIR)

import django
from django.conf import settings

# Configurar Django
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "core.settings")
django.setup()

from django.test.utils import get_runner
from django.conf import settings


def check_api_key():
    """Verifica se a chave de API está configurada"""
    api_key = getattr(settings, "ASAAS_API_KEY", None)
    if not api_key:
        print("[AVISO] ASAAS_API_KEY nao configurada no .env")
        print("        Configure antes de executar testes que precisam da API")
        return False
    return True


def run_tests(quick=False):
    """Executa os testes"""
    TestRunner = get_runner(settings)
    test_runner = TestRunner(verbosity=2, keepdb=True)
    
    if quick:
        # Apenas testes que não precisam de API
        test_names = [
            "financeiro.test_asaas_functional.AsaasFunctionalTestCase.test_asaas_client_initialization",
            "financeiro.test_asaas_functional.AsaasFunctionalTestCase.test_environment_configuration",
            "financeiro.test_asaas_functional.AsaasFunctionalTestCase.test_api_key_format",
            "financeiro.test_asaas_functional.AsaasFunctionalTestCase.test_asaas_payment_model_creation",
            "financeiro.test_asaas_functional.AsaasFunctionalTestCase.test_qr_code_generation_from_payload",
            "financeiro.test_asaas_functional.AsaasFunctionalTestCase.test_invalid_customer_data",
            "financeiro.test_asaas_functional.AsaasFunctionalTestCase.test_error_handling_invalid_payment_id",
            "financeiro.test_asaas_functional.AsaasFunctionalTestCase.test_error_handling_invalid_customer_id",
            "financeiro.test_asaas_functional.AsaasFunctionalTestCase.test_webhook_endpoint_structure",
        ]
        print("Executando testes rapidos (nao precisam de API)...")
    else:
        # Todos os testes
        if not check_api_key():
            print("\n[ERRO] Configure ASAAS_API_KEY antes de executar todos os testes")
            print("       Use --quick para executar apenas testes que nao precisam de API")
            return False
        
        test_names = ["financeiro.test_asaas_functional"]
        print("Executando todos os testes (precisa de API key valida)...")
    
    failures = test_runner.run_tests(test_names)
    
    if failures == 0:
        print("\n[OK] Todos os testes passaram!")
        return True
    else:
        print(f"\n[ERRO] {failures} teste(s) falharam")
        return False


def main():
    """Função principal"""
    print("=" * 60)
    print("Testes Funcionais - API Asaas")
    print("=" * 60)
    
    quick = "--quick" in sys.argv
    all_tests = "--all" in sys.argv
    
    if quick:
        success = run_tests(quick=True)
    elif all_tests:
        success = run_tests(quick=False)
    else:
        # Padrão: executar testes que não precisam de API
        print("[INFO] Executando testes rapidos por padrao")
        print("       Use --all para executar todos os testes (requer API key)")
        print("       Use --quick para executar apenas testes rapidos\n")
        success = run_tests(quick=True)
    
    print("\n" + "=" * 60)
    if success:
        print("SUCESSO: Testes concluidos")
        sys.exit(0)
    else:
        print("ERRO: Alguns testes falharam")
        sys.exit(1)


if __name__ == "__main__":
    main()

