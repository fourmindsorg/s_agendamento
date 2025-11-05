# Verificação Automática de Pagamentos via API Asaas

## ✅ Funcionalidade Implementada

Sistema agora verifica automaticamente via API do Asaas se os pagamentos pendentes foram confirmados e atualiza o status das assinaturas automaticamente.

## 🔧 Como Funciona

### 1. **Verificação ao Acessar Página de Planos**

Quando o usuário acessa a página `/authentication/planos/`:

1. Sistema busca assinaturas com status "aguardando_pagamento"
2. Para cada assinatura pendente que tem `asaas_payment_id`:
   - Verifica primeiro no banco local (tabela `AsaasPayment`)
   - Se não encontrar, busca na API do Asaas
   - Se pagamento foi confirmado (status: `RECEIVED`, `CONFIRMED`, `RECEIVED_IN_CASH_UNDONE`):
     - Atualiza status da assinatura para "ativa"
     - Define `data_inicio` como data/hora atual
     - Recalcula `data_fim` baseado na duração do plano
     - Salva alterações
3. Recarrega o histórico de assinaturas com status atualizado
4. Verifica novamente se ainda há assinaturas pendentes
5. Se não houver mais pendentes, a mensagem de alerta e o botão "Finalizar Pagamento" não são exibidos

### 2. **Método `verificar_e_atualizar_pagamentos_pendentes()`**

**Localização**: `authentication/views.py` - Classe `PlanSelectionView`

**Funcionalidades**:
- Recebe QuerySet de assinaturas pendentes
- Verifica cada uma via API do Asaas
- Atualiza status automaticamente se pagamento confirmado
- Retorna lista de assinaturas atualizadas
- Trata erros graciosamente (não bloqueia a página)

**Fluxo de Verificação**:
```
1. Verifica se Asaas está configurado (tem API key)
2. Para cada assinatura pendente:
   a. Verifica se tem asaas_payment_id
   b. Busca no banco local (AsaasPayment)
   c. Se não encontrar, busca na API Asaas
   d. Salva resultado no banco local
   e. Se status = RECEIVED/CONFIRMED, atualiza assinatura
3. Retorna assinaturas atualizadas
```

### 3. **Método `tem_assinatura_aguardando_pagamento()`**

**Localização**: `authentication/views.py` - Classe `PlanSelectionView`

**Atualizado para**:
- Antes de retornar, verifica via API se pagamentos foram confirmados
- Se todas as assinaturas foram atualizadas, retorna `False`
- Isso faz com que a mensagem de alerta não seja exibida

## 📋 Comportamento na Interface

### Página de Planos (`/authentication/planos/`)

**Antes da verificação**:
- ❌ Mostrava mensagem "Pagamento Pendente!" mesmo após pagamento
- ❌ Botão "Finalizar Pagamento" aparecia mesmo após pagamento confirmado

**Após implementação**:
- ✅ Verifica pagamentos automaticamente ao carregar a página
- ✅ Mensagem de alerta desaparece quando pagamento confirmado
- ✅ Botão "Finalizar Pagamento" desaparece quando status muda para "ativa"
- ✅ Histórico de assinaturas mostra status atualizado

### Botão "Finalizar Pagamento"

**Localização**: `templates/authentication/plan_selection.html`

**Condição de Exibição**:
```django
{% if a.status == 'aguardando_pagamento' %}
    <a href="{% url 'authentication:payment_pix' a.id %}" 
       class="btn btn-outline-success" 
       title="Finalizar Pagamento">
        <i class="fas fa-credit-card"></i>
    </a>
{% endif %}
```

**Comportamento**:
- Só aparece quando `status == 'aguardando_pagamento'`
- Quando status muda para "ativa" (após verificação), botão desaparece automaticamente
- Não precisa de alteração no template - funciona automaticamente

### Mensagem de Alerta

**Localização**: `templates/authentication/plan_selection.html`

**Condição de Exibição**:
```django
{% if tem_assinatura_aguardando %}
    <div class="alert alert-warning">
        <strong>Pagamento Pendente!</strong> ...
    </div>
{% endif %}
```

**Comportamento**:
- Só aparece quando `tem_assinatura_aguardando == True`
- Variável é calculada por `tem_assinatura_aguardando_pagamento()`
- Quando todas as assinaturas são atualizadas, retorna `False`
- Mensagem desaparece automaticamente

## 🔍 Status de Pagamento Reconhecidos

O sistema reconhece os seguintes status do Asaas como pagamento confirmado:

