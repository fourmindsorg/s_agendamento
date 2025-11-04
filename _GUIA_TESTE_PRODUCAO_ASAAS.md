# 🚀 Guia: Teste Real em Produção - Asaas PIX

## ⚠️ IMPORTANTE - Antes de Testar em Produção

1. **Certifique-se de que o sistema está funcionando corretamente em sandbox**
2. **Teste com valores pequenos primeiro** (ex: R$ 0,01 ou R$ 1,00)
3. **Tenha acesso ao painel do Asaas** para verificar pagamentos
4. **Mantenha logs ativos** para debug

## 📋 Checklist Pré-Teste

### 1. Verificar Configuração Atual

```bash
# Verificar qual ambiente está configurado
python manage.py shell
>>> from django.conf import settings
>>> print(f"Ambiente: {getattr(settings, 'ASAAS_ENV', 'sandbox')}")
>>> print(f"API Key configurada: {bool(getattr(settings, 'ASAAS_API_KEY', None))}")
>>> print(f"Base URL: {'https://www.asaas.com/api/v3/' if getattr(settings, 'ASAAS_ENV', 'sandbox') == 'production' else 'https://api-sandbox.asaas.com/v3/'}")
```

### 2. Verificar Chave de API de Produção

1. Acesse: https://www.asaas.com/minha-conta/integracoes/chaves-api
2. Copie a chave de produção (começa com `$aact_`)
3. Verifique se a chave está ativa e tem permissões para PIX

## 🔧 Configuração para Produção

### Opção 1: Variáveis de Ambiente (Recomendado)

```bash
# No servidor de produção, configure:
export ASAAS_ENV=production
export ASAAS_API_KEY=$aact_SUA_CHAVE_PRODUCAO_AQUI
```

### Opção 2: Arquivo .env (Desenvolvimento/Teste Local)

```env
# Ambiente (sandbox ou production)
ASAAS_ENV=production

# Chaves separadas por ambiente (recomendado)
ASAAS_API_KEY_SANDBOX=$aact_SUA_CHAVE_SANDBOX_AQUI
ASAAS_API_KEY_PRODUCTION=$aact_SUA_CHAVE_PRODUCAO_AQUI

# OU usar chave única (fallback)
# ASAAS_API_KEY=$aact_SUA_CHAVE_AQUI
```

**Estrutura de Chaves:**
- **Sandbox**: Usa `ASAAS_API_KEY_SANDBOX` (ou `ASAAS_API_KEY` como fallback)
- **Produção**: Usa `ASAAS_API_KEY_PRODUCTION` (ou `ASAAS_API_KEY` como fallback)

### Opção 3: AWS Systems Manager Parameter Store (Produção AWS)

```bash
# Criar parâmetros no AWS Systems Manager
aws ssm put-parameter \
  --name "/s_agendamento/ASAAS_ENV" \
  --value "production" \
  --type "String"

aws ssm put-parameter \
  --name "/s_agendamento/ASAAS_API_KEY" \
  --value "$aact_SUA_CHAVE_AQUI" \
  --type "SecureString"
```

## 🧪 Passos para Teste em Produção

### 1. Preparar Ambiente de Teste

```bash
# 1. Fazer backup das configurações atuais
cp .env .env.backup

# 2. Configurar para produção (temporariamente)
echo "ASAAS_ENV=production" >> .env
echo "ASAAS_API_KEY=$aact_SUA_CHAVE_PRODUCAO" >> .env

# 3. Verificar configuração
python manage.py shell
>>> from financeiro.services.asaas import AsaasClient
>>> client = AsaasClient()
>>> print(f"Ambiente: {client.env}")
>>> print(f"Base URL: {client.base}")
# Deve mostrar: Ambiente: production
# Deve mostrar: Base URL: https://www.asaas.com/api/v3/
```

### 2. Criar Teste com Valor Mínimo

**⚠️ IMPORTANTE**: 
- Asaas exige **valor mínimo de R$ 5,00** para pagamentos PIX
- Use valor mínimo (R$ 5,00) para teste
- Em produção, isso criará cobrança real!

1. Acesse o sistema em produção
2. Selecione um plano com valor mínimo
3. Preencha dados de cobrança com **CPF válido real**
4. Selecione PIX como método de pagamento
5. Finalize a compra

### 3. Verificar no Painel do Asaas

1. Acesse: https://www.asaas.com/minha-conta/financeiro
2. Verifique se o pagamento foi criado
3. Verifique se o QR Code está disponível
4. Verifique o status do pagamento

### 4. Testar Pagamento Real (Opcional)

**⚠️ CUIDADO**: Isso criará um pagamento real que será cobrado!

1. Escaneie o QR Code com app de pagamento
2. Realize o pagamento
3. Verifique no painel do Asaas se o pagamento foi confirmado
4. Verifique se o webhook foi recebido (se configurado)

## 📊 Verificação dos Logs

### Durante o Teste

```bash
# Monitorar logs em tempo real
tail -f logs/django.log | grep -i asaas

# Ou no servidor Django
# Os logs devem mostrar:
# - "AsaasClient inicializado - Ambiente: production"
# - "✅ Pagamento criado no Asaas: pay_xxxxx"
# - "✅ Payload obtido com sucesso"
```

### Logs Esperados (Sucesso)

```
INFO: AsaasClient inicializado - Ambiente: production
INFO: ✅ Pagamento criado no Asaas: pay_xxxxx
INFO: ✅ Payload obtido com sucesso na tentativa X
INFO: ✅ QR Code gerado com sucesso!
```

## 🔍 Verificação Manual

### 1. Verificar Pagamento Criado

