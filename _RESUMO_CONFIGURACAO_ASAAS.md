# 📋 Resumo: Configuração Asaas - Estrutura de Chaves

## 🔑 Estrutura de Variáveis de Ambiente

O sistema suporta **chaves separadas por ambiente** para maior segurança:

### Configuração Recomendada (.env)

```env
# Ambiente atual (sandbox ou production)
ASAAS_ENV=sandbox

# Chave para ambiente SANDBOX
ASAAS_API_KEY_SANDBOX=$aact_SUA_CHAVE_SANDBOX_AQUI

# Chave para ambiente PRODUÇÃO
ASAAS_API_KEY_PRODUCTION=$aact_SUA_CHAVE_PRODUCAO_AQUI
```

### Como Funciona

1. **Quando `ASAAS_ENV=sandbox`**:
   - Usa `ASAAS_API_KEY_SANDBOX`
   - Se não existir, usa `ASAAS_API_KEY` (fallback)
   - Base URL: `https://api-sandbox.asaas.com/v3/`

2. **Quando `ASAAS_ENV=production`**:
   - Usa `ASAAS_API_KEY_PRODUCTION`
   - Se não existir, usa `ASAAS_API_KEY` (fallback)
   - Base URL: `https://www.asaas.com/api/v3/`

## 🔄 Trocar Entre Ambientes

### Para Produção:
```env
ASAAS_ENV=production
# ASAAS_API_KEY_PRODUCTION já deve estar configurada
```

### Para Sandbox:
```env
ASAAS_ENV=sandbox
# ASAAS_API_KEY_SANDBOX já deve estar configurada
```

## ✅ Verificar Configuração

```bash
# Script de verificação
python _VERIFICAR_CONFIGURACAO_ASAAS.py
```

Ou manualmente:
```python
python manage.py shell
>>> from django.conf import settings
>>> print(f"Ambiente: {getattr(settings, 'ASAAS_ENV', 'sandbox')}")
>>> print(f"API Key: {'✅' if getattr(settings, 'ASAAS_API_KEY', None) else '❌'}")
```

## 📝 Exemplo de .env Completo

```env
# Ambiente
ASAAS_ENV=sandbox

# Chaves Asaas
ASAAS_API_KEY_SANDBOX=$aact_YTU5YTE0M2M2N2I4MTIxN2E2MTExYTBiYjE1...
ASAAS_API_KEY_PRODUCTION=$aact_YTU5YTE0M2M2N2I4MTIxN2E2MTExYTBiYjE1...

# Webhook (opcional)
ASAAS_WEBHOOK_TOKEN=seu_token_aqui
```

## ⚠️ Importante

- **Sandbox**: Testes seguros, não cria cobranças reais
- **Produção**: Cria cobranças reais, use com cuidado!
- **Chaves separadas**: Recomendado para segurança
- **Fallback**: Se chave específica não existir, usa `ASAAS_API_KEY`

---

**Status**: ✅ Documentação atualizada
**Data**: Janeiro 2025