- `RECEIVED` - Pagamento recebido
- `CONFIRMED` - Pagamento confirmado  
- `RECEIVED_IN_CASH_UNDONE` - Recebido em dinheiro (não processado)

## 📝 Logs

O sistema registra logs detalhados:

**Sucesso**:
```
✅ Assinatura {id} atualizada para 'ativa' após verificação via API. 
Payment ID: {payment_id}, Status pagamento: {status}
```

**Erros**:
```
Erro ao verificar pagamento {payment_id} para assinatura {id}: {erro}
Erro ao verificar pagamentos pendentes via API Asaas: {erro}
```

**Debug**:
```
Pagamento {payment_id} ainda não disponível na API (404)
Asaas API key não configurada, pulando verificação de pagamentos
```

## ⚙️ Configuração Necessária

### Variáveis de Ambiente

Certifique-se de ter configurado no `.env`:

```env
ASAAS_API_KEY=sua_chave_de_api_aqui
ASAAS_ENV=sandbox  # ou 'production'
```

### Verificação

Se `ASAAS_API_KEY` não estiver configurada:
- Sistema não faz verificações (evita erros)
- Loga mensagem de debug
- Retorna status atual do banco

## 🎯 Benefícios

1. **Atualização Automática**: Não precisa esperar webhook ou recarregar manualmente
2. **Experiência do Usuário**: Interface atualiza automaticamente quando pagamento confirmado
3. **Confiabilidade**: Verifica tanto no banco local quanto na API
4. **Performance**: Busca primeiro no banco local (mais rápido)
5. **Resiliência**: Trata erros graciosamente sem bloquear a página
6. **Logs Detalhados**: Facilita debugging e monitoramento

## 🔄 Fluxo Completo

### Cenário: Usuário Realiza Pagamento PIX

1. **Usuário faz pagamento** → PIX é processado pelo banco
2. **Asaas confirma pagamento** → Status muda para `RECEIVED`
3. **Webhook (opcional)** → Se configurado, atualiza status imediatamente
4. **Usuário acessa página de planos** → Sistema verifica via API
5. **Sistema detecta pagamento confirmado** → Atualiza assinatura para "ativa"
6. **Interface atualiza automaticamente**:
   - ✅ Mensagem de alerta desaparece
   - ✅ Botão "Finalizar Pagamento" desaparece
   - ✅ Status mostra "Ativa" no histórico
   - ✅ Usuário pode usar o sistema imediatamente

### Cenário: Webhook Não Funciona

1. **Usuário faz pagamento** → PIX é processado
2. **Webhook não chega** → Status ainda "aguardando_pagamento"
3. **Usuário acessa página de planos** → Sistema verifica via API
4. **Sistema detecta pagamento** → Atualiza status automaticamente
5. **Interface atualiza** → Mesmo resultado do cenário anterior

## 📊 Arquivos Modificados

1. ✅ `authentication/views.py`:
   - Método `tem_assinatura_aguardando_pagamento()` atualizado
   - Novo método `verificar_e_atualizar_pagamentos_pendentes()` adicionado
   - `get_context_data()` atualizado para verificar antes de exibir

2. ✅ `templates/authentication/plan_selection.html`:
   - Nenhuma alteração necessária (já estava correto)
   - Botão e mensagem desaparecem automaticamente quando status muda

## 🧪 Testes Recomendados

1. **Teste de Pagamento Confirmado**:
   - Criar assinatura com status "aguardando_pagamento"
   - Confirmar pagamento no Asaas
   - Acessar página de planos
   - Verificar se status mudou para "ativa"
   - Verificar se mensagem e botão desapareceram

2. **Teste de Pagamento Pendente**:
   - Criar assinatura com status "aguardando_pagamento"
   - Não confirmar pagamento
   - Acessar página de planos
   - Verificar se mensagem e botão ainda aparecem

3. **Teste de Erro de API**:
   - Remover `ASAAS_API_KEY` do `.env`
   - Acessar página de planos
   - Verificar se página carrega normalmente (não quebra)
   - Verificar logs para mensagem de debug

## ⚠️ Notas Importantes

1. **Performance**: Verificação é feita apenas quando há assinaturas pendentes
2. **Rate Limiting**: API do Asaas pode ter limites de requisições
3. **Timeout**: Verificação pode demorar se API estiver lenta (mas não bloqueia página)
4. **Fallback**: Se API falhar, sistema usa status atual do banco
5. **Cache**: Resultados são salvos no banco local para próximas verificações

