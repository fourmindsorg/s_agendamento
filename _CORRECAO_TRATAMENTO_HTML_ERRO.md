# ✅ Correção: Tratamento de Erro HTML da API Asaas

## 🔍 Problema Identificado

Os logs mostravam que a API do Asaas estava retornando uma **página HTML de erro 404** em vez de uma resposta JSON quando o QR Code PIX ainda não estava disponível. O código estava tentando extrair a mensagem de erro do HTML, resultando em mensagens muito longas e inúteis.

**Exemplo do erro:**
```
ERROR: Mensagem de erro extraída: <!doctype html><html lang="pt">... (HTML completo)
```

## ✅ Correção Aplicada

### 1. **Detecção de Resposta HTML vs JSON**
- Sistema agora detecta se a resposta é HTML ou JSON
- Verifica `Content-Type` header
- Verifica se o conteúdo começa com `<!doctype`

### 2. **Mensagens de Erro Mais Úteis**
- **Para 404 HTML**: "Recurso não encontrado. O QR Code PIX pode ainda não estar disponível."
- **Para outros erros HTML**: "Erro HTTP {status_code} do servidor Asaas"
- **Para JSON**: Extrai mensagem específica do array `errors` se disponível

### 3. **Logs Melhorados**
- Não loga HTML completo (apenas indica que é HTML)
- Loga dados relevantes para JSON
- Facilita debug sem poluir logs

## 📊 O Que Foi Alterado

### `financeiro/services/asaas.py`:

1. **Linha 86-127**: Lógica melhorada de tratamento de erro:
   - Detecção de resposta HTML vs JSON
   - Mensagens específicas para cada tipo
   - Logs mais limpos

## 🎯 Resultado Esperado

### Antes:
```
ERROR: Mensagem de erro extraída: <!doctype html><html lang="pt">... (1000+ caracteres de HTML)
```

### Depois:
```
ERROR: Erro na API Asaas [404]: payments/pay_xxx/pix - Resposta HTML (não JSON)
Exception: Recurso não encontrado. O QR Code PIX pode ainda não estar disponível.
```

## 📝 Como Funciona Agora

1. **Resposta HTML (404)**:
   - Detecta que é HTML
   - Usa mensagem padrão: "Recurso não encontrado. O QR Code PIX pode ainda não estar disponível."
   - Log limpo indicando que é HTML

2. **Resposta JSON (erro da API)**:
   - Parseia JSON normalmente
   - Extrai mensagem específica do array `errors`
   - Log com dados relevantes

3. **Resposta de Texto (outros)**:
   - Usa texto da resposta (limitado a 200 caracteres)
   - Log apropriado

## 🚀 Benefícios

- ✅ Logs mais limpos e úteis
- ✅ Mensagens de erro mais claras para o usuário
- ✅ Melhor tratamento de erros 404 (QR Code ainda não disponível)
- ✅ Facilita debug sem poluir logs com HTML

---

**Status**: ✅ Correção aplicada
**Data**: Janeiro 2025

