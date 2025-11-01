# ✅ Checklist de Configuração - Asaas API PIX

Use este checklist para garantir que tudo está configurado corretamente.

## 📋 Pré-Configuração

### Conta no Asaas
- [ ] Conta criada no Asaas Sandbox (testes)
- [ ] Conta criada no Asaas Produção (opcional)
- [ ] Email verificado
- [ ] Dados pessoais/empresariais completos

---

## 🔑 Passo 1: Chave de API

### Sandbox
- [ ] Acessei: https://sandbox.asaas.com/
- [ ] Fiz login na conta
- [ ] Menu: Minha Conta → Integrações → Chaves API
- [ ] Cliquei em "Gerar Chave de API"
- [ ] Copiei a chave imediatamente
- [ ] Guardei a chave em local seguro

### Produção (quando necessário)
- [ ] Acessei: https://www.asaas.com/
- [ ] Fiz login na conta
- [ ] Menu: Minha Conta → Integrações → Chaves API
- [ ] Cliquei em "Gerar Chave de API"
- [ ] Copiei a chave imediatamente
- [ ] Guardei a chave em local seguro

**Formato da chave:** `$aact_YTU5YTE0M2M2N2I4...`

---

## ⚙️ Passo 2: Configuração no Projeto

### Arquivo .env
- [ ] Arquivo `.env` criado na raiz do projeto
- [ ] Adicionei `ASAAS_API_KEY=` com a chave copiada
- [ ] Adicionei `ASAAS_ENV=sandbox` (ou `production`)
- [ ] Verifiquei que não há espaços ou caracteres inválidos
- [ ] Arquivo `.env` está no `.gitignore` (não será commitado)

**Exemplo do .env:**
```env
ASAAS_API_KEY=$aact_YTU5YTE0M2M2N2I4MTIxN2E2MTExYTBiYjE1...
ASAAS_ENV=sandbox
```

### Dependências
- [ ] Biblioteca `requests` instalada (`pip list | grep requests`)
- [ ] Biblioteca `qrcode[pil]` instalada (`pip list | grep qrcode`)
- [ ] Biblioteca `python-dotenv` instalada

**Comando de instalação:**
```bash
python -m pip install qrcode[pil] python-dotenv
```

**Nota Windows:** Se `pip` não funcionar, use `python -m pip`

---

## 🔗 Passo 3: Webhook (Opcional mas Recomendado)

### Configuração no Asaas
- [ ] Acessei: Minha Conta → Integrações → Webhook
- [ ] Configurei URL: `https://seudominio.com.br/financeiro/webhooks/asaas/`
- [ ] Selecionei eventos: PAYMENT_RECEIVED, PAYMENT_OVERDUE
- [ ] Copiei o token de webhook gerado
- [ ] Adicionei `ASAAS_WEBHOOK_TOKEN=` no `.env`

### Configuração da URL (Produção)
- [ ] URL do webhook usa HTTPS
- [ ] URL é acessível publicamente
- [ ] Testei a URL manualmente
- [ ] Configurado no servidor de produção

---

## 🧪 Passo 4: Testes

### Teste Básico
- [ ] Executei: `python manage.py shell`
- [ ] Testei importação: `from financeiro.services.asaas import AsaasClient`
- [ ] Criei cliente: `client = AsaasClient()` (sem erros)
- [ ] Verifiquei logs (sem erros)

### Teste de Criação
- [ ] Criei cliente de teste via API
- [ ] Criei pagamento PIX de teste
- [ ] Obteve QR Code do pagamento
- [ ] Verificou que payload PIX está presente

**Script de teste:**
```python
from financeiro.services.asaas import AsaasClient
from datetime import datetime, timedelta

client = AsaasClient()
customer = client.create_customer(name="Teste", email="teste@teste.com")
payment = client.create_payment(
    customer_id=customer["id"],
    value=10.00,
    due_date=(datetime.now() + timedelta(days=1)).strftime("%Y-%m-%d"),
    billing_type="PIX"
)
pix_data = client.get_pix_qr(payment["id"])
print("✅ Funcionando!" if pix_data.get("payload") else "❌ Erro")
```

---

## 🌐 Passo 5: Teste no Sistema

### Fluxo Completo
- [ ] Acessei seleção de planos no sistema
- [ ] Selecionei um plano
- [ ] Escolhi método de pagamento: PIX
- [ ] Preenchi dados de cobrança
- [ ] Confirmei o pagamento

### Verificações na Tela
- [ ] QR Code PIX aparece na tela
- [ ] Código PIX copia e cola está visível
- [ ] Status mostra "PENDENTE" (em português)
- [ ] Valores estão corretos
- [ ] Data de vencimento está correta

### Verificações no Asaas
- [ ] Acessei painel do Asaas
- [ ] Menu: Cobranças/Pagamentos
- [ ] Vi o pagamento criado
- [ ] Status: Pendente
- [ ] Cliente vinculado corretamente
- [ ] QR Code disponível no painel

---

## 📊 Passo 6: Monitoramento

### Logs
- [ ] Logs do Django não mostram erros
- [ ] Tentativas de criação de pagamento são logadas
- [ ] Erros (se houver) são logados corretamente

### Webhook (se configurado)
- [ ] Webhook recebe eventos do Asaas
- [ ] Status de pagamentos é atualizado automaticamente
- [ ] Logs mostram recebimento de webhooks

---

## 🔒 Passo 7: Segurança

### Proteção de Dados
- [ ] Arquivo `.env` não está no controle de versão (Git)
- [ ] Chave de API não está exposta no código
- [ ] Token de webhook está protegido
- [ ] Logs não expõem informações sensíveis

### Validação
- [ ] Testei criação com dados inválidos (deve rejeitar)
- [ ] Testei rate limiting (deve funcionar)
- [ ] Testei validação de entrada (deve funcionar)

---

## 📚 Documentação

### Arquivos de Referência
- [ ] Li: `_Docs/GUIA_CONFIGURACAO_ASAAS_PIX.md` (guia completo)
- [ ] Li: `_Docs/QUICK_START_ASAAS.md` (guia rápido)
- [ ] Li: `_Docs/ASAAS_CONFIGURACAO.md` (documentação técnica)
- [ ] Consultei: https://docs.asaas.com/ (documentação oficial)

---

## ✅ Verificação Final

### Checklist Rápido
- [ ] Chave de API configurada ✅
- [ ] Ambiente configurado (sandbox/production) ✅
- [ ] Dependências instaladas ✅
- [ ] Teste básico passou ✅
- [ ] QR Code aparece no sistema ✅
- [ ] Pagamento criado no Asaas ✅
- [ ] Webhook configurado (opcional) ✅
- [ ] Sistema funcionando corretamente ✅

---

## 🎉 Resultado Esperado

Após completar todos os passos:

✅ Sistema cria pagamentos PIX automaticamente
✅ QR Code é gerado e exibido
✅ Código PIX copia e cola disponível
✅ Status de pagamento atualizado via webhook
✅ Tudo funcionando perfeitamente!

---

## 🆘 Se Algo Não Funcionar

1. **Verifique os logs** do Django
2. **Teste a chave de API** no shell Python
3. **Confirme o ambiente** (sandbox vs production)
4. **Verifique o arquivo `.env`** está correto
5. **Consulte a documentação** do Asaas
6. **Entre em contato com suporte** se necessário

---

**Última atualização**: Janeiro 2025

