# 🔍 Como Verificar se o Sistema está Gerando QR Code do Asaas

## 📋 Resumo

Este guia mostra **como verificar** se o sistema está gerando corretamente o QR Code de cobrança do banco Asaas.

---

## ✅ Métodos de Verificação

### 1. **Verificação no Banco de Dados** (Mais Direto)

#### Verificar se há pagamentos com QR Code salvo:

```python
# No shell do Django
python manage.py shell

from financeiro.models import AsaasPayment

# Ver todos os pagamentos PIX
pagamentos = AsaasPayment.objects.filter(billing_type="PIX")

# Verificar se têm QR Code
for p in pagamentos:
    print(f"ID: {p.asaas_id}")
    print(f"  Status: {p.status}")
    print(f"  Tem QR Code Base64: {bool(p.qr_code_base64)}")
    print(f"  Tem Payload: {bool(p.copy_paste_payload)}")
    print(f"  Valor: R$ {p.amount}")
    print("---")
```

#### Verificar pagamento específico:

```python
# Buscar pagamento por ID do Asaas
payment = AsaasPayment.objects.filter(asaas_id="pay_xxxxx").first()

if payment:
    if payment.qr_code_base64:
        print("✅ QR Code está salvo no banco!")
        print(f"   Tamanho: {len(payment.qr_code_base64)} caracteres")
    else:
        print("❌ QR Code NÃO está salvo")
    
    if payment.copy_paste_payload:
        print("✅ Payload PIX está salvo!")
        print(f"   Payload: {payment.copy_paste_payload[:50]}...")
    else:
        print("❌ Payload NÃO está salvo")
else:
    print("❌ Pagamento não encontrado no banco")
```

---

### 2. **Verificação via API Asaas** (Verificar Direto na Fonte)

#### Verificar se o QR Code foi gerado no Asaas:

```python
# No shell do Django
from financeiro.services.asaas import get_asaas_client

client = get_asaas_client()

# Substituir pelo ID do pagamento real
payment_id = "pay_xxxxx"

try:
    # Buscar QR Code diretamente do Asaas
    qr_data = client.get_pix_qr(payment_id)
    
    print("=== Dados do QR Code do Asaas ===")
    print(f"Tem QR Code (base64): {bool(qr_data.get('qrCode'))}")
    print(f"Tem Payload: {bool(qr_data.get('payload'))}")
    print(f"Expira em: {qr_data.get('expiresAt', 'N/A')}")
    
    if qr_data.get('qrCode'):
        print("✅ QR Code está disponível no Asaas!")
    elif qr_data.get('payload'):
        print("⚠️  Apenas payload disponível (sistema deve gerar QR Code)")
    else:
        print("❌ QR Code não disponível no Asaas")
        
except Exception as e:
    print(f"❌ Erro ao buscar QR Code: {e}")
```

---

### 3. **Verificação via Endpoint HTTP** (Testar Criação)

#### Criar um pagamento PIX e verificar se retorna QR Code:

```bash
# POST para criar cobrança PIX
curl -X POST http://localhost:8000/financeiro/api/pix/create/ \
  -H "Content-Type: application/json" \
  -d '{
    "customer_id": "cus_xxxxx",
    "value": 10.00,
    "due_date": "2025-12-31",
    "description": "Teste QR Code"
  }'
```

**Resposta esperada:**
```json
{
  "payment_id": "pay_xxxxx",
  "qrBase64": "iVBORw0KGgoAAAANSUhEUgAA...",  // ✅ Se presente, QR Code foi gerado
  "payload": "00020126580014br.gov.bcb.pix...",  // ✅ Se presente, payload disponível
  "status": "PENDING"
}
```

**Verificações:**
- ✅ Se `qrBase64` está presente → QR Code foi gerado pelo Asaas
- ✅ Se `payload` está presente → Sistema pode gerar QR Code localmente
- ❌ Se ambos estiverem ausentes → Problema na geração

---

### 4. **Verificação na Interface Web** (Visual)

#### Acessar página de pagamento PIX:

```
http://seu-dominio.com/financeiro/<payment_id>/qr/
```

**O que verificar:**
- ✅ QR Code aparece como imagem na tela
- ✅ Código "Copia e Cola" está disponível
- ✅ Valor e descrição estão corretos

**Se não aparecer:**
1. Abrir console do navegador (F12)
2. Verificar erros JavaScript
3. Verificar se a imagem está sendo carregada:
   ```javascript
   // No console do navegador
   const img = document.querySelector('img[alt="QR Code PIX"]');
   console.log('QR Code existe?', !!img);
   console.log('Src da imagem:', img?.src?.substring(0, 50));
   ```

---

### 5. **Verificação via Logs** (Debug)

#### Verificar logs do sistema:

```python
# No shell do Django
import logging

# Ver logs relacionados ao Asaas
logger = logging.getLogger('financeiro')

# Ou verificar logs do arquivo
# (ajuste o caminho conforme sua configuração)
```

#### Verificar logs do Django:

```bash
# Se estiver rodando com runserver
# Os logs aparecerão no terminal

# Procurar por:
# - "QR Code obtido"
# - "Erro ao gerar QR Code"
# - "Não foi possível gerar QR Code"
```

---

## 🔧 Verificação Completa (Script Automatizado)

Crie um arquivo `verificar_qrcode.py`:

