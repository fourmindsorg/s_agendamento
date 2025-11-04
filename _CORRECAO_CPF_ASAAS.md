# ✅ Correção: CPF Inválido no Asaas - QR Code não Gerado

## 🔍 Problema Identificado

O sistema estava gerando erro ao criar cliente no Asaas:
```
ERROR:financeiro.services.asaas:Erro na API Asaas [400]: customers - 
{'errors': [{'code': 'invalid_object', 'description': 'O CPF/CNPJ informado é inválido.'}]}
```

**Causa**: O CPF estava sendo enviado como `"00000000000"` (hardcoded) em vez de usar o CPF do formulário.

## ✅ Correções Aplicadas

### 1. **Salvar Dados de Cobrança na Sessão** (`authentication/views.py` linha 944-947)
```python
# Salvar dados de cobrança na sessão para usar na página de pagamento
request.session["billing_data"] = billing_data
request.session["cpf_temporario"] = billing_data.get("cpf", "")
request.session["telefone_temporario"] = billing_data.get("telefone", "")
```

### 2. **Recuperar Dados de Cobrança na PaymentPixView** (linha 992-1021)
- Recupera dados da sessão
- Tenta buscar CPF do modelo Cliente como fallback
- Valida que o CPF está presente e válido antes de prosseguir
- Redireciona para checkout se CPF não estiver disponível

### 3. **Validação e Limpeza do CPF Antes de Enviar ao Asaas** (linha 1108-1116)
```python
# Limpar e validar CPF antes de enviar ao Asaas
cpf_limpo = billing_data.get("cpf", "").replace(".", "").replace("-", "").replace("/", "").strip()

# Validar que o CPF tem 11 dígitos
if not cpf_limpo or len(cpf_limpo) != 11 or not cpf_limpo.isdigit():
    raise ValueError(
        f"CPF inválido: '{billing_data.get('cpf', '')}'. "
        f"O CPF deve ter 11 dígitos numéricos."
    )
```

### 4. **Limpeza do Telefone** (linha 1119)
```python
telefone_limpo = billing_data.get("telefone", "").replace("(", "").replace(")", "").replace("-", "").replace(" ", "").strip()
```

## 🎯 Resultado Esperado

Agora o sistema:
1. ✅ Salva o CPF do formulário na sessão
2. ✅ Recupera o CPF correto na página de pagamento
3. ✅ Valida o CPF antes de enviar ao Asaas
4. ✅ Envia CPF no formato correto (apenas números, 11 dígitos)
5. ✅ Gera QR Code corretamente após criar cliente e pagamento no Asaas

## 🧪 Como Testar

1. **Acesse o checkout** e preencha o formulário com CPF válido
2. **Selecione PIX** como método de pagamento
3. **Finalize o checkout**
4. **Verifique se o QR Code aparece** na página de pagamento

### Verificar nos Logs:
- ✅ Não deve aparecer mais erro "CPF/CNPJ informado é inválido"
- ✅ Deve aparecer "Cliente criado no Asaas"
- ✅ Deve aparecer "Pagamento criado no Asaas"

### Verificar no Banco:
```python
python manage.py shell
>>> from financeiro.models import AsaasPayment
>>> payment = AsaasPayment.objects.filter(billing_type="PIX").last()
>>> print(f"Payment ID: {payment.asaas_id}")
>>> print(f"Tem QR Code: {bool(payment.qr_code_base64)}")
>>> print(f"Tem Payload: {bool(payment.copy_paste_payload)}")
```

## 📝 Notas Importantes

- O CPF é validado no formulário (`BillingInfoForm.clean_cpf()`)
- O CPF é limpo novamente antes de enviar ao Asaas (garantir formato)
- Se o CPF não estiver disponível, o usuário é redirecionado para preencher novamente
- O sistema tenta buscar CPF do modelo `Cliente` como fallback

## ⚠️ Se Ainda Não Funcionar

1. **Verificar se o CPF está sendo salvo na sessão**:
   ```python
   # No shell do Django, durante uma sessão ativa
   request.session.get("billing_data")
   ```

2. **Verificar se o formulário está validando o CPF**:
   - O formulário já valida CPF antes de processar
   - CPF deve ter 11 dígitos e passar no algoritmo de validação

3. **Verificar logs completos**:
   - Procure por "Erro na API Asaas" nos logs
   - Verifique se o erro mudou após a correção

---

**Status**: ✅ Correções aplicadas
**Data**: Janeiro 2025

