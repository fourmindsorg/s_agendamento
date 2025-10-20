# 🔑 Configuração da API Key Asaas

Este documento explica como obter e configurar uma API key válida do Asaas para realizar testes de integração.

## 📋 Pré-requisitos

- Conta no Asaas (https://www.asaas.com/)
- Acesso ao painel administrativo

## 🔧 Como Obter a API Key

### 1. Acesse o Painel do Asaas

1. Vá para: https://www.asaas.com/
2. Faça login na sua conta

### 2. Navegue até as Configurações de API

1. No canto superior direito, clique no ícone do usuário
2. Selecione **"Minha conta"**
3. Navegue até a aba **"Integração"**
4. Clique em **"Chaves de API"**

### 3. Gere uma Nova Chave

1. Clique em **"Gerar chave de API"**
2. Insira um nome para a chave (ex: "App Financeiro 4Minds")
3. Defina uma data de expiração (opcional)
4. Confirme a geração da chave
5. **COPIE A CHAVE** (ela só será exibida uma vez!)

### 4. Formato da API Key

A API key do Asaas tem o formato:
```
aact_XXXXXXXXXX...
```

## 🧪 Configuração Automática

Execute o script de configuração:

```bash
python configurar_api_asaas.py
```

O script irá:
1. Solicitar sua API key
2. Testar se a chave está válida
3. Opcionalmente criar um pagamento de teste
4. Salvar a configuração em `.env`

## 🔍 Teste Manual da API Key

Se preferir testar manualmente:

```bash
python testar_api_key_asaas.py
```

## 🚀 Executar Testes de Integração

Após configurar a API key:

```bash
python testar_asaas_integracao.py
```

## 📁 Arquivos de Configuração

### `.env`
```ini
# Configurações para testes de integração
ASAAS_API_KEY=sua_api_key_aqui
ASAAS_ENV=sandbox
ASAAS_WEBHOOK_TOKEN=test_webhook_token
```

### `core/settings.py`
```python
# Configurações da API Asaas
ASAAS_API_KEY = os.environ.get("ASAAS_API_KEY")
ASAAS_ENV = os.environ.get("ASAAS_ENV", "sandbox")
ASAAS_WEBHOOK_TOKEN = os.environ.get("ASAAS_WEBHOOK_TOKEN")
```

## 🌐 URLs da API

### Sandbox (Testes)
- **Base URL**: `https://api-sandbox.asaas.com/v3`
- **Documentação**: https://docs.asaas.com/

### Produção
- **Base URL**: `https://api.asaas.com/v3`
- **Documentação**: https://docs.asaas.com/

## 🔐 Autenticação

A API do Asaas usa autenticação por token no header:

```python
headers = {
    "access_token": "sua_api_key_aqui",
    "Content-Type": "application/json"
}
```

## 📊 Endpoints Principais

### Clientes
- `GET /customers` - Listar clientes
- `POST /customers` - Criar cliente

### Pagamentos
- `POST /payments` - Criar pagamento
- `GET /payments/{id}` - Obter pagamento
- `GET /payments/{id}/pix` - Obter QR Code PIX

### Webhooks
- `POST /webhooks` - Configurar webhook

## 🧪 Testes Disponíveis

### 1. Teste de Conexão
```bash
python testar_api_key_asaas.py
```

### 2. Teste Completo de Integração
```bash
python testar_asaas_integracao.py
```

### 3. Testes Unitários (Mock)
```bash
python manage.py test financeiro.test_asaas_api
```

## ⚠️ Importante

1. **Nunca commite** a API key no Git
2. **Use sandbox** para testes
3. **Configure webhooks** para produção
4. **Monitore** o uso da API
5. **Renove** as chaves periodicamente

## 🆘 Troubleshooting

### Erro 401: "invalid_access_token"
- Verifique se a API key está correta
- Confirme se a chave não expirou
- Teste no ambiente correto (sandbox/produção)

### Erro 403: "Forbidden"
- Verifique as permissões da API key
- Confirme se o endpoint está correto

### Erro de Conexão
- Verifique sua conexão com a internet
- Teste se o site do Asaas está acessível

## 📞 Suporte

- **Documentação**: https://docs.asaas.com/
- **Central de Ajuda**: https://central.ajuda.asaas.com/
- **Suporte**: Através do painel do Asaas

---

**Última atualização:** Outubro 2025  
**Versão:** 1.0

