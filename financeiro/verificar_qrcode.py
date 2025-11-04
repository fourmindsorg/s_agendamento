#!/usr/bin/env python
"""
Script para verificar se o sistema está gerando QR Code do Asaas
Execute: python manage.py shell < financeiro/verificar_qrcode.py
Ou: python -c "import django; django.setup(); exec(open('financeiro/verificar_qrcode.py').read())"
"""
import os
import sys

# Configurar Django
if 'DJANGO_SETTINGS_MODULE' not in os.environ:
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')

try:
    import django
    django.setup()
except:
    print("⚠️  Execute este script dentro do Django shell:")
    print("   python manage.py shell")
    print("   >>> exec(open('financeiro/verificar_qrcode.py').read())")
    sys.exit(1)

from financeiro.models import AsaasPayment
from financeiro.services.asaas import get_asaas_client
from financeiro.utils import generate_qr_code_from_payload

def verificar_qrcode():
    print("=" * 60)
    print("VERIFICAÇÃO DE QR CODE ASAAS")
    print("=" * 60)
    
    # 1. Verificar biblioteca qrcode
    try:
        import qrcode
        from PIL import Image
        print("✅ Biblioteca qrcode instalada")
    except ImportError as e:
        print("❌ Biblioteca qrcode NÃO instalada")
        print(f"   Erro: {e}")
        print("   Execute: pip install qrcode[pil]")
        return False
    
    # 2. Verificar cliente Asaas
    client = get_asaas_client()
    if not client:
        print("❌ Cliente Asaas não configurado")
        print("   Configure ASAAS_API_KEY no .env")
        return False
    print("✅ Cliente Asaas configurado")
    
    # 3. Verificar pagamentos no banco
    pagamentos_pix = AsaasPayment.objects.filter(billing_type="PIX").order_by('-created_at')
    print(f"\n📊 Total de pagamentos PIX no banco: {pagamentos_pix.count()}")
    
    if pagamentos_pix.count() == 0:
        print("⚠️  Nenhum pagamento PIX encontrado")
        print("   Crie um pagamento para testar")
        return True
    
    # 4. Verificar cada pagamento (máximo 5 mais recentes)
    problemas = []
    sucessos = []
    
    for payment in pagamentos_pix[:5]:
        print(f"\n--- Pagamento {payment.asaas_id} ---")
        print(f"   Status: {payment.status}")
        print(f"   Valor: R$ {payment.amount}")
        print(f"   Criado em: {payment.created_at}")
        
        # Verificar no banco
        tem_qr_base64 = bool(payment.qr_code_base64)
        tem_payload = bool(payment.copy_paste_payload)
        
        print(f"   QR Code no banco: {'✅' if tem_qr_base64 else '❌'}")
        if tem_qr_base64:
            print(f"      Tamanho: {len(payment.qr_code_base64)} caracteres")
        print(f"   Payload no banco: {'✅' if tem_payload else '❌'}")
        if tem_payload:
            print(f"      Payload: {payment.copy_paste_payload[:50]}...")
        
        # Verificar no Asaas
        try:
            qr_asaas = client.get_pix_qr(payment.asaas_id)
            tem_qr_asaas = bool(qr_asaas.get('qrCode'))
            tem_payload_asaas = bool(qr_asaas.get('payload'))
            
            print(f"   QR Code no Asaas: {'✅' if tem_qr_asaas else '❌'}")
            print(f"   Payload no Asaas: {'✅' if tem_payload_asaas else '❌'}")
            
            if qr_asaas.get('expiresAt'):
                print(f"   Expira em: {qr_asaas.get('expiresAt')}")
            
            # Se não tem QR Code mas tem payload, testar geração local
            if not tem_qr_asaas and tem_payload_asaas:
                payload = qr_asaas.get('payload')
                print(f"   Testando geração local de QR Code...")
                qr_gerado = generate_qr_code_from_payload(payload)
                if qr_gerado:
                    print(f"   ✅ Geração local: OK (QR Code pode ser gerado)")
                else:
                    print(f"   ❌ Geração local: FALHOU")
                    problemas.append(f"Pagamento {payment.asaas_id}: Não foi possível gerar QR Code localmente")
            
            # Resumo do pagamento
            if tem_qr_asaas or (tem_payload_asaas and generate_qr_code_from_payload(qr_asaas.get('payload', ''))):
                sucessos.append(payment.asaas_id)
                print(f"   ✅ Status: OK")
            else:
                problemas.append(f"Pagamento {payment.asaas_id}: Sem QR Code e sem payload válido")
                print(f"   ❌ Status: PROBLEMA")
                
        except Exception as e:
            print(f"   ❌ Erro ao verificar no Asaas: {e}")
            problemas.append(f"Pagamento {payment.asaas_id}: Erro ao buscar no Asaas - {str(e)}")
    
    # Resumo final
    print("\n" + "=" * 60)
    print("RESUMO")
    print("=" * 60)
    print(f"✅ Pagamentos com QR Code funcionando: {len(sucessos)}")
    print(f"❌ Pagamentos com problemas: {len(problemas)}")
    
    if problemas:
        print("\n⚠️  PROBLEMAS ENCONTRADOS:")
        for problema in problemas:
            print(f"   - {problema}")
        print("\n💡 SOLUÇÕES:")
        print("   1. Verificar se ASAAS_API_KEY está configurada")
        print("   2. Verificar se biblioteca qrcode está instalada: pip install qrcode[pil]")
        print("   3. Verificar logs do Django para mais detalhes")
        return False
    else:
        print("\n✅ Todos os pagamentos estão OK!")
        print("   O sistema está gerando QR Code corretamente!")
        return True

if __name__ == "__main__":
    sucesso = verificar_qrcode()
    sys.exit(0 if sucesso else 1)

