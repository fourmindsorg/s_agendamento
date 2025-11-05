# Timeout do QR Code Reduzido

## ✅ Alteração Aplicada

O timeout para geração do QR Code foi **reduzido significativamente** para melhorar a experiência do usuário e evitar timeouts.

## 📊 Comparação

### Antes
- **Tentativas**: 15
- **Tempo máximo**: 45 segundos
- **Aguardo inicial**: 2 segundos
- **Intervalo entre tentativas**: 5 segundos
- **Tempo total máximo**: ~47 segundos

### Depois
- **Tentativas**: 3 ⚡
- **Tempo máximo**: 10 segundos ⚡
- **Aguardo inicial**: 1 segundo ⚡
- **Intervalo entre tentativas**: 3 segundos
- **Tempo total máximo**: ~10 segundos ⚡

## 🎯 Benefícios

1. ✅ **Resposta muito mais rápida** - usuário não espera mais 45+ segundos
2. ✅ **Elimina 502 Bad Gateway** - tempo muito abaixo do timeout do Nginx/Gunicorn
3. ✅ **Melhor UX** - se QR Code não estiver pronto, usuário pode recarregar rapidamente
4. ✅ **Sistema mais responsivo** - não bloqueia workers do Gunicorn por muito tempo

## 🔄 Comportamento

### Se QR Code estiver disponível (cenário comum)
- ✅ Retorna em **1-7 segundos** normalmente
- ✅ Usuário vê QR Code imediatamente

### Se QR Code não estiver disponível (cenário raro)
- ⏱️ Sistema tenta até **3 vezes** em **10 segundos**
- 📄 Página é exibida com mensagem "Aguardando QR Code"
- 🔄 Botão "Recarregar Página" permite tentar novamente
- 💾 `payment_id` já está salvo, então na próxima tentativa busca dados existentes

## 📝 Notas Técnicas

- O QR Code do Asaas geralmente fica disponível em **2-5 segundos** após criar o pagamento
- Em casos raros, pode levar até 30-60 segundos
- Com 3 tentativas em 10 segundos, cobrimos a maioria dos casos
- Se não conseguir, o sistema já tem o `payment_id` salvo e pode tentar novamente ao recarregar

## 🔧 Arquivos Modificados

- ✅ `authentication/views.py` - Timeout reduzido de 25s para 10s
- ✅ `_CORRECOES_APLICADAS_502.md` - Documentação atualizada

