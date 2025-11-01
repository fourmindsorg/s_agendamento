# 📊 Resumo Visual - Configuração Asaas API PIX

## 🎯 Objetivo
Configurar API Asaas para gerar QR Code PIX automaticamente no sistema.

---

## 🗺️ Fluxo Visual da Configuração

```
┌─────────────────────────────────────────────────────────┐
│  PASSO 1: Criar Conta no Asaas                         │
│  • Sandbox: https://sandbox.asaas.com/                 │
│  • Produção: https://www.asaas.com/                    │
│  • Verificar email                                     │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  PASSO 2: Gerar Chave de API                           │
│  • Menu: Minha Conta → Integrações → Chaves API        │
│  • Clicar: "Gerar Chave de API"                        │
│  • ⚠️ COPIAR IMEDIATAMENTE (aparece só uma vez!)      │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  PASSO 3: Configurar no Projeto                         │
│  • Criar arquivo .env na raiz                          │
│  • Adicionar: ASAAS_API_KEY=sua_chave                  │
│  • Adicionar: ASAAS_ENV=sandbox                        │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  PASSO 4: Instalar Dependências                       │
│  • pip install qrcode[pil]                             │
│  • Reiniciar servidor Django                           │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  PASSO 5: Testar                                         │
│  • Acessar sistema → Selecionar plano → PIX             │
│  • Verificar se QR Code aparece                         │
└─────────────────────────────────────────────────────────┘
```

---

## 📍 Locais Importantes

### No Painel Asaas

```
┌─────────────────────────────────────┐
│  MINHA CONTA                        │
│  ├── Integrações                    │
│  │   ├── Chaves API        ← AQUI  │
│  │   └── Webhook           ← OPCIONAL
│  └── Cobranças             ← VER PAGAMENTOS
└─────────────────────────────────────┘
```

### No Projeto

```
s_agendamento/
├── .env                      ← CONFIGURAR AQUI
├── requirements.txt          ← Verificar dependências
├── financeiro/
│   ├── services/
│   │   └── asaas.py         ← Cliente API
│   └── views.py             ← Views de pagamento
└── _Docs/
    ├── GUIA_CONFIGURACAO_ASAAS_PIX.md    ← Guia completo
    ├── QUICK_START_ASAAS.md              ← Quick start
    └── CHECKLIST_CONFIGURACAO_ASAAS.md   ← Checklist
```

---

## 🔑 Chave de API - Onde Obter

### Sandbox (Testes)
```
URL: https://sandbox.asaas.com/minha-conta/integracoes/chaves-api
```
1. Login na conta sandbox
2. Menu: Minha Conta → Integrações → Chaves API
3. Botão: "Gerar Chave de API"
4. **COPIAR IMEDIATAMENTE** (aparece só uma vez!)

### Produção
```
URL: https://www.asaas.com/minha-conta/integracoes/chaves-api
```
1. Login na conta produção
2. Menu: Minha Conta → Integrações → Chaves API
3. Botão: "Gerar Chave de API"
4. **COPIAR IMEDIATAMENTE** (aparece só uma vez!)

**Formato:** `$aact_YTU5YTE0M2M2N2I4MTIxN2E2MTExYTBiYjE1...`

---

## ⚙️ Configuração do .env

### Arquivo .env (criar na raiz do projeto)

```env
# ========================================
# API Asaas - Configuração
# ========================================

# Chave de API (cole a chave copiada do Asaas)
ASAAS_API_KEY=$aact_YTU5YTE0M2M2N2I4MTIxN2E2MTExYTBiYjE1...

# Ambiente: 'sandbox' (testes) ou 'production' (produção)
ASAAS_ENV=sandbox

# Token de Webhook (obtido em Integrações → Webhook)
# Opcional, mas recomendado para produção
ASAAS_WEBHOOK_TOKEN=seu_token_opcional_aqui
```

### ⚠️ Importante
- Arquivo `.env` deve estar na **raiz** do projeto
- Não commitar no Git (já deve estar no `.gitignore`)
- Sem espaços antes ou depois do `=`

---

## 📦 Instalação de Dependências

### Comando Único
```bash
python -m pip install qrcode[pil]
```

### Verificar Instalação (Windows)
```bash
python -m pip list | findstr qrcode
# Deve mostrar: qrcode [algum número de versão]
```

### Verificar Instalação (Linux/Mac)
```bash
pip list | grep qrcode
# Deve mostrar: qrcode [algum número de versão]
```

