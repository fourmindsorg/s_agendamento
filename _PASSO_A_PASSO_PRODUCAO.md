# 🚀 Passo a Passo: Teste em Produção - Asaas PIX

## ⚠️ IMPORTANTE - Leia Antes!

1. **Valor mínimo**: R$ 5,00 (cobrança real será criada)
2. **CPF válido**: Use CPF real válido (não aceita CPF de teste)
3. **Backup**: Faça backup das configurações atuais
4. **Logs**: Mantenha logs ativos para debug

## 📋 Passo 1: Obter Chave de API de Produção

1. Acesse: https://www.asaas.com/minha-conta/integracoes/chaves-api
2. Faça login na sua conta
3. **Gere uma nova chave de API** (se ainda não tiver)
4. Copie a chave (começa com `$aact_`)
5. ⚠️ **IMPORTANTE**: Guarde a chave em local seguro!

## 📋 Passo 2: Configurar Ambiente de Produção

### Opção A: Teste Local (Recomendado para primeiro teste)

```bash
# 1. Fazer backup do .env atual
cp .env .env.backup.sandbox

# 2. Editar .env e adicionar/alterar:
ASAAS_ENV=production
ASAAS_API_KEY_PRODUCTION=$aact_SUA_CHAVE_PRODUCAO_AQUI

# Mantenha também a chave de sandbox (para reverter depois):
ASAAS_API_KEY_SANDBOX=$aact_SUA_CHAVE_SANDBOX_AQUI
```

**Nota**: O sistema usa:
- **Sandbox**: `ASAAS_API_KEY_SANDBOX` ou `ASAAS_API_KEY` (fallback)
- **Produção**: `ASAAS_API_KEY_PRODUCTION` ou `ASAAS_API_KEY` (fallback)

### Opção B: Produção AWS (Servidor real)

```bash
# Via AWS CLI ou Console:
# 1. Acesse AWS Systems Manager Parameter Store
# 2. Criar/atualizar parâmetros:
#    - /s_agendamento/ASAAS_ENV = "production"
#    - /s_agendamento/ASAAS_API_KEY = "$aact_SUA_CHAVE_AQUI"
```

## 📋 Passo 3: Verificar Configuração

```bash
# Verificar se está configurado corretamente
python manage.py shell
>>> from django.conf import settings
>>> print(f"Ambiente: {getattr(settings, 'ASAAS_ENV', 'sandbox')}")
>>> print(f"API Key: {'✅ Configurada' if getattr(settings, 'ASAAS_API_KEY', None) else '❌ Não configurada'}")
>>> 
>>> from financeiro.services.asaas import AsaasClient
>>> client = AsaasClient()
>>> print(f"Base URL: {client.base}")
>>> print(f"Ambiente: {client.env}")
# Deve mostrar:
# Ambiente: production
# Base URL: https://www.asaas.com/api/v3/
# Ambiente: production
```

## 📋 Passo 4: Testar Conexão

```bash
# Executar script de teste
python financeiro/teste_producao_asaas.py

# Escolher:
# 1. Informar CPF válido próprio
# 2. Usar gerador (não recomendado para produção)
# 3. Pular (apenas testar conexão)

# Quando pedir valor:
# - Digite 5 (ou Enter para R$ 5,00)
# - ⚠️ LEMBRE-SE: Isso criará cobrança REAL de R$ 5,00!
```

## 📋 Passo 5: Teste Real no Sistema

### 5.1 Criar Plano de Teste

1. Acesse o admin do Django: `/admin/authentication/plano/`
2. Crie um plano com valor mínimo de R$ 5,00
3. Marque como ativo

### 5.2 Realizar Checkout

1. Acesse: `/authentication/planos/`
2. Selecione o plano de teste
3. Preencha checkout:
   - **Nome completo**: Seu nome real
   - **Email**: Seu email real
   - **CPF**: Seu CPF válido (11 dígitos)
   - **Telefone**: Seu telefone (opcional)
4. Selecione **PIX** como método de pagamento
5. Clique em **Finalizar Compra**

