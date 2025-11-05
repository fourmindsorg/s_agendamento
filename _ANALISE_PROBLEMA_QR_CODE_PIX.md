# Análise: Problema de Geração de QR Code e Código PIX

## 🔴 Problema Identificado

O sistema não está gerando o QR Code nem o código PIX (payload) para pagamentos, mesmo após criar o pagamento no Asaas.

## 📋 Possíveis Causas Identificadas

### 1. **Endpoint Incorreto para Obter QR Code** ⚠️ CRÍTICO

**Código Atual** (`financeiro/services/asaas.py` linha 519):
```python
response = self._request("GET", f"payments/{payment_id}/pix", timeout=15)
```

**Possível Endpoint Correto** (segundo documentação Asaas):
- `/v3/payments/{id}/pixQrCode` ou
- `/v3/payments/{id}/pix`

**Ação**: Verificar documentação oficial e testar ambos os endpoints.

### 2. **Chave PIX Não Cadastrada** ⚠️ CRÍTICO

**Requisito do Asaas**:
- É **obrigatório** ter uma chave PIX cadastrada na conta do Asaas
- Mesmo em ambiente **sandbox** é necessário cadastrar uma chave PIX
- Sem chave PIX, o endpoint retorna erro 404 ou não gera QR code

**Verificação Necessária**:
1. Acessar painel do Asaas (sandbox ou produção)
2. Verificar se há chave PIX cadastrada
3. Se não houver, cadastrar uma chave PIX

### 3. **Recebimento via PIX Não Habilitado** ⚠️ ALTO

**Requisito do Asaas**:
- A opção "Disponibilizar recebimento por Pix" deve estar habilitada
- Configuração: "Minha conta" > "Configurações" > "Configurações do sistema"

### 4. **Erro 404 ao Buscar QR Code** ⚠️ MÉDIO

**Causa Comum**:
- QR Code ainda não foi gerado pelo Asaas (pode levar alguns segundos)
- Pagamento não foi criado como tipo PIX
- Chave PIX não configurada

**Solução Atual**:
- O código já tenta múltiplas vezes (5 tentativas em 15s)
- Mas pode não ser suficiente se o problema for de configuração

### 5. **Resposta da API com Estrutura Diferente** ⚠️ MÉDIO

**Possível Problema**:
- A API pode retornar campos diferentes:
  - `qrCode` (base64) ou `encodedImage`
  - `payload` ou `copyPaste`
- O código precisa verificar todas as possibilidades

## 🔍 Verificações Necessárias

### 1. Verificar Logs do Sistema

```bash
# Ver logs do Django/Gunicorn
sudo journalctl -u s-agendamento -n 100 | grep -i "pix\|qr\|asaas"

# Verificar erros específicos
grep -i "404\|500\|pix\|qr" /opt/s-agendamento/logs/gunicorn_error.log
```

### 2. Verificar Configuração da Conta Asaas

**Passos**:
1. Acessar https://sandbox.asaas.com/ (ou produção)
2. Verificar se há chave PIX cadastrada:
   - Menu: **Pix** > **Minhas Chaves**
   - Deve ter pelo menos uma chave PIX ativa
3. Verificar se recebimento via PIX está habilitado:
   - Menu: **Minha conta** > **Configurações** > **Configurações do sistema**
   - Verificar opção "Disponibilizar recebimento por Pix"

### 3. Testar Endpoint da API Manualmente

```bash
# Testar criação de pagamento PIX
curl -X POST https://api-sandbox.asaas.com/v3/payments \
  -H "access_token: $ASAAS_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "customer": "cus_xxxxx",
    "value": 10.00,
    "dueDate": "2024-12-31",
    "billingType": "PIX"
  }'

# Testar obter QR code (substituir PAYMENT_ID)
curl -X GET https://api-sandbox.asaas.com/v3/payments/PAYMENT_ID/pix \
  -H "access_token: $ASAAS_API_KEY"
```

### 4. Verificar Resposta da API

**Campos Esperados**:
- `payload`: Código PIX copia e cola
- `qrCode` ou `encodedImage`: Imagem do QR code em base64
- `expiresAt`: Data de expiração

## 🔧 Soluções Propostas

### Solução 1: Adicionar Validação de Chave PIX

Adicionar verificação se a conta tem chave PIX configurada antes de criar pagamento.

### Solução 2: Melhorar Tratamento de Erros

Capturar e logar erros específicos da API Asaas para identificar problema.

### Solução 3: Testar Endpoint Alternativo

Verificar se o endpoint correto é `/pixQrCode` em vez de `/pix`.

### Solução 4: Adicionar Retry Mais Inteligente

Aumentar tentativas e aguardar mais tempo se receber erro 404 (QR code ainda não disponível).

### Solução 5: Verificar Estrutura da Resposta

Adicionar logs detalhados da resposta da API para verificar estrutura retornada.

## 📝 Checklist de Diagnóstico

- [ ] Verificar logs do sistema para erros específicos
- [ ] Confirmar que chave PIX está cadastrada no Asaas
- [ ] Confirmar que recebimento via PIX está habilitado
- [ ] Testar criação de pagamento manualmente via API
- [ ] Testar obtenção de QR code manualmente via API
- [ ] Verificar estrutura da resposta da API
- [ ] Verificar se endpoint está correto (`/pix` vs `/pixQrCode`)
- [ ] Verificar se pagamento está sendo criado como tipo PIX
- [ ] Verificar se há erro 404 ao buscar QR code (e se é esperado)

## 🎯 Próximos Passos

1. **Verificar configuração da conta Asaas** (chave PIX e recebimento habilitado)
2. **Testar endpoints manualmente** para confirmar funcionamento
3. **Adicionar logs detalhados** para diagnóstico
4. **Corrigir endpoint** se necessário
5. **Melhorar tratamento de erros** para identificar problema específico

