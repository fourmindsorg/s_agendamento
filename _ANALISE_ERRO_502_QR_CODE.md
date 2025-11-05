# Análise Profunda: Erro 502 Bad Gateway na Geração de QR Code

## 🔴 Problema Identificado

O sistema está retornando **502 Bad Gateway** ao tentar gerar QR codes para pagamentos via API Asaas. Este erro indica que o Nginx não conseguiu se comunicar adequadamente com o backend (Gunicorn/Django).

## 📊 Causas Identificadas

### 1. **Timeout Excessivo na Geração do QR Code** ⚠️ CRÍTICO

**Localização**: `authentication/views.py` - Método `gerar_qr_code_pix()`

**Problema**:
- O método `gerar_qr_code_pix()` pode demorar **até 45-60 segundos** devido a:
  - Aguardo inicial de 2 segundos (`time.sleep(2)`)
  - Loop de até 15 tentativas com intervalo de 3 segundos cada (`time.sleep(3)`)
  - Cada tentativa faz uma chamada HTTP à API Asaas (timeout de 15s)
  - Total: 2s + (15 × 3s) = **até 47 segundos** apenas no loop
  - Mais tempo de criação de cliente e pagamento = **potencialmente mais de 60 segundos**

**Código problemático**:
```python
# Linha 1317-1318
time.sleep(2)  # Aguardo inicial

# Linhas 1327-1386
max_tentativas = 15
max_wait_seconds = 45
while (tentativa < max_tentativas) and (time.time() - start_time < max_wait_seconds):
    # ... tentativa de buscar QR Code ...
    time.sleep(3)  # Aguardo entre tentativas
```

### 2. **Timeouts Não Sincronizados** ⚠️ CRÍTICO

**Configurações atuais**:
- **Gunicorn**: `--timeout 60` (60 segundos)
- **Nginx**: `proxy_read_timeout 60s` (60 segundos)
- **AsaasClient**: `timeout=15` (15 segundos por requisição)

**Problema**:
- Se o processo demorar mais de 60 segundos (o que pode acontecer com os retries), o Nginx fecha a conexão antes do Django responder
- O Nginx retorna 502 Bad Gateway quando o upstream (Gunicorn) não responde a tempo

### 3. **Processamento Síncrono Bloqueante** ⚠️ ALTO

**Problema**:
- A geração do QR code é feita de forma **síncrona** durante a requisição HTTP
- O usuário fica esperando a resposta por até 60+ segundos
- Isso bloqueia workers do Gunicorn, reduzindo capacidade de processamento

**Impacto**:
- Usuários experientes podem pensar que o site travou
- Múltiplos usuários simultâneos podem esgotar workers do Gunicorn
- Aumenta chance de timeouts

### 4. **Webhook Podendo Retornar 502** ⚠️ MÉDIO

**Localização**: `financeiro/views.py` - Função `asaas_webhook()`

**Possíveis problemas**:
- Se houver exceção não tratada durante o processamento do webhook
- Se o webhook tentar fazer chamadas síncronas à API Asaas que demoram muito
- Se houver problema de validação que cause exceção não capturada

**Código verificado**:
- O webhook faz chamada à API Asaas em `AsaasPayment.DoesNotExist` (linha 254-268)
- Essa chamada pode demorar e causar timeout se o webhook não responder rápido

### 5. **Falta de Retorno Imediato** ⚠️ MÉDIO

**Problema**:
- O sistema não retorna resposta imediata ao usuário
- O usuário fica esperando a geração completa do QR code
- Não há indicação clara de progresso

## 🔧 Soluções Propostas

### Solução 1: Aumentar Timeouts (SOLUÇÃO RÁPIDA) ⚡

**Ajustar timeouts do Nginx e Gunicorn**:

1. **Nginx**: Aumentar `proxy_read_timeout` para 120s
2. **Gunicorn**: Aumentar `--timeout` para 120s
3. **Garantir que Nginx > Gunicorn** (Nginx deve esperar mais que o Gunicorn)

**Arquivos a modificar**:
- Scripts de deploy: `infrastructure/deploy_manual.sh`, `infrastructure/deploy_completo.sh`
- Configuração do systemd: Verificar `/etc/systemd/system/s-agendamento.service`

### Solução 2: Processamento Assíncrono (SOLUÇÃO IDEAL) ⭐

**Implementar geração assíncrona do QR code**:

1. **Retornar resposta imediata** após criar o pagamento no Asaas
2. **Salvar `asaas_payment_id`** na assinatura
3. **Gerar QR code em background** ou via AJAX polling
4. **Usuário vê página de "Aguardando QR Code"** e recarrega automaticamente

**Vantagens**:
- Resposta rápida ao usuário
- Não bloqueia workers do Gunicorn
- Melhor experiência do usuário
- Reduz chance de timeouts

