# 🧪 Testes da API Asaas

Este documento detalha como configurar e executar testes completos para a integração com a API Asaas no sistema de agendamento.

## 📋 Visão Geral

O sistema de testes da API Asaas inclui:

- ✅ **Testes Unitários**: Testam componentes individuais com mocks
- ✅ **Testes de Integração**: Testam comunicação real com a API
- ✅ **Testes de Views**: Testam endpoints da aplicação
- ✅ **Testes de Modelos**: Testam persistência de dados
- ✅ **Testes de Webhook**: Testam recebimento de notificações

## 🚀 Configuração Inicial

### 1. Dependências

Certifique-se de que as seguintes dependências estão instaladas:

```bash
# Instalar dependências básicas
pip install django requests

# Ou instalar todas as dependências do projeto
pip install -r requirements.txt
```

### 2. Configuração da API

Crie um arquivo `.env.asaas` baseado no exemplo:

```bash
# Copiar arquivo de exemplo
cp env.asaas.example .env.asaas
```

Configure suas credenciais no arquivo `.env.asaas`:

```ini
# Chave da API Asaas
ASAAS_API_KEY=sk_test_sua_chave_aqui

# Ambiente (sandbox para testes)
ASAAS_ENV=sandbox

# Token para webhooks (opcional)
ASAAS_WEBHOOK_TOKEN=seu_token_webhook_aqui
```

### 3. Configuração do Django

As configurações da API Asaas devem estar no `settings.py`:

```python
# core/settings.py
ASAAS_API_KEY = os.environ.get('ASAAS_API_KEY')
ASAAS_ENV = os.environ.get('ASAAS_ENV', 'sandbox')
ASAAS_WEBHOOK_TOKEN = os.environ.get('ASAAS_WEBHOOK_TOKEN')
```

## 🧪 Executando os Testes

### Execução Rápida

```bash
# Executar todos os testes
python testar_asaas.py

# Executar com menu interativo
python testar_asaas.py --interactive

# Executar apenas testes básicos
python testar_asaas.py --quick
```

### Execução com Django

```bash
# Executar todos os testes da API Asaas
python manage.py test financeiro.test_asaas_api

# Executar teste específico
python manage.py test financeiro.test_asaas_api.AsaasAPITestCase.test_create_customer

# Executar com verbosidade
python manage.py test financeiro.test_asaas_api --verbosity=2
```

### Execução do Setup Completo

```bash
# Executar setup e testes completos
python financeiro/setup_asaas_tests.py
```

## 📊 Tipos de Testes

### 1. Testes Unitários

Testam componentes individuais com mocks da API:

```python
# Exemplo: Teste de criação de cliente
@patch('financeiro.services.asaas.requests.Session.post')
def test_create_customer(self, mock_post):
    mock_response = Mock()
    mock_response.json.return_value = {"id": "cus_123", "name": "Teste"}
    mock_post.return_value = mock_response
    
    result = self.asaas_client.create_customer("João Silva")
    self.assertEqual(result["id"], "cus_123")
```

### 2. Testes de Integração

Testam comunicação real com a API (requer chave válida):

```python
def test_real_api_connection(self):
    client = AsaasClient()
    customer = client.create_customer("Cliente Teste")
    self.assertIsNotNone(customer["id"])
```

### 3. Testes de Views

Testam endpoints da aplicação:

```python
def test_create_pix_charge_view(self):
    data = {
        "customer_id": "cus_123",
        "value": 100.00,
        "due_date": "2024-12-31"
    }
    
    response = self.client.post(
        reverse('financeiro:create_pix_charge'),
        data=json.dumps(data),
        content_type='application/json'
    )
    
    self.assertEqual(response.status_code, 200)
```

### 4. Testes de Webhook

Testam recebimento de notificações:

```python
def test_asaas_webhook_payment_received(self):
    webhook_payload = {
        "id": "evt_123",
        "event": "PAYMENT_RECEIVED",
        "payment": {"id": "pay_123", "status": "RECEIVED"}
    }
    
    response = self.client.post(
        reverse('financeiro:asaas_webhook'),
        data=json.dumps(webhook_payload),
        content_type='application/json'
    )
    
    self.assertEqual(response.status_code, 200)
```

## 🔧 Funcionalidades Testadas

### API Asaas

- ✅ **Criação de Cliente**: Testa criação de clientes na API
- ✅ **Criação de Pagamento**: Testa criação de cobranças PIX, Boleto e Cartão
- ✅ **QR Code PIX**: Testa obtenção de QR Code para pagamento
- ✅ **Pagamento com Cartão**: Testa processamento de cartão de crédito
- ✅ **Tratamento de Erros**: Testa respostas de erro da API