### 5.3 Verificar QR Code

1. Aguarde a página de pagamento carregar
2. Se QR Code aparecer: ✅ Sucesso!
3. Se não aparecer: Aguarde e recarregue a página
4. O sistema tentará até 45 segundos automaticamente

### 5.4 Testar Pagamento (Opcional)

**⚠️ ATENÇÃO**: Isso criará pagamento REAL!

1. Escaneie o QR Code com app de pagamento
2. Realize o pagamento de R$ 5,00
3. Verifique no painel do Asaas se foi confirmado
4. Verifique se o webhook atualizou o status (se configurado)

## 📋 Passo 6: Verificar no Painel do Asaas

1. Acesse: https://www.asaas.com/minha-conta/financeiro
2. Verifique se o pagamento aparece na lista
3. Clique no pagamento para ver detalhes
4. Verifique se o QR Code está disponível
5. Verifique o status do pagamento

## 📋 Passo 7: Verificar Logs

```bash
# Verificar logs do Django
# Procurar por:
# - "AsaasClient inicializado - Ambiente: production"
# - "✅ Pagamento criado no Asaas: pay_xxxxx"
# - "✅ Payload obtido com sucesso"
# - "✅ QR Code gerado com sucesso"
```

## 📋 Passo 8: Verificar no Banco de Dados

```python
python manage.py shell
>>> from financeiro.models import AsaasPayment
>>> from authentication.models import AssinaturaUsuario
>>> 
>>> # Ver último pagamento
>>> payment = AsaasPayment.objects.order_by('-created_at').first()
>>> print(f"Payment ID: {payment.asaas_id}")
>>> print(f"Status: {payment.status}")
>>> print(f"Valor: R$ {payment.amount}")
>>> print(f"QR Code: {'SIM' if payment.qr_code_base64 else 'NÃO'}")
>>> print(f"Payload: {'SIM' if payment.copy_paste_payload else 'NÃO'}")
>>> 
>>> # Ver assinatura relacionada
>>> assinatura = AssinaturaUsuario.objects.filter(asaas_payment_id=payment.asaas_id).first()
>>> if assinatura:
>>>     print(f"Assinatura ID: {assinatura.id}")
>>>     print(f"Status: {assinatura.status}")
```

## ✅ Checklist de Sucesso

- [ ] Ambiente configurado como `production`
- [ ] Chave de API de produção configurada
- [ ] Cliente criado com CPF válido
- [ ] Pagamento criado com sucesso
- [ ] QR Code gerado e exibido
- [ ] QR Code pode ser escaneado
- [ ] Pagamento aparece no painel do Asaas
- [ ] Dados salvos no banco local
- [ ] Logs mostram sucesso

## 🔄 Reverter para Sandbox (Opcional)

Após o teste, se quiser voltar para sandbox:

```bash
# Restaurar backup
cp .env.backup.sandbox .env

# Ou editar manualmente:
ASAAS_ENV=sandbox
# A chave ASAAS_API_KEY_SANDBOX já deve estar configurada
```

## 🚨 Problemas Comuns

### QR Code não aparece
- **Solução**: Aguarde até 60 segundos e recarregue a página
- Em produção geralmente é mais rápido (5-15 segundos)

### Erro 400 ao criar pagamento
- **Causa**: CPF inválido ou valor menor que R$ 5,00
- **Solução**: Verificar CPF e usar valor mínimo de R$ 5,00

### Erro 401 (Não autorizado)
- **Causa**: Chave de API inválida ou expirada
- **Solução**: Verificar chave no painel do Asaas

### QR Code não funciona para pagamento
- **Causa**: Payload inválido ou QR Code gerado incorretamente
- **Solução**: Verificar logs e tentar criar novo pagamento

## 📞 Próximos Passos

1. ✅ Teste completo funcionando
2. ✅ Configurar webhooks para atualização automática
3. ✅ Monitorar pagamentos em produção
4. ✅ Documentar processos de suporte

---

**Status**: ✅ Guia completo
**Data**: Janeiro 2025

