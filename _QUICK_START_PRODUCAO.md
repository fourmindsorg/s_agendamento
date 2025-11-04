# ⚡ Quick Start - Teste em Produção

## 🎯 Configuração Rápida (5 minutos)

### 1. Obter Chave de API
```
https://www.asaas.com/minha-conta/integracoes/chaves-api
```

### 2. Configurar .env
```env
ASAAS_ENV=production
ASAAS_API_KEY_PRODUCTION=$aact_SUA_CHAVE_PRODUCAO_AQUI

# Manter sandbox também:
ASAAS_API_KEY_SANDBOX=$aact_SUA_CHAVE_SANDBOX_AQUI
```

### 3. Verificar
```bash
python financeiro/teste_producao_asaas.py
```

### 4. Testar no Sistema
- Criar plano de R$ 5,00
- Checkout com CPF válido
- Selecionar PIX
- Verificar QR Code

## ⚠️ Lembretes

- ✅ Valor mínimo: R$ 5,00
- ✅ CPF válido real (não aceita teste)
- ✅ Em produção cria cobrança REAL
- ✅ QR Code pode demorar 5-60 segundos

## 📋 Checklist Rápido

- [ ] Chave de produção obtida
- [ ] ASAAS_ENV=production configurado
- [ ] ASAAS_API_KEY configurada
- [ ] Teste com script passou
- [ ] Teste no sistema funcionou
- [ ] QR Code apareceu
- [ ] Verificado no painel Asaas

---

**Guia completo**: Ver `_PASSO_A_PASSO_PRODUCAO.md`

