# 🚀 Quick Start - Asaas API PIX

Guia rápido para configurar a API Asaas em 5 minutos.

## ⚡ Configuração Rápida

### 1. Criar Conta e Obter Chave API

**Sandbox (Testes):**
```
1. Acesse: https://sandbox.asaas.com/
2. Crie conta gratuita
3. Menu: Minha Conta → Integrações → Chaves API
4. Clique em "Gerar Chave de API"
5. COPIE A CHAVE (ela só aparece uma vez!)
```

**Produção:**
```
1. Acesse: https://www.asaas.com/
2. Faça login
3. Menu: Minha Conta → Integrações → Chaves API
4. Clique em "Gerar Chave de API"
5. COPIE A CHAVE (ela só aparece uma vez!)
```

### 2. Configurar no Projeto

Crie/edite o arquivo `.env` na raiz do projeto:

```env
# Chave de API (cole a chave copiada acima)
ASAAS_API_KEY=$aact_sua_chave_aqui

# Ambiente: 'sandbox' ou 'production'
ASAAS_ENV=sandbox

# Token de Webhook (opcional - obter em Integrações → Webhook)
ASAAS_WEBHOOK_TOKEN=seu_token_opcional
```

### 3. Instalar Dependências

```bash
python -m pip install qrcode[pil]
```

**Nota:** No Windows, use `python -m pip` ao invés de apenas `pip`

### 4. Reiniciar Servidor

```bash
python manage.py runserver
```

### 5. Testar

Acesse o sistema e tente criar um pagamento PIX. O QR Code deve aparecer!

---

## 🔍 Verificar se Funcionou

### Teste Rápido no Shell

```bash
python manage.py shell
```

```python
from financeiro.services.asaas import AsaasClient
client = AsaasClient()
print("✅ Configurado com sucesso!")
```

### Testar no Sistema

1. Acesse: Seleção de Planos
2. Escolha um plano
3. Selecione método: **PIX**
4. Preencha dados
5. Confirme

**Resultado esperado:**
- ✅ QR Code PIX aparece
- ✅ Código copia e cola disponível
- ✅ Status: PENDENTE

---

## 📍 Locais Importantes no Asaas

| Item | Sandbox | Produção |
|------|---------|----------|
| **Criar Conta** | https://sandbox.asaas.com/ | https://www.asaas.com/ |
| **Chaves API** | Minha Conta → Integrações → Chaves API | Minha Conta → Integrações → Chaves API |
| **Webhooks** | Minha Conta → Integrações → Webhook | Minha Conta → Integrações → Webhook |
| **API Base** | `https://api-sandbox.asaas.com/v3/` | `https://www.asaas.com/api/v3/` |
| **Cobranças** | Menu: Cobranças | Menu: Cobranças |

---

## ⚠️ Dicas Importantes

1. **Sandbox vs Produção:**
   - Use **sandbox** para testes
   - Use **production** apenas em produção
   - Chaves de API são diferentes entre ambientes

2. **Chave de API:**
   - ⚠️ Só é exibida UMA VEZ
   - Guarde em local seguro
   - Nunca compartilhe ou commite no Git

3. **Webhook:**
   - Deve usar HTTPS em produção
   - URL deve ser acessível publicamente
   - Token é opcional mas recomendado

4. **QR Code:**
   - Sistema gera automaticamente se API não retornar
   - Sempre há código PIX copia e cola disponível
   - Funciona mesmo sem imagem do QR Code

---

## 🆘 Problemas?

### Erro: "ASAAS_API_KEY não configurada"
→ Verifique se o `.env` existe e tem a chave correta

### Erro: "HTTP 401"
→ Chave de API inválida ou ambiente errado

### QR Code não aparece
→ Execute: `pip install qrcode[pil]` e reinicie o servidor

---

## 📚 Documentação Completa

Para guia detalhado, veja: `_Docs/GUIA_CONFIGURACAO_ASAAS_PIX.md`

---

**Tempo estimado**: 5 minutos ⏱️