### Solução 3: Reduzir Tentativas e Implementar Retry Inteligente (SOLUÇÃO INTERMEDIÁRIA) ⚡

**Otimizar o loop de tentativas**:

1. **Reduzir tentativas iniciais** de 15 para 5
2. **Aumentar intervalo** entre tentativas (5s em vez de 3s)
3. **Implementar retry exponencial backoff**
4. **Retornar resposta parcial** se não conseguir em 20-30 segundos

### Solução 4: Webhook Retornar Imediatamente (SOLUÇÃO CRÍTICA) 🚨

**Processar webhook de forma assíncrona**:

1. **Webhook deve retornar 200 imediatamente** após validar
2. **Processar eventos em background** (Celery ou thread)
3. **Não fazer chamadas à API Asaas** dentro do webhook (síncrono)

**Código atual problemático**:
```python
# financeiro/views.py linha 254-268
except AsaasPayment.DoesNotExist:
    # ⚠️ PROBLEMA: Chamada síncrona à API dentro do webhook
    client = get_asaas_client()
    fetched = client.get_payment(payment_id)  # Pode demorar
```

### Solução 5: Cache e Fallback (SOLUÇÃO COMPLEMENTAR) 💡

**Implementar cache de QR codes**:

1. **Cachear QR codes gerados** (Redis ou banco)
2. **Se não conseguir gerar, retornar página com botão "Tentar novamente"**
3. **Usar payload PIX** para gerar QR code localmente como fallback

## 📋 Plano de Ação Prioritário

### Prioridade 1 (URGENTE) 🚨
1. ✅ Aumentar timeouts do Nginx e Gunicorn para 120s
2. ✅ Fazer webhook retornar 200 imediatamente (sem chamadas síncronas à API)
3. ✅ Reduzir tentativas de QR code para 5 (máximo 25s)

### Prioridade 2 (IMPORTANTE) ⚠️
4. ✅ Implementar retorno imediato após criar pagamento
5. ✅ Melhorar feedback ao usuário (indicador de progresso)
6. ✅ Adicionar logs detalhados para diagnóstico

### Prioridade 3 (MELHORIA) 💡
7. ✅ Implementar processamento assíncrono completo
8. ✅ Cache de QR codes
9. ✅ Retry exponencial backoff

## 🔍 Verificações Necessárias

### 1. Verificar Configuração Atual do Nginx

```bash
# Ver configuração do Nginx
sudo cat /etc/nginx/sites-available/s-agendamento | grep timeout

# Ver logs de erro do Nginx
sudo tail -n 100 /var/log/nginx/error.log | grep -i "502\|timeout\|upstream"
```

### 2. Verificar Configuração do Gunicorn

```bash
# Ver serviço systemd
sudo systemctl status s-agendamento
sudo cat /etc/systemd/system/s-agendamento.service | grep timeout

# Ver logs do Gunicorn
sudo journalctl -u s-agendamento -n 100 | grep -i "timeout\|error\|502"
```

### 3. Verificar Logs do Django

```bash
# Ver logs de erro do Django
sudo tail -n 100 /opt/s-agendamento/logs/gunicorn_error.log | grep -i "asaas\|qr\|timeout"
```

### 4. Testar Webhook

```bash
# Simular webhook do Asaas
curl -X POST https://seudominio.com/financeiro/webhooks/asaas/ \
  -H "Content-Type: application/json" \
  -H "asaas-access-token: SEU_TOKEN" \
  -d '{"event":"PAYMENT_RECEIVED","payment":{"id":"pay_123"}}'
```

## 📝 Notas Importantes

### Sobre o Erro 502
- **502 Bad Gateway** = Nginx não conseguiu se comunicar com o backend
- Geralmente causado por:
  - Timeout do upstream (Gunicorn)
  - Backend crashou ao processar requisição
  - Backend não está rodando
  - Timeout do Nginx menor que o do Gunicorn

### Sobre Webhooks do Asaas
- Webhooks devem responder em **menos de 5 segundos**
- Se demorar mais, o Asaas pode marcar como falha
- Após 30 dias de falhas, a fila pode ser desativada
- Webhooks devem ser **idempotentes** (processar mesmo evento múltiplas vezes sem problema)

### Sobre a Geração de QR Code
- A API Asaas pode demorar **até 30-60 segundos** para gerar o QR Code após criar o pagamento
- O sistema atual tenta até 15 vezes com intervalo de 3s
- Isso pode resultar em **tempo total de 45-60 segundos** apenas esperando o QR Code

## 🎯 Resultado Esperado Após Correções

1. ✅ **Não mais erro 502** ao gerar QR codes
2. ✅ **Resposta rápida** ao usuário (< 5 segundos)
3. ✅ **Webhooks processados** corretamente pelo Asaas
4. ✅ **Melhor experiência** do usuário com feedback claro
5. ✅ **Sistema mais resiliente** a falhas temporárias

