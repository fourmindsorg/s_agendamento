#!/usr/bin/env python3
"""
Script para testar a API Asaas
Executa testes completos da integração com Asaas
"""
import os
import sys
import subprocess
from pathlib import Path


def check_dependencies():
    """Verifica se as dependências estão instaladas"""
    print("🔍 Verificando dependências...")

    try:
        import django

        print("✅ Django instalado")
    except ImportError:
        print("❌ Django não instalado")
        return False

    try:
        import requests

        print("✅ Requests instalado")
    except ImportError:
        print("❌ Requests não instalado")
        return False

    return True


def setup_environment():
    """Configura o ambiente para os testes"""
    print("\n⚙️ Configurando ambiente...")

    # Define variáveis de ambiente padrão para testes
    os.environ.setdefault("DJANGO_SETTINGS_MODULE", "core.settings")
    os.environ.setdefault("ASAAS_ENV", "sandbox")

    # Verifica se há arquivo de configuração
    env_file = Path(".env.asaas")
    if env_file.exists():
        print("✅ Arquivo .env.asaas encontrado")
        # Carrega variáveis do arquivo
        with open(env_file, "r") as f:
            for line in f:
                if line.strip() and not line.startswith("#"):
                    key, value = line.strip().split("=", 1)
                    os.environ[key] = value
    else:
        print("⚠️ Arquivo .env.asaas não encontrado")
        print("Crie o arquivo baseado em env.asaas.example")


def run_tests():
    """Executa os testes da API Asaas"""
    print("\n🧪 Executando testes da API Asaas...")
    print("=" * 50)

    try:
        # Executa o script de setup e testes
        result = subprocess.run(
            [sys.executable, "financeiro/setup_asaas_tests.py"],
            capture_output=True,
            text=True,
            cwd=os.getcwd(),
        )

        print("STDOUT:")
        print(result.stdout)

        if result.stderr:
            print("\nSTDERR:")
            print(result.stderr)

        return result.returncode == 0

    except Exception as e:
        print(f"❌ Erro ao executar testes: {e}")
        return False


def run_specific_test(test_name):
    """Executa um teste específico"""
    print(f"\n🎯 Executando teste específico: {test_name}")
    print("=" * 50)

    try:
        result = subprocess.run(
            [
                sys.executable,
                "manage.py",
                "test",
                f"financeiro.test_asaas_api.{test_name}",
                "--verbosity=2",
            ],
            capture_output=True,
            text=True,
            cwd=os.getcwd(),
        )

        print("STDOUT:")
        print(result.stdout)

        if result.stderr:
            print("\nSTDERR:")
            print(result.stderr)

        return result.returncode == 0

    except Exception as e:
        print(f"❌ Erro ao executar teste: {e}")
        return False


def interactive_menu():
    """Menu interativo para escolher os testes"""
    while True:
        print("\n🔧 Menu de Testes da API Asaas")
        print("=" * 50)
        print("1. Executar todos os testes")
        print("2. Testar apenas inicialização do cliente")
        print("3. Testar criação de cliente")
        print("4. Testar criação de pagamento PIX")
        print("5. Testar obtenção de QR Code")
        print("6. Testar pagamento com cartão")
        print("7. Testar webhook")
        print("8. Testar modelo de dados")
        print("9. Testes de integração (API real)")
        print("0. Sair")

        choice = input("\nEscolha uma opção (0-9): ").strip()

        if choice == "0":
            print("👋 Saindo...")
            break
        elif choice == "1":
            run_tests()
        elif choice == "2":
            run_specific_test("AsaasAPITestCase.test_asaas_client_initialization")
        elif choice == "3":
            run_specific_test("AsaasAPITestCase.test_create_customer")
        elif choice == "4":
            run_specific_test("AsaasAPITestCase.test_create_payment_pix")
        elif choice == "5":
            run_specific_test("AsaasAPITestCase.test_get_pix_qr")
        elif choice == "6":
            run_specific_test("AsaasAPITestCase.test_pay_with_credit_card")
        elif choice == "7":
            run_specific_test("AsaasViewsTest.test_asaas_webhook_payment_received")
        elif choice == "8":
            run_specific_test("AsaasPaymentModelTest.test_create_payment_model")
        elif choice == "9":
            print("⚠️ Testes de integração requerem API key real")
            run_specific_test("AsaasIntegrationTest.test_real_api_connection")
        else:
            print("❌ Opção inválida")


def main():
    """Função principal"""
    print("🚀 Testador da API Asaas")
    print("=" * 50)

    # Verifica dependências
    if not check_dependencies():
        print("\n❌ Dependências não atendidas. Instale Django e requests.")
        sys.exit(1)

    # Configura ambiente
    setup_environment()

    # Verifica argumentos da linha de comando
    if len(sys.argv) > 1:
        if sys.argv[1] == "--interactive":
            interactive_menu()
        elif sys.argv[1] == "--quick":
            # Executa apenas testes básicos
            print("\n⚡ Executando testes rápidos...")
            run_specific_test("AsaasAPITestCase.test_asaas_client_initialization")
        else:
            # Executa teste específico
            test_name = sys.argv[1]
            run_specific_test(test_name)
    else:
        # Executa todos os testes
        success = run_tests()

        if success:
            print("\n✅ Todos os testes passaram!")
            sys.exit(0)
        else:
            print("\n❌ Alguns testes falharam.")
            sys.exit(1)


if __name__ == "__main__":
    main()
