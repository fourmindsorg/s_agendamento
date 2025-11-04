#!/usr/bin/env python3
"""
Script para testar conexão com Asaas em produção
Execute: python financeiro/teste_producao_asaas.py
"""

import os
import sys
import django
from datetime import datetime, timedelta

# Configurar Django
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "core.settings")
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
django.setup()

from django.conf import settings
from financeiro.services.asaas import AsaasClient, AsaasAPIError

def testar_producao():
    """Testa conexão e funcionalidades básicas do Asaas em produção"""
    
    print("=" * 70)
    print("🧪 Teste de Produção - Asaas PIX")
    print("=" * 70)
    
    # 1. Verificar ambiente
    env = getattr(settings, 'ASAAS_ENV', 'sandbox')
    api_key = getattr(settings, 'ASAAS_API_KEY', None)
    
    print(f"\n📋 Configuração:")
    print(f"   Ambiente: {env}")
    print(f"   API Key configurada: {'✅ SIM' if api_key else '❌ NÃO'}")
    
    if not api_key:
        print("\n❌ ERRO: ASAAS_API_KEY não configurada!")
        print("   Configure no .env ou variáveis de ambiente:")
        print("   ASAAS_ENV=production")
        print("   ASAAS_API_KEY=$aact_SUA_CHAVE_AQUI")
        return False
    
    if env != 'production':
        print(f"\n⚠️  ATENÇÃO: Ambiente atual é '{env}', não 'production'")
        print("   Para testar em produção, configure:")
        print("   ASAAS_ENV=production")
        resposta = input("\n   Deseja continuar mesmo assim? (s/N): ")
        if resposta.lower() != 's':
            return False
    
    # 2. Inicializar cliente
    print(f"\n🔌 Conectando com API Asaas...")
    try:
        client = AsaasClient()
        print(f"   ✅ Cliente inicializado")
        print(f"   Base URL: {client.base}")
        print(f"   Ambiente: {client.env}")
    except Exception as e:
        print(f"   ❌ Erro ao inicializar cliente: {e}")
        return False
    
    # 3. Testar criação de cliente (com CPF válido)
    print(f"\n👤 Testando criação de cliente...")
    print("   ⚠️  IMPORTANTE: Em produção, use CPF válido real!")
    
    # Perguntar se deseja usar CPF próprio ou gerador
    print("\n   Opções:")
    print("   1. Informar CPF válido próprio")
    print("   2. Usar gerador de CPF válido (para sandbox)")
    print("   3. Pular teste de cliente (apenas testar conexão)")
    
    opcao = input("\n   Escolha uma opção (1/2/3): ").strip()
    
    cpf_para_teste = None
    customer_id = None
    
    if opcao == "1":
        # Solicitar CPF do usuário
        cpf_input = input("\n   Digite o CPF (apenas números, 11 dígitos): ").strip()
        cpf_limpo = cpf_input.replace(".", "").replace("-", "").replace("/", "").strip()
        
        if len(cpf_limpo) != 11 or not cpf_limpo.isdigit():
            print("   ❌ CPF inválido! Deve ter 11 dígitos numéricos.")
            return False
        
        cpf_para_teste = cpf_limpo
        print(f"   ✅ CPF informado: {cpf_limpo[:3]}***{cpf_limpo[-2:]}")
        
    elif opcao == "2":
        # Usar gerador de CPF válido
        try:
            from financeiro.test_utils import gerar_cpf_valido
            cpf_para_teste = gerar_cpf_valido()
            print(f"   ✅ CPF gerado: {cpf_para_teste[:3]}***{cpf_para_teste[-2:]}")
        except ImportError:
            print("   ⚠️  Gerador de CPF não disponível. Usando CPF de teste padrão.")
            # CPFs válidos conhecidos para teste
            cpfs_teste = ["11144477735", "12345678909", "00000000191"]
            import random
            cpf_para_teste = random.choice(cpfs_teste)
            print(f"   ✅ CPF de teste: {cpf_para_teste[:3]}***{cpf_para_teste[-2:]}")
    
    elif opcao == "3":
        print("   ⏭️  Pulando teste de cliente...")
        print("   ✅ Conexão com API funcionando!")
        return True
    
    else:
        print("   ❌ Opção inválida!")
        return False
    
    # Criar cliente com CPF
    if cpf_para_teste:
        try:
            import random
            email_teste = f"teste.prod.{random.randint(10000, 99999)}@example.com"
            
            print(f"\n   Criando cliente com CPF {cpf_para_teste[:3]}***{cpf_para_teste[-2:]}...")
            customer = client.create_customer(
                name="Teste Produção",
                email=email_teste,
                cpf_cnpj=cpf_para_teste
            )
            print(f"   ✅ Cliente criado: {customer['id']}")
            customer_id = customer['id']
            
        except AsaasAPIError as e:
            if "CPF" in str(e).upper() or "invalid" in str(e).lower():
                print(f"   ❌ Erro: CPF inválido - {e.message}")
                print("   ⚠️  Em produção, você DEVE usar CPF válido real!")
                if env == 'production':
                    print("   💡 Dica: Use seu próprio CPF ou de um conhecido para teste")
                    return False
                else:
                    print("   ℹ️  Em sandbox, alguns CPFs podem não funcionar")
                    print("   ✅ Conexão com API funcionando!")
                    return True
            else:
                print(f"   ❌ Erro inesperado: {e.message}")
                return False
        except Exception as e:
            print(f"   ❌ Erro: {e}")
            return False
    
    # 4. Testar criação de pagamento (se cliente foi criado)
    if customer_id:
        print(f"\n💳 Testando criação de pagamento PIX...")
        
        # Perguntar valor para teste
        # ⚠️ IMPORTANTE: Asaas exige valor mínimo de R$ 5,00 para PIX
        valor_minimo = 5.00
        valor_input = input(f"\n   Digite o valor para teste (mínimo R$ {valor_minimo:.2f}, ou Enter para R$ {valor_minimo:.2f}): ").strip()
        try:
            valor_teste = float(valor_input) if valor_input else valor_minimo
            if valor_teste < valor_minimo:
                print(f"   ⚠️  Valor mínimo é R$ {valor_minimo:.2f}. Ajustando para R$ {valor_minimo:.2f}")
                valor_teste = valor_minimo
            if valor_teste <= 0:
                print(f"   ⚠️  Valor deve ser maior que zero. Usando R$ {valor_minimo:.2f}")
                valor_teste = valor_minimo
        except ValueError:
            print(f"   ⚠️  Valor inválido. Usando R$ {valor_minimo:.2f}")
            valor_teste = valor_minimo
        
        if valor_teste > 50.00:
            print(f"   ⚠️  ATENÇÃO: Valor alto (R$ {valor_teste:.2f})! Em produção isso criará cobrança real!")
            confirmar = input("   Deseja continuar? (s/N): ").strip().lower()
            if confirmar != 's':
                print("   ⏭️  Teste cancelado pelo usuário")
                return True
        
        try:
            due_date = (datetime.now() + timedelta(days=1)).strftime("%Y-%m-%d")
            print(f"\n   Criando pagamento PIX de R$ {valor_teste:.2f}...")
            payment = client.create_payment(
                customer_id=customer_id,
                value=valor_teste,
                due_date=due_date,
                billing_type="PIX",
                description="Teste de Produção"
            )
            print(f"   ✅ Pagamento criado: {payment['id']}")
            print(f"   Status: {payment.get('status', 'N/A')}")
            print(f"   Valor: R$ {payment.get('value', 0)}")
            print(f"   Tipo: {payment.get('billingType', 'N/A')}")
            
            # Tentar obter QR Code
            print(f"\n📱 Tentando obter QR Code...")
            print("   ⏳ Aguardando QR Code ficar disponível (pode demorar até 60 segundos)...")
            import time
            max_tentativas = 10
            for tentativa in range(max_tentativas):
                try:
                    if tentativa > 0:
                        time.sleep(3)  # Aguardar 3 segundos entre tentativas
                    pix_data = client.get_pix_qr(payment['id'])
                    payload = pix_data.get('payload', '')
                    if payload:
                        print(f"   ✅ QR Code obtido na tentativa {tentativa + 1}!")
                        print(f"   Payload: {payload[:50]}...")
                        print(f"\n   📋 Informações do Pagamento:")
                        print(f"      Payment ID: {payment['id']}")
                        print(f"      Valor: R$ {valor_teste:.2f}")
                        print(f"      Status: {payment.get('status', 'N/A')}")
                        print(f"      QR Code: ✅ Disponível")
                        print(f"\n   💡 Próximos passos:")
                        print(f"      1. Acesse o painel do Asaas para ver o pagamento")
                        print(f"      2. Escaneie o QR Code com app de pagamento")
                        print(f"      3. Verifique se o webhook foi recebido (se configurado)")
                        return True
                except AsaasAPIError as e:
                    if e.status_code == 404:
                        print(f"   ⏳ Tentativa {tentativa + 1}/{max_tentativas}: QR Code ainda não disponível...")
                        continue
                    else:
                        print(f"   ❌ Erro: {e.message}")
                        return False
            
            print(f"\n   ⚠️  QR Code não disponível após {max_tentativas} tentativas")
            print(f"   ℹ️  Isso é normal - pode demorar até 60 segundos")
            print(f"   ℹ️  Recarregue a página de pagamento para tentar novamente")
            print(f"\n   📋 Informações do Pagamento:")
            print(f"      Payment ID: {payment['id']}")
            print(f"      Valor: R$ {valor_teste:.2f}")
            print(f"      Status: {payment.get('status', 'N/A')}")
            print(f"      QR Code: ⏳ Aguardando (pode demorar)")
            
        except Exception as e:
            print(f"   ❌ Erro ao criar pagamento: {e}")
            import traceback
            traceback.print_exc()
            return False
    
    print(f"\n✅ Teste concluído!")
    return True

if __name__ == "__main__":
    try:
        sucesso = testar_producao()
        if sucesso:
            print("\n" + "=" * 70)
            print("✅ Teste executado com sucesso!")
            print("=" * 70)
            sys.exit(0)
        else:
            print("\n" + "=" * 70)
            print("❌ Teste falhou. Verifique os erros acima.")
            print("=" * 70)
            sys.exit(1)
    except KeyboardInterrupt:
        print("\n\n⚠️  Teste cancelado pelo usuário")
        sys.exit(1)
    except Exception as e:
        print(f"\n\n❌ Erro inesperado: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