### Modelos Django

- ✅ **AsaasPayment**: Testa criação e atualização de registros
- ✅ **Campos Obrigatórios**: Testa validação de campos
- ✅ **Relacionamentos**: Testa relacionamentos entre modelos

### Views Django

- ✅ **create_pix_charge**: Testa criação de cobrança PIX
- ✅ **pix_qr_view**: Testa exibição de QR Code
- ✅ **asaas_webhook**: Testa recebimento de webhooks
- ✅ **Tratamento de Erros**: Testa respostas de erro

### Integração Completa

- ✅ **Fluxo PIX**: Criação → QR Code → Pagamento → Webhook
- ✅ **Fluxo Cartão**: Criação → Pagamento → Confirmação
- ✅ **Fluxo Boleto**: Criação → URL do Boleto → Pagamento

## 📈 Relatórios de Teste

### Saída Padrão

```
🚀 Setup e Testes da API Asaas
==================================================
🔍 Verificando configurações da API Asaas...
✅ ASAAS_API_KEY: sk_test_1234...5678
✅ ASAAS_ENV: sandbox
✅ ASAAS_WEBHOOK_TOKEN: webhook_token_123

🧪 Executando testes básicos...
✅ Cliente Asaas inicializado
✅ URL Base: https://api-sandbox.asaas.com/v3/
✅ Ambiente: sandbox

🔬 Executando testes unitários...
✅ Todos os testes unitários passaram!

📋 RESUMO DOS TESTES
==================================================
Configurações: ✅ OK
Testes Básicos: ✅ OK
Testes Unitários: ✅ OK
Testes Integração: ✅ OK

🎉 API Asaas configurada e funcionando corretamente!
```

### Logs Detalhados

Para logs mais detalhados, execute com verbosidade:

```bash
python manage.py test financeiro.test_asaas_api --verbosity=2
```

## 🐛 Troubleshooting

### Problemas Comuns

#### 1. "ASAAS_API_KEY não configurada"

**Solução:**
```bash
# Definir variável de ambiente
export ASAAS_API_KEY=sk_test_sua_chave_aqui

# Ou criar arquivo .env.asaas
echo "ASAAS_API_KEY=sk_test_sua_chave_aqui" > .env.asaas
```

#### 2. "ModuleNotFoundError: No module named 'requests'"

**Solução:**
```bash
pip install requests
```

#### 3. "Django not configured"

**Solução:**
```bash
# Definir variável de ambiente
export DJANGO_SETTINGS_MODULE=core.settings

# Ou executar via manage.py
python manage.py test financeiro.test_asaas_api
```

#### 4. Testes de integração falhando

**Possíveis causas:**
- API key inválida ou expirada
- Problemas de conectividade
- Limites da API atingidos

**Solução:**
```bash
# Verificar API key
curl -H "access_token: sk_test_sua_chave" https://api-sandbox.asaas.com/v3/customers

# Executar apenas testes unitários
python testar_asaas.py --quick
```

### Logs de Debug

Para debug detalhado, adicione no `settings.py`:

```python
# Configurações de debug para testes
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
        },
    },
    'loggers': {
        'financeiro': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': True,
        },
    },
}
```

## 📚 Recursos Adicionais

### Documentação da API Asaas

- [Documentação Oficial](https://docs.asaas.com/)
- [API Reference](https://docs.asaas.com/reference)
- [Webhooks](https://docs.asaas.com/reference/receber-notificacoes)

### Sandbox para Testes

- [Sandbox Asaas](https://sandbox.asaas.com/)
- [Dados de Teste](https://docs.asaas.com/reference/dados-de-teste)

### Exemplos de Uso

```python
# Exemplo básico de uso
from financeiro.services.asaas import AsaasClient

client = AsaasClient()

# Criar cliente
customer = client.create_customer(
    name="João Silva",
    email="joao@example.com",
    cpf_cnpj="12345678901"
)

# Criar pagamento PIX
payment = client.create_payment(
    customer_id=customer["id"],
    value=100.00,
    due_date="2024-12-31",
    billing_type="PIX"
)

# Obter QR Code
qr = client.get_pix_qr(payment["id"])
```

## 🎯 Próximos Passos

1. **Configurar credenciais** da API Asaas
2. **Executar testes básicos** para verificar configuração
3. **Executar testes de integração** para validar API real
4. **Implementar melhorias** baseadas nos resultados dos testes
5. **Configurar webhooks** para notificações em tempo real

---

**Última atualização:** Outubro 2025  
**Versão:** 1.0  
**Autor:** Sistema de Agendamento 4Minds
