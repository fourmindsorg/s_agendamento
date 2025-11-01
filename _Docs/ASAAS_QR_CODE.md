# Configuração de QR Code PIX - Asaas

## 📋 Problema Comum

O Asaas pode não retornar a imagem do QR Code (`encodedImage` ou `qrCode`) em alguns casos, especialmente:
- Em ambiente sandbox
- Quando há problemas temporários na API
- Em alguns tipos de pagamento

## ✅ Solução Implementada

O sistema agora gera automaticamente o QR Code a partir do **payload PIX** quando a imagem não está disponível na resposta da API.

### Como Funciona

1. **Primeiro tenta usar a imagem do Asaas**: Se a API retornar `encodedImage` ou `qrCode`, usa essas imagens
2. **Se não houver imagem, gera a partir do payload**: Usa a biblioteca `qrcode` para gerar a imagem do QR Code a partir do payload PIX

### Bibliotecas Necessárias

O projeto usa:
- `qrcode[pil]` - Para gerar QR Codes a partir do payload PIX
- `Pillow` - Processamento de imagens (incluso no qrcode[pil])

## 🔧 Instalação

```bash
pip install qrcode[pil]
```

Ou adicione ao `requirements.txt`:
```
qrcode[pil]==7.4.2
```

## 📝 Uso

A função `generate_qr_code_from_payload()` em `financeiro/utils.py` é chamada automaticamente quando:

1. A API Asaas não retorna imagem do QR Code
2. Há necessidade de regenerar o QR Code a partir do payload salvo

### Exemplo Manual

```python
from financeiro.utils import generate_qr_code_from_payload

payload = "00020126580014br.gov.bcb.pix0136..."
qr_code_base64 = generate_qr_code_from_payload(payload)

# Retorna string base64 da imagem PNG do QR Code
# Ou None se houver erro
```

## 🎯 Funcionalidades

### 1. Buscar Dados Existentes

Quando uma assinatura já tem `asaas_payment_id`, o sistema:
- Busca os dados atualizados do pagamento no Asaas
- Obtém o QR Code novamente
- Gera a imagem se necessário

### 2. Geração Automática

O QR Code é gerado automaticamente quando:
- A API não retorna imagem
- Há necessidade de exibir o QR Code novamente

### 3. Fallback Seguro

Se houver erro na geração:
- O sistema continua funcionando
- Mostra mensagem informativa
- Permite copiar o código PIX mesmo sem imagem

## 🔍 Verificação

Para verificar se está funcionando:

1. **Check no template**: O template verifica `pix_data.qr_code_image`
2. **Logs**: Erros são logados mas não interrompem o processo
3. **Fallback**: Sempre há o código PIX copia e cola disponível

## 🚨 Troubleshooting

### QR Code não aparece

1. **Verificar instalação**:
   ```bash
   pip list | grep qrcode
   ```

2. **Verificar payload**: O payload PIX deve ser válido

3. **Verificar logs**: 
   ```python
   # Em authentication/views.py
   logging.warning(f"Não foi possível gerar QR Code: {e}")
   ```

### Erro: "No module named 'qrcode'"

Instale a biblioteca:
```bash
pip install qrcode[pil]
```

### Erro: "No module named 'PIL'"

O `qrcode[pil]` já inclui o Pillow, mas se houver problemas:
```bash
pip install Pillow
```

## 📊 Status da Integração

- ✅ Geração automática de QR Code
- ✅ Fallback seguro quando API não retorna imagem
- ✅ Suporte a dados existentes (busca no Asaas)
- ✅ Logging de erros
- ✅ Template com suporte a QR Code gerado

## 💡 Dicas

1. **Ambiente Sandbox**: Em sandbox, pode ser necessário gerar o QR Code manualmente
2. **Produção**: Em produção, geralmente a API retorna a imagem
3. **Performance**: A geração do QR Code é rápida e não impacta performance
4. **Cache**: Considere cachear o QR Code gerado se necessário

## 🔗 Referências

- [Documentação qrcode](https://github.com/lincolnloop/python-qrcode)
- [API Asaas - PIX](https://docs.asaas.com/reference/obter-qr-code-pix)

