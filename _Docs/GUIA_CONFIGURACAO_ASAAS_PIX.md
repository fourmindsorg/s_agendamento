# 📋 Guia Completo - Configuração API Asaas para PIX

Este guia mostra passo a passo como configurar a API do Asaas para emitir QR Code PIX no sistema.

## 🎯 Pré-requisitos

- Conta no Asaas (produção ou sandbox)
- Acesso ao painel administrativo do Asaas
- Chave de API do Asaas
- Token de Webhook (opcional, mas recomendado)

---

## 📝 Passo 1: Criar Conta no Asaas

### 1.1. Acesse o Asaas

**Para Testes (Sandbox):**
- URL: https://sandbox.asaas.com/
- Clique em "Criar Conta Grátis" ou "Fazer Login"

**Para Produção:**
- URL: https://www.asaas.com/
- Clique em "Criar Conta Grátis"

### 1.2. Preencha os Dados

Você precisará fornecer:
- Email
- Senha
- Dados pessoais (nome, CPF, telefone)
- Dados da empresa (se for pessoa jurídica)

### 1.3. Verifique seu Email

- Acesse sua caixa de entrada
- Clique no link de confirmação enviado pelo Asaas
- Complete o cadastro

---

## 🔑 Passo 2: Gerar Chave de API

### 2.1. Acessar Menu de Integrações

1. Faça login no painel do Asaas
2. No menu lateral, clique em **"Minha Conta"** ou **"Integrações"**
3. Selecione **"Chaves API"** ou **"API"**

### 2.2. Criar Nova Chave

1. Clique no botão **"Gerar Chave de API"** ou **"Nova Chave"**
2. Preencha:
   - **Nome da chave**: Ex: "Sistema de Agendamentos - Produção"
   - **Data de expiração**: (Opcional) Se quiser que expire automaticamente
   - **Token App/SMS**: (Opcional) Para autenticação adicional

### 2.3. Copiar a Chave

⚠️ **ATENÇÃO**: A chave será exibida apenas UMA VEZ!

1. **Copie a chave imediatamente**
2. **Guarde em local seguro** (nunca compartilhe)
3. A chave terá formato: `$aact_YTU5YTE0M2M2N2I4MTIxN2E2MTExYTBiYjE1...`

### 2.4. Locais no Painel Asaas

**Sandbox:**
- Menu: **Minha Conta** → **Integrações** → **Chaves API**
- URL direta: https://sandbox.asaas.com/minha-conta/integracoes/chaves-api

**Produção:**
- Menu: **Minha Conta** → **Integrações** → **Chaves API**
- URL direta: https://www.asaas.com/minha-conta/integracoes/chaves-api

---

## 🔗 Passo 3: Configurar Webhooks (Opcional mas Recomendado)

Os webhooks permitem que o Asaas notifique seu sistema quando um pagamento for confirmado.

### 3.1. Acessar Configuração de Webhooks

1. No painel do Asaas, vá em: **Minha Conta** → **Integrações** → **Webhook**
2. Ou acesse diretamente:
   - Sandbox: https://sandbox.asaas.com/minha-conta/integracoes/webhook
   - Produção: https://www.asaas.com/minha-conta/integracoes/webhook

### 3.2. Configurar URL do Webhook

1. Clique em **"Configurar Webhook"** ou **"Novo Webhook"**
2. Preencha:
   - **URL do Webhook**: `https://seudominio.com.br/financeiro/webhooks/asaas/`
     - ⚠️ Use HTTPS em produção
     - ⚠️ A URL deve ser acessível publicamente
   - **Eventos**: Selecione os eventos que deseja receber:
     - ✅ `PAYMENT_RECEIVED` - Pagamento recebido
     - ✅ `PAYMENT_OVERDUE` - Pagamento vencido
     - ✅ `PAYMENT_DELETED` - Pagamento deletado
     - ✅ `PAYMENT_AWAITING_RISK_ANALYSIS` - Aguardando análise

### 3.3. Obter Token de Webhook

