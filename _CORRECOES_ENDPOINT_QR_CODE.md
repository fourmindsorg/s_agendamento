# Correções: Endpoint e Tratamento de QR Code PIX

## ✅ Correções Aplicadas

### 1. **Correção do Endpoint da API** ⚠️ CRÍTICO

**Problema Identificado**:
- O código usava o endpoint `/pix` que pode não ser o correto
- A documentação oficial do Asaas indica `/pixQrCode`

**Solução Implementada**:
- Endpoint principal alterado para `/pixQrCode` (correto segundo documentação)
- Fallback para `/pix` caso o primeiro retorne 404
- Logs detalhados para identificar qual endpoint funciona

**Arquivo**: `financeiro/services/asaas.py`
```python
# Antes:
response = self._request("GET", f"payments/{payment_id}/pix", timeout=15)

# Depois:
response = self._request("GET", f"payments/{payment_id}/pixQrCode", timeout=15)
# Com fallback para /pix se necessário
```

### 2. **Melhor Tratamento de Campos da Resposta** ✅

**Problema Identificado**:
- A API pode retornar campos com nomes diferentes
- Código só verificava `payload` e `encodedImage`/`qrCode`

**Solução Implementada**:
- Verifica múltiplos campos possíveis para payload:
  - `payload` (padrão)
  - `copyPaste` (alternativo)
  - `pixCopiaECola` (alternativo)
- Verifica múltiplos campos possíveis para imagem:
  - `qrCode` (padrão)
  - `encodedImage` (alternativo)
  - `qrCodeBase64` (alternativo)

**Arquivos Modificados**:
- `authentication/views.py` - Em 2 locais (quando já existe payment_id e quando cria novo)

### 3. **Logs Melhorados para Diagnóstico** ✅

**Adicionado**:
- Log das chaves disponíveis na resposta da API
- Log do tamanho do payload obtido
- Log indicando qual endpoint foi usado
- Logs mais detalhados quando payload está vazio

## 🔍 Verificações Necessárias

### 1. Verificar se Chave PIX está Cadastrada

**CRÍTICO**: O Asaas **requer** que uma chave PIX esteja cadastrada na conta:

1. Acesse o painel do Asaas:
   - Sandbox: https://sandbox.asaas.com/
   - Produção: https://www.asaas.com/

2. Verifique se há chave PIX:
   - Menu: **Pix** > **Minhas Chaves**
   - Deve ter pelo menos uma chave PIX ativa

3. Se não houver chave:
   - Cadastre uma chave PIX (CPF, CNPJ, Email, Telefone ou Chave Aleatória)
   - **IMPORTANTE**: Mesmo em sandbox é necessário cadastrar uma chave

### 2. Verificar se Recebimento via PIX está Habilitado

1. No painel do Asaas:
   - Menu: **Minha conta** > **Configurações** > **Configurações do sistema**
   - Verificar opção "Disponibilizar recebimento por Pix"
   - Deve estar **habilitada**

### 3. Testar Endpoint Manualmente

```bash
# Substituir PAYMENT_ID e ASAAS_API_KEY
curl -X GET https://api-sandbox.asaas.com/v3/payments/PAYMENT_ID/pixQrCode \
  -H "access_token: $ASAAS_API_KEY" \
  -H "Content-Type: application/json"
```

**Resposta Esperada**:
```json
{
  "payload": "00020126580014br.gov.bcb.pix...",
  "qrCode": "iVBORw0KGgoAAAANS...",
  "expiresAt": "2024-12-31T23:59:59"
}
```

## 📊 Estrutura da Resposta da API

### Campos Possíveis no Response:

**Payload (Código PIX)**:
- `payload` (mais comum)
- `copyPaste` (alternativo)
- `pixCopiaECola` (alternativo)

**QR Code (Imagem Base64)**:
- `qrCode` (mais comum)
- `encodedImage` (alternativo)
- `qrCodeBase64` (alternativo)

**Outros Campos**:
- `expiresAt`: Data de expiração do QR code

## 🎯 Próximos Passos

1. ✅ **Endpoint corrigido** - Usa `/pixQrCode` com fallback
2. ✅ **Melhor tratamento de campos** - Verifica múltiplos nomes
3. ✅ **Logs melhorados** - Facilita diagnóstico
4. ⚠️ **VERIFICAR**: Chave PIX cadastrada no Asaas
5. ⚠️ **VERIFICAR**: Recebimento via PIX habilitado
6. ⚠️ **TESTAR**: Criar novo pagamento e verificar logs

## 📝 Notas Importantes

### Sobre o Endpoint

- **Documentação oficial**: `/v3/payments/{id}/pixQrCode`
- **Endpoint alternativo**: `/v3/payments/{id}/pix` (pode funcionar em algumas versões)
- O código agora tenta ambos automaticamente

### Sobre Chave PIX

- **OBRIGATÓRIO** ter chave PIX cadastrada
- Mesmo em **sandbox** é necessário
- Sem chave PIX, o endpoint retorna erro 404 ou não gera QR code

### Sobre Timeout

- O QR code pode levar alguns segundos para ser gerado
- O sistema tenta 5 vezes em 15 segundos
- Se não conseguir, usuário pode recarregar a página

