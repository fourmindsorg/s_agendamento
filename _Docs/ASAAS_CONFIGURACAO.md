# Configuração da API Asaas

Este documento descreve como configurar a integração com a API do Asaas para processamento de pagamentos.

> 📚 **Guia Completo**: Para instruções detalhadas passo a passo, veja [`GUIA_CONFIGURACAO_ASAAS_PIX.md`](GUIA_CONFIGURACAO_ASAAS_PIX.md)
> 
> ⚡ **Quick Start**: Para configuração rápida em 5 minutos, veja [`QUICK_START_ASAAS.md`](QUICK_START_ASAAS.md)
> 
> ✅ **Checklist**: Para verificar se está tudo configurado, veja [`CHECKLIST_CONFIGURACAO_ASAAS.md`](CHECKLIST_CONFIGURACAO_ASAAS.md)

## 📋 Pré-requisitos

1. Conta no Asaas (produção ou sandbox)
2. Chave de API gerada no painel do Asaas
3. Python 3.8+ e Django instalado

## 🔑 Obtenção da Chave de API

### Ambiente Sandbox (Testes)

1. Acesse: https://sandbox.asaas.com/
2. Crie uma conta ou faça login
3. Vá em: **Minha Conta** > **Integrações** > **Chaves API**
4. Clique em **Gerar chave de API**
5. **⚠️ COPIE A CHAVE IMEDIATAMENTE** (ela só será exibida uma vez!)
6. Guarde em local seguro

### Ambiente de Produção

1. Acesse: https://www.asaas.com/
2. Faça login na sua conta
3. Vá em: **Minha Conta** > **Integrações** > **Chaves API**
4. Clique em **Gerar chave de API**
5. Copie a chave gerada

## ⚙️ Configuração no Projeto

### 1. Criar arquivo .env

Crie um arquivo `.env` na raiz do projeto (se ainda não existir) e adicione:

```env
# Chave de API do Asaas
ASAAS_API_KEY=sua_chave_de_api_aqui

# Ambiente: 'sandbox' ou 'production'
ASAAS_ENV=sandbox

# Token para validação de webhooks (opcional, mas recomendado)
ASAAS_WEBHOOK_TOKEN=seu_token_de_webhook_aqui
```

### 2. Verificar configuração

O Django carregará automaticamente as variáveis do arquivo `.env` através do `python-dotenv`.

### 3. Testar a configuração

Você pode usar o script de teste existente:

```bash
python financeiro/setup_asaas_tests.py
```

## 🔗 Configuração de Webhooks

Os webhooks permitem que o Asaas notifique seu sistema sobre eventos de pagamento em tempo real.

### Configurar Webhook no Asaas

1. No painel do Asaas, vá em: **Minha Conta** > **Integrações** > **Webhook para cobranças**
2. Informe a URL do seu webhook: `https://seudominio.com.br/financeiro/webhooks/asaas/`
3. Gere e copie o token de validação
4. Configure no `.env` como `ASAAS_WEBHOOK_TOKEN`

### Eventos Suportados

O sistema processa os seguintes eventos:

- `PAYMENT_RECEIVED` - Pagamento confirmado
- `PAYMENT_OVERDUE` - Pagamento vencido
- `PAYMENT_DELETED` - Pagamento deletado

## 📚 Uso da API

### Exemplo: Criar Cliente

```python
from financeiro.services.asaas import AsaasClient

client = AsaasClient()

# Criar cliente
customer = client.create_customer(
    name="João Silva",
    email="joao@example.com",
    cpf_cnpj="12345678900",
    phone="(11) 98765-4321"
)

customer_id = customer["id"]
```

### Exemplo: Criar Pagamento PIX

```python
from datetime import datetime, timedelta

# Criar pagamento
payment = client.create_payment(
    customer_id=customer_id,
    value=100.00,
    due_date=(datetime.now() + timedelta(days=7)).strftime("%Y-%m-%d"),
    billing_type="PIX",
    description="Pagamento de assinatura"
)

# Obter QR Code PIX
qr_code = client.get_pix_qr(payment["id"])
print(f"QR Code: {qr_code['qrCode']}")
print(f"Payload: {qr_code['payload']}")
```

### Exemplo: Buscar Pagamento

```python
payment = client.get_payment("pay_xxxxxxxxxxxxx")
print(f"Status: {payment['status']}")
print(f"Valor: {payment['value']}")
```

### Exemplo: Listar Pagamentos

```python
payments = client.list_payments(
    customer=customer_id,
    status="RECEIVED",
    limit=10
)

for payment in payments["data"]:
    print(f"ID: {payment['id']}, Valor: {payment['value']}")
```

## 🛠️ Métodos Disponíveis

### Clientes

- `create_customer()` - Criar cliente
- `get_customer()` - Buscar cliente por ID
- `find_customer_by_cpf_cnpj()` - Buscar cliente por CPF/CNPJ
- `update_customer()` - Atualizar dados do cliente

### Pagamentos

- `create_payment()` - Criar cobrança
- `get_payment()` - Buscar pagamento por ID
- `list_payments()` - Listar pagamentos com filtros
- `delete_payment()` - Remover pagamento
- `get_pix_qr()` - Obter QR Code PIX
- `get_payment_barcode()` - Obter código de barras (boleto)
- `pay_with_credit_card()` - Pagar com cartão de crédito

### Assinaturas

- `create_subscription()` - Criar assinatura recorrente
- `get_subscription()` - Buscar assinatura por ID
- `cancel_subscription()` - Cancelar assinatura

## ⚠️ Tratamento de Erros

O cliente lança `AsaasAPIError` em caso de erro na API:

```python
from financeiro.services.asaas import AsaasClient, AsaasAPIError

try:
    client = AsaasClient()
    payment = client.create_payment(...)
except AsaasAPIError as e:
    print(f"Erro na API: {e.message}")
    print(f"Código HTTP: {e.status_code}")
except RuntimeError as e:
    print(f"Configuração inválida: {e}")
```

## 🔒 Segurança

1. **NUNCA** commite o arquivo `.env` no Git
2. Mantenha sua chave de API segura e privada
3. Use ambiente `sandbox` para desenvolvimento e testes
4. Use `production` apenas em ambiente de produção
5. Configure o token de webhook para validar requisições

## 📖 Documentação Oficial

- Documentação da API: https://docs.asaas.com/
- Portal do desenvolvedor: https://www.asaas.com/desenvolvedores
- Central de ajuda: https://central.ajuda.asaas.com/

## 🧪 Testes

Execute os testes da integração:

```bash
python financeiro/setup_asaas_tests.py
```

Ou usando pytest:

```bash
pytest financeiro/tests.py -v
```

## ❓ Troubleshooting

### Erro: "ASAAS_API_KEY não configurada"

- Verifique se o arquivo `.env` existe na raiz do projeto
- Confirme que a variável está escrita como `ASAAS_API_KEY` (sem espaços)
- Certifique-se de que o `python-dotenv` está instalado (`pip install python-dotenv`)

### Erro: "Timeout na comunicação com a API Asaas"

- Verifique sua conexão com a internet
- Confirme se a URL da API está correta
- Em alguns casos, pode ser necessário aumentar o timeout

### Webhook não está recebendo eventos

- Verifique se a URL do webhook está acessível publicamente
- Confirme que o token está configurado corretamente
- Verifique os logs do servidor para erros
- Teste a URL do webhook manualmente

