#!/usr/bin/env python3
"""
Script para configurar e executar testes da API Asaas
"""
import os
import sys
import django
from django.conf import settings


def setup_django():
    """Configura Django para execução dos testes"""
    os.environ.setdefault("DJANGO_SETTINGS_MODULE", "core.settings")
    django.setup()


def check_asaas_configuration():
    """Verifica se as configurações da API Asaas estão corretas"""
    print("🔍 Verificando configurações da API Asaas...")
    print("=" * 50)

    # Verifica variáveis de ambiente
    configs = {
        "ASAAS_API_KEY": os.environ.get("ASAAS_API_KEY"),
        "ASAAS_ENV": os.environ.get("ASAAS_ENV", "sandbox"),
        "ASAAS_WEBHOOK_TOKEN": os.environ.get("ASAAS_WEBHOOK_TOKEN"),
    }

    for key, value in configs.items():
        if value:
            if key == "ASAAS_API_KEY":
                # Mascarar a chave por segurança
                masked_value = (
                    f"{value[:8]}...{value[-4:]}" if len(value) > 12 else "***"
                )
                print(f"✅ {key}: {masked_value}")
            else:
                print(f"✅ {key}: {value}")
        else:
            print(f"❌ {key}: NÃO CONFIGURADO")

    print("\n📋 Configurações necessárias:")
    print("- ASAAS_API_KEY: Sua chave da API Asaas")
    print("- ASAAS_ENV: 'sandbox' ou 'production'")
    print("- ASAAS_WEBHOOK_TOKEN: Token para validar webhooks")

    return all(configs.values())


def create_test_data():
    """Cria dados de teste para os testes da API"""
    print("\n📝 Criando dados de teste...")

    # Dados de teste para cliente
    test_customer = {
        "name": "Cliente Teste API",
        "email": "cliente.teste@example.com",
        "cpf_cnpj": "12345678901",
        "phone": "11999999999",
    }

    # Dados de teste para pagamento
    from datetime import datetime, timedelta

    test_payment = {
        "value": 50.00,
        "due_date": (datetime.now() + timedelta(days=7)).strftime("%Y-%m-%d"),
        "billing_type": "PIX",
        "description": "Teste de integração API Asaas",
    }

    print("✅ Dados de teste criados")
    return test_customer, test_payment


def run_basic_tests():
    """Executa testes básicos da API"""
    print("\n🧪 Executando testes básicos...")
    print("=" * 50)

    try:
        from financeiro.services.asaas import AsaasClient

        # Testa inicialização do cliente
        client = AsaasClient()
        print("✅ Cliente Asaas inicializado")

        # Testa URL base
        print(f"✅ URL Base: {client.base}")
        print(f"✅ Ambiente: {client.env}")

        return True

    except Exception as e:
        print(f"❌ Erro nos testes básicos: {e}")
        return False


def run_unit_tests():
    """Executa testes unitários"""
    print("\n🔬 Executando testes unitários...")
    print("=" * 50)

    try:
        from django.test.utils import get_runner
        from django.conf import settings

        TestRunner = get_runner(settings)
        test_runner = TestRunner()

        # Executa apenas os testes da API Asaas
        failures = test_runner.run_tests(["financeiro.test_asaas_api"])

        if failures == 0:
            print("✅ Todos os testes unitários passaram!")
            return True
        else:
            print(f"❌ {failures} teste(s) falharam")
            return False

    except Exception as e:
        print(f"❌ Erro ao executar testes: {e}")
        return False


def run_integration_tests():
    """Executa testes de integração com API real"""
    print("\n🌐 Executando testes de integração...")
    print("=" * 50)

    # Verifica se a API key está configurada
    api_key = os.environ.get("ASAAS_API_KEY")
    if not api_key or api_key.startswith("sk_test_"):
        print("⚠️ API key não configurada ou é de teste")
        print("Configure ASAAS_API_KEY para testes de integração reais")
        return False

    try:
        from financeiro.services.asaas import AsaasClient
        import requests

        client = AsaasClient()

        # Testa conectividade básica
        print("🔗 Testando conectividade com API Asaas...")

        # Cria cliente de teste
        test_customer, test_payment = create_test_data()

        print("📝 Criando cliente de teste...")
        customer = client.create_customer(**test_customer)
        print(f"✅ Cliente criado: {customer['id']}")

        # Cria pagamento de teste
        print("💰 Criando pagamento de teste...")
        test_payment["customer_id"] = customer["id"]
        payment = client.create_payment(**test_payment)
        print(f"✅ Pagamento criado: {payment['id']}")

        # Obtém QR Code
        print("📱 Obtendo QR Code PIX...")
        qr_data = client.get_pix_qr(payment["id"])
        print("✅ QR Code obtido com sucesso")

        print("\n🎉 Testes de integração concluídos com sucesso!")
        print(f"Cliente ID: {customer['id']}")
        print(f"Pagamento ID: {payment['id']}")

        return True

    except requests.exceptions.RequestException as e:
        print(f"❌ Erro de conexão com API: {e}")
        return False
    except Exception as e:
        print(f"❌ Erro nos testes de integração: {e}")
        return False


def generate_test_report():
    """Gera relatório de testes"""
    print("\n📊 Relatório de Testes da API Asaas")
    print("=" * 50)

    # Verifica configurações
    config_ok = check_asaas_configuration()

    # Executa testes básicos
    basic_ok = run_basic_tests()

    # Executa testes unitários
    unit_ok = run_unit_tests()

    # Executa testes de integração
    integration_ok = run_integration_tests()

    # Resumo
    print("\n📋 RESUMO DOS TESTES")
    print("=" * 50)
    print(f"Configurações: {'✅ OK' if config_ok else '❌ FALHOU'}")
    print(f"Testes Básicos: {'✅ OK' if basic_ok else '❌ FALHOU'}")
    print(f"Testes Unitários: {'✅ OK' if unit_ok else '❌ FALHOU'}")
    print(f"Testes Integração: {'✅ OK' if integration_ok else '❌ FALHOU'}")

    if all([config_ok, basic_ok, unit_ok]):
        print("\n🎉 API Asaas configurada e funcionando corretamente!")
        return True
    else:
        print("\n⚠️ Alguns testes falharam. Verifique as configurações.")
        return False


def main():
    """Função principal"""
    print("🚀 Setup e Testes da API Asaas")
    print("=" * 50)

    # Configura Django
    setup_django()

    # Executa relatório completo
    success = generate_test_report()

    if success:
        print("\n✅ Setup concluído com sucesso!")
        sys.exit(0)
    else:
        print("\n❌ Setup falhou. Verifique os erros acima.")
        sys.exit(1)


if __name__ == "__main__":
    main()