1. Após configurar, o Asaas gerará um **Token de Webhook**
2. **Copie esse token** imediatamente
3. Guarde em local seguro
4. Formato: Geralmente uma string longa aleatória

---

## ⚙️ Passo 4: Configurar no Projeto

### 4.1. Criar Arquivo `.env`

Na raiz do projeto, crie ou edite o arquivo `.env`:

```env
# ========================================
# Configurações da API Asaas
# ========================================

# Chave de API do Asaas (obtida no Passo 2)
ASAAS_API_KEY=$aact_YTU5YTE0M2M2N2I4MTIxN2E2MTExYTBiYjE1...

# Ambiente: 'sandbox' ou 'production'
# Use 'sandbox' para testes
ASAAS_ENV=sandbox

# Token de Webhook (obtido no Passo 3)
# Opcional mas recomendado
ASAAS_WEBHOOK_TOKEN=seu_token_de_webhook_aqui
```

### 4.2. Verificar Instalação das Dependências

Execute no terminal:

```bash
pip install requests qrcode[pil]
```

Ou verifique se estão no `requirements.txt`:
- `requests==2.31.0`
- `qrcode[pil]==7.4.2`

### 4.3. Verificar Configuração

Execute o comando para verificar se está tudo configurado:

```bash
python manage.py shell
```

No shell Python:
```python
from django.conf import settings
print("API Key configurada:", bool(settings.ASAAS_API_KEY))
print("Ambiente:", getattr(settings, 'ASAAS_ENV', 'sandbox'))
```

---

## 🧪 Passo 5: Testar a Configuração

### 5.1. Teste Básico

Use o script de teste existente:

```bash
python financeiro/setup_asaas_tests.py
```

### 5.2. Teste Manual via Python Shell

```bash
python manage.py shell
```

```python
from financeiro.services.asaas import AsaasClient

# Inicializar cliente
client = AsaasClient()
print("✅ Cliente inicializado com sucesso!")

# Criar cliente de teste
customer = client.create_customer(
    name="Teste da Silva",
    email="teste@example.com",
    cpf_cnpj="12345678900",
    phone="11987654321"
)
print(f"✅ Cliente criado: {customer['id']}")

# Criar pagamento PIX
from datetime import datetime, timedelta
due_date = (datetime.now() + timedelta(days=1)).strftime("%Y-%m-%d")

payment = client.create_payment(
    customer_id=customer["id"],
    value=10.00,
    due_date=due_date,
    billing_type="PIX",
    description="Teste de pagamento PIX"
)
print(f"✅ Pagamento criado: {payment['id']}")
print(f"   Status: {payment['status']}")

# Obter QR Code
pix_data = client.get_pix_qr(payment["id"])
print(f"✅ QR Code obtido!")
print(f"   Payload: {pix_data.get('payload', 'N/A')[:50]}...")
print(f"   Tem imagem: {bool(pix_data.get('encodedImage') or pix_data.get('qrCode'))}")
```

---

## 🌐 Passo 6: Configurar Webhook (Produção)

### 6.1. Testar URL do Webhook

Seu webhook deve estar acessível publicamente. Use uma ferramenta como:
- **ngrok** (para testes locais): https://ngrok.com/
- **localhost.run**: https://localhost.run/

### 6.2. Configurar no Asaas

1. No painel do Asaas, vá em: **Integrações** → **Webhook**
2. Informe a URL: `https://seudominio.com.br/financeiro/webhooks/asaas/`
3. Selecione os eventos desejados
4. Copie o token gerado
5. Adicione no `.env`: `ASAAS_WEBHOOK_TOKEN=token_aqui`

### 6.3. Testar Webhook

O Asaas enviará eventos quando:
- Pagamento for confirmado
- Pagamento vencer
- Pagamento for deletado

Verifique os logs do seu servidor para confirmar recebimento.

---

## 🔍 Passo 7: Verificar Funcionamento

### 7.1. Testar Criação de Pagamento PIX

1. Acesse o sistema
2. Selecione um plano
3. Escolha método de pagamento: **PIX**
4. Preencha os dados de cobrança
5. Confirme o pagamento