```python
python manage.py shell
>>> from financeiro.models import AsaasPayment
>>> from authentication.models import AssinaturaUsuario
>>> 
>>> # Ver último pagamento criado
>>> payment = AsaasPayment.objects.last()
>>> print(f"Payment ID: {payment.asaas_id}")
>>> print(f"Status: {payment.status}")
>>> print(f"Valor: R$ {payment.amount}")
>>> print(f"Tipo: {payment.billing_type}")
>>> print(f"QR Code: {'SIM' if payment.qr_code_base64 else 'NÃO'}")
>>> print(f"Payload: {'SIM' if payment.copy_paste_payload else 'NÃO'}")
```

### 2. Verificar Assinatura

```python
>>> assinatura = AssinaturaUsuario.objects.filter(asaas_payment_id__isnull=False).last()
>>> print(f"Assinatura ID: {assinatura.id}")
>>> print(f"Payment ID: {assinatura.asaas_payment_id}")
>>> print(f"Status: {assinatura.status}")
```

### 3. Testar Obtenção de QR Code

```python
>>> from financeiro.services.asaas import AsaasClient
>>> client = AsaasClient()
>>> 
>>> # Tentar obter QR Code do pagamento
>>> try:
>>>     pix_data = client.get_pix_qr(assinatura.asaas_payment_id)
>>>     print("✅ QR Code obtido!")
>>>     print(f"Payload: {pix_data.get('payload', 'N/A')[:50]}...")
>>> except Exception as e:
>>>     print(f"❌ Erro: {e}")
```

## 🛠️ Script de Teste Automatizado

Crie um script para testar rapidamente:

```python
# financeiro/teste_producao.py
import os
import django

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "core.settings")
django.setup()

from financeiro.services.asaas import AsaasClient
from django.conf import settings

def testar_producao():
    print("=" * 60)
    print("Teste de Produção - Asaas PIX")
    print("=" * 60)
    
    # Verificar ambiente
    env = getattr(settings, 'ASAAS_ENV', 'sandbox')
    print(f"\n1. Ambiente configurado: {env}")
    
    if env != 'production':
        print("   ⚠️ ATENÇÃO: Ambiente não é produção!")
        resposta = input("   Deseja continuar mesmo assim? (s/N): ")
        if resposta.lower() != 's':
            return
    
    # Inicializar cliente
    try:
        client = AsaasClient()
        print(f"   ✅ Cliente inicializado")
        print(f"   Base URL: {client.base}")
    except Exception as e:
        print(f"   ❌ Erro: {e}")
        return
    
    # Testar criação de cliente
    print("\n2. Testando criação de cliente...")
    try:
        customer = client.create_customer(
            name="Teste Produção",
            email=f"teste.{os.urandom(4).hex()}@example.com",
            cpf_cnpj="12345678901"  # CPF de teste (não funcionará em produção)
        )
        print(f"   ✅ Cliente criado: {customer['id']}")
    except Exception as e:
        print(f"   ⚠️ Erro esperado (CPF inválido): {e}")
    
    print("\n✅ Teste concluído!")
    print("\n⚠️ LEMBRE-SE: Use CPF válido e valor mínimo para teste real!")

if __name__ == "__main__":
    testar_producao()
```

Executar:
```bash
python financeiro/teste_producao.py
```

## ⚠️ Cuidados Importantes

### 1. **Valores de Teste**
- ✅ **Asaas exige mínimo de R$ 5,00 para PIX**
- ✅ Use valor mínimo (R$ 5,00) para teste
- ⚠️ Em produção, R$ 5,00 criará cobrança real!
- ❌ Não use valores muito altos para teste

### 2. **CPF Válido**
- Em produção, você **DEVE** usar CPF válido
- CPF de teste não funciona em produção

### 3. **Limpeza Após Teste**
- Cancele pagamentos de teste no painel do Asaas (se possível)
- Documente os pagamentos de teste para referência

### 4. **Webhooks**
- Se configurou webhooks, verifique se estão funcionando
- Teste se o sistema recebe notificações de pagamento

### 5. **Reversão**
- Após teste, pode voltar para sandbox se necessário:
  ```bash
  # Restaurar backup
  cp .env.backup .env
  # Ou alterar manualmente
  ASAAS_ENV=sandbox
  ```

## 📝 Checklist Pós-Teste

- [ ] Pagamento foi criado no Asaas
- [ ] QR Code foi gerado e está válido
- [ ] QR Code pode ser escaneado
- [ ] Logs mostram sucesso em todas as etapas
- [ ] Dados foram salvos no banco local
- [ ] Assinatura foi criada corretamente
- [ ] Webhook recebeu notificação (se configurado)
- [ ] Status do pagamento foi atualizado após pagamento

## 🚨 Problemas Comuns

### QR Code não aparece
- **Causa**: Pode demorar até 60 segundos
- **Solução**: Recarregar a página após alguns segundos

### Erro 400 ao criar pagamento
- **Causa**: CPF inválido ou dados incorretos
- **Solução**: Verificar CPF e dados de cobrança

### Erro 401 (Não autorizado)
- **Causa**: Chave de API inválida ou expirada
- **Solução**: Verificar chave no painel do Asaas

### Erro 404 ao obter QR Code
- **Causa**: QR Code ainda não está disponível
- **Solução**: Aguardar mais tempo ou recarregar página

## 📞 Suporte

- **Documentação Asaas**: https://docs.asaas.com/
- **Suporte Asaas**: https://www.asaas.com/suporte
- **Portal do Desenvolvedor**: https://www.asaas.com/desenvolvedores

---

**Status**: ✅ Guia completo
**Data**: Janeiro 2025