**Nota:** No Windows, use `python -m pip` se o comando `pip` não funcionar.

### Dependências Necessárias
- ✅ `requests` - Já deve estar instalado
- ✅ `qrcode[pil]` - Para gerar QR Code
- ✅ `python-dotenv` - Para carregar .env

---

## 🧪 Como Testar

### Teste Rápido (1 minuto)

```bash
python manage.py shell
```

```python
# Teste 1: Importação
from financeiro.services.asaas import AsaasClient
print("✅ Importação OK")

# Teste 2: Inicialização
client = AsaasClient()
print("✅ Cliente inicializado")

# Teste 3: Criar pagamento teste
from datetime import datetime, timedelta
customer = client.create_customer(name="Teste", email="teste@teste.com")
payment = client.create_payment(
    customer_id=customer["id"],
    value=10.00,
    due_date=(datetime.now() + timedelta(days=1)).strftime("%Y-%m-%d"),
    billing_type="PIX"
)
pix = client.get_pix_qr(payment["id"])
print("✅ QR Code obtido:", bool(pix.get("payload")))
```

### Teste no Sistema

1. Acesse: `http://127.0.0.1:8000/authentication/plan_selection/`
2. Selecione um plano
3. Escolha método: **PIX**
4. Preencha dados
5. Confirme

**Resultado esperado:**
- ✅ Tela de pagamento PIX aparece
- ✅ QR Code visível na tela
- ✅ Código copia e cola disponível
- ✅ Status: PENDENTE

---

## 🔍 Verificação no Painel Asaas

Após criar um pagamento no sistema:

1. Acesse: https://sandbox.asaas.com/ (ou produção)
2. Menu: **Cobranças** ou **Pagamentos**
3. Você deve ver:
   - ✅ Pagamento criado
   - ✅ Status: Pendente
   - ✅ Valor correto
   - ✅ Cliente vinculado
   - ✅ QR Code disponível

---

## ⚠️ Problemas Comuns

### ❌ "ASAAS_API_KEY não configurada"
**Causa:** Arquivo `.env` não existe ou variável incorreta
**Solução:**
1. Verificar se `.env` está na raiz do projeto
2. Verificar se está escrito `ASAAS_API_KEY` (sem espaços)
3. Reiniciar servidor Django

### ❌ "HTTP 401 - Não autorizado"
**Causa:** Chave de API inválida ou ambiente errado
**Solução:**
1. Verificar se chave está completa (não cortada)
2. Verificar se `ASAAS_ENV` está correto
3. Gerar nova chave se necessário

### ❌ QR Code não aparece
**Causa:** Biblioteca `qrcode` não instalada
**Solução:**
```bash
pip install qrcode[pil]
python manage.py runserver  # Reiniciar
```

### ❌ Webhook não recebe eventos
**Causa:** URL não acessível ou token incorreto
**Solução:**
1. Verificar se URL usa HTTPS (produção)
2. Verificar se URL é acessível publicamente
3. Verificar token no `.env`

---

## 📚 Documentação de Referência

| Documento | Descrição | Quando Usar |
|----------|-----------|-------------|
| `GUIA_CONFIGURACAO_ASAAS_PIX.md` | Guia completo passo a passo | Primeira configuração |
| `QUICK_START_ASAAS.md` | Configuração rápida 5 min | Já conhece o processo |
| `CHECKLIST_CONFIGURACAO_ASAAS.md` | Checklist de verificação | Verificar se está tudo OK |
| `ASAAS_CONFIGURACAO.md` | Documentação técnica | Referência técnica |

**Documentação Oficial:**
- https://docs.asaas.com/ - Documentação completa da API
- https://www.asaas.com/desenvolvedores - Portal do desenvolvedor

---

## ✅ Checklist Mínimo

Para funcionar rapidamente, você precisa apenas:

- [x] Conta no Asaas
- [x] Chave de API copiada
- [x] Arquivo `.env` criado com a chave
- [x] `qrcode[pil]` instalado
- [x] Servidor Django reiniciado

**Pronto!** O sistema já deve estar funcionando! 🎉

---

## 🎯 Próximos Passos

Após configurar:

1. **Testar criação de pagamento PIX**
2. **Configurar webhook** (para atualização automática de status)
3. **Monitorar logs** para garantir funcionamento
4. **Fazer testes em produção** antes de lançar

---

**Tempo Total Estimado:** 5-10 minutos ⏱️