**O que deve acontecer:**
- ✅ QR Code PIX deve aparecer na tela
- ✅ Código PIX copia e cola deve estar disponível
- ✅ Status deve mostrar "PENDENTE"

### 7.2. Verificar no Painel Asaas

1. Acesse o painel do Asaas
2. Vá em **Cobranças** ou **Pagamentos**
3. Você deve ver o pagamento criado com:
   - Status: "Pendente"
   - Valor correto
   - Cliente vinculado
   - QR Code disponível

---

## 📊 Passo 8: Monitoramento

### 8.1. Verificar Logs

Os logs do sistema registram:
- Criação de pagamentos
- Erros na API
- Recebimento de webhooks

**Localização dos logs:**
- Console do Django (em desenvolvimento)
- Arquivo de log (em produção)

### 8.2. Dashboard Asaas

No painel do Asaas você pode:
- Ver todas as cobranças criadas
- Verificar status de pagamentos
- Ver histórico de transações
- Exportar relatórios

---

## ⚠️ Passo 9: Problemas Comuns e Soluções

### Problema: "ASAAS_API_KEY não configurada"

**Solução:**
1. Verifique se o arquivo `.env` existe na raiz do projeto
2. Confirme que a variável está escrita como `ASAAS_API_KEY` (sem espaços)
3. Reinicie o servidor Django após adicionar a variável

### Problema: "Erro HTTP 401" (Não autorizado)

**Solução:**
1. Verifique se a chave de API está correta
2. Confirme se está usando a chave do ambiente correto (sandbox vs produção)
3. Verifique se a chave não expirou
4. Gere uma nova chave se necessário

### Problema: QR Code não aparece

**Solução:**
1. Instale a biblioteca: `pip install qrcode[pil]`
2. Verifique os logs para erros
3. O sistema gera QR Code automaticamente se a API não retornar imagem
4. Use o código PIX copia e cola como alternativa

### Problema: Webhook não recebe eventos

**Solução:**
1. Verifique se a URL do webhook é acessível publicamente
2. Confirme que está usando HTTPS em produção
3. Verifique se o token está configurado corretamente no `.env`
4. Teste a URL do webhook manualmente

---

## 📚 Passo 10: Documentação Adicional

### Recursos Úteis

- **Documentação Oficial Asaas**: https://docs.asaas.com/
- **Portal do Desenvolvedor**: https://www.asaas.com/desenvolvedores
- **Central de Ajuda**: https://central.ajuda.asaas.com/

### Endpoints Importantes

**Sandbox:**
- Base URL: `https://api-sandbox.asaas.com/v3/`
- Criar Cliente: `POST /customers`
- Criar Pagamento: `POST /payments`
- Obter QR Code: `GET /payments/{id}/pix`

**Produção:**
- Base URL: `https://www.asaas.com/api/v3/`
- Criar Cliente: `POST /customers`
- Criar Pagamento: `POST /payments`
- Obter QR Code: `GET /payments/{id}/pix`

---

## ✅ Checklist Final

- [ ] Conta no Asaas criada e verificada
- [ ] Chave de API gerada e copiada
- [ ] Chave de API configurada no arquivo `.env`
- [ ] Ambiente configurado (sandbox ou production)
- [ ] Token de Webhook configurado (opcional)
- [ ] Dependências instaladas (`requests`, `qrcode[pil]`)
- [ ] Teste básico executado com sucesso
- [ ] QR Code PIX aparece corretamente
- [ ] Webhook configurado e testado (opcional)
- [ ] Logs sendo monitorados

---

## 🎉 Pronto!

Após seguir todos os passos, seu sistema estará configurado para:
- ✅ Criar pagamentos PIX via API Asaas
- ✅ Gerar QR Code automaticamente
- ✅ Receber notificações de pagamento via webhook
- ✅ Gerenciar status de pagamentos automaticamente

---

## 📞 Suporte

Se tiver dúvidas:
1. Consulte a documentação do Asaas: https://docs.asaas.com/
2. Entre em contato com o suporte do Asaas
3. Verifique os logs do sistema para mais detalhes

---

**Última atualização**: Janeiro 2025