```python
#!/usr/bin/env python
"""
Script para verificar se o sistema está gerando QR Code do Asaas
"""
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

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
        print("✅ Biblioteca qrcode instalada")
    except ImportError:
        print("❌ Biblioteca qrcode NÃO instalada")
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
    pagamentos_pix = AsaasPayment.objects.filter(billing_type="PIX")
    print(f"\n📊 Total de pagamentos PIX no banco: {pagamentos_pix.count()}")
    
    if pagamentos_pix.count() == 0:
        print("⚠️  Nenhum pagamento PIX encontrado")
        print("   Crie um pagamento para testar")
        return True
    
    # 4. Verificar cada pagamento
    problemas = []
    sucessos = []
    
    for payment in pagamentos_pix[:5]:  # Verificar apenas os 5 mais recentes
        print(f"\n--- Pagamento {payment.asaas_id} ---")
        print(f"   Status: {payment.status}")
        print(f"   Valor: R$ {payment.amount}")
        
        # Verificar no banco
        tem_qr_base64 = bool(payment.qr_code_base64)
        tem_payload = bool(payment.copy_paste_payload)
        
        print(f"   QR Code no banco: {'✅' if tem_qr_base64 else '❌'}")
        print(f"   Payload no banco: {'✅' if tem_payload else '❌'}")
        
        # Verificar no Asaas
        try:
            qr_asaas = client.get_pix_qr(payment.asaas_id)
            tem_qr_asaas = bool(qr_asaas.get('qrCode'))
            tem_payload_asaas = bool(qr_asaas.get('payload'))
            
            print(f"   QR Code no Asaas: {'✅' if tem_qr_asaas else '❌'}")
            print(f"   Payload no Asaas: {'✅' if tem_payload_asaas else '❌'}")
            
            # Se não tem QR Code mas tem payload, testar geração local
            if not tem_qr_asaas and tem_payload_asaas:
                payload = qr_asaas.get('payload')
                qr_gerado = generate_qr_code_from_payload(payload)
                if qr_gerado:
                    print(f"   Geração local: ✅ (QR Code pode ser gerado)")
                else:
                    print(f"   Geração local: ❌ (Erro ao gerar)")
                    problemas.append(f"Pagamento {payment.asaas_id}: Não foi possível gerar QR Code localmente")
            
            if tem_qr_asaas or tem_payload_asaas:
                sucessos.append(payment.asaas_id)
            else:
                problemas.append(f"Pagamento {payment.asaas_id}: Sem QR Code e sem payload")
                
        except Exception as e:
            print(f"   ❌ Erro ao verificar no Asaas: {e}")
            problemas.append(f"Pagamento {payment.asaas_id}: Erro ao buscar no Asaas - {e}")
    
    # Resumo
    print("\n" + "=" * 60)
    print("RESUMO")
    print("=" * 60)
    print(f"✅ Pagamentos com QR Code: {len(sucessos)}")
    print(f"❌ Pagamentos com problemas: {len(problemas)}")
    
    if problemas:
        print("\n⚠️  PROBLEMAS ENCONTRADOS:")
        for problema in problemas:
            print(f"   - {problema}")
        return False
    else:
        print("\n✅ Todos os pagamentos estão OK!")
        return True

if __name__ == "__main__":
    sucesso = verificar_qrcode()
    exit(0 if sucesso else 1)
```

**Executar:**
```bash
python verificar_qrcode.py
```

---

## 📊 Checklist de Verificação Rápida

### ✅ Pré-requisitos:
- [ ] Biblioteca `qrcode[pil]` instalada (`pip list | grep qrcode`)
- [ ] `ASAAS_API_KEY` configurada no `.env`
- [ ] Cliente Asaas inicializando corretamente

### ✅ Funcionalidade:
- [ ] Pagamento PIX é criado no Asaas
- [ ] QR Code é obtido do Asaas (ou payload)
- [ ] QR Code é salvo no banco (`AsaasPayment.qr_code_base64`)
- [ ] Payload é salvo no banco (`AsaasPayment.copy_paste_payload`)
- [ ] QR Code aparece na interface web

### ✅ Fallback:
- [ ] Se Asaas não retornar imagem, sistema gera localmente
- [ ] QR Code gerado localmente funciona corretamente

---

## 🚨 Problemas Comuns e Soluções

### Problema 1: QR Code não aparece no banco
**Causa**: API Asaas não retornou QR Code
**Solução**: Verificar se `copy_paste_payload` está salvo. Se estiver, o sistema deve gerar automaticamente.

### Problema 2: Erro "No module named 'qrcode'"
**Causa**: Biblioteca não instalada
**Solução**: `pip install qrcode[pil]`

### Problema 3: QR Code não aparece na tela
**Causa**: Template não está renderizando corretamente
**Solução**: Verificar template `financeiro/pix_qr.html` e logs do navegador

### Problema 4: Payload não está sendo salvo
**Causa**: Erro na chamada `client.get_pix_qr()`
**Solução**: Verificar logs do Django e conexão com API Asaas

---

## 📝 Comandos Úteis

### Verificar se biblioteca está instalada:
```bash
pip list | grep qrcode
# Deve mostrar: qrcode 7.4.2 (ou similar)
```

### Testar geração de QR Code manualmente:
```python
from financeiro.utils import generate_qr_code_from_payload

payload = "00020126580014br.gov.bcb.pix0136..."
qr = generate_qr_code_from_payload(payload)
print("QR Code gerado!" if qr else "Erro ao gerar")
```

### Ver pagamentos no banco:
```bash
python manage.py shell
>>> from financeiro.models import AsaasPayment
>>> AsaasPayment.objects.filter(billing_type="PIX").values('asaas_id', 'qr_code_base64', 'copy_paste_payload')
```

---

**Última atualização**: Janeiro 2025

