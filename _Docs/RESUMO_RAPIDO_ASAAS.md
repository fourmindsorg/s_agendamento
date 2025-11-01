# ⚡ Resumo Rápido - Configuração Asaas PIX

## 🚀 Configuração em 5 Minutos

### 1️⃣ Criar Conta
- Sandbox (testes): https://sandbox.asaas.com/
- Produção: https://www.asaas.com/

### 2️⃣ Obter Chave API
1. Login no Asaas
2. **Minha Conta** → **Integrações** → **Chaves API**
3. **Gerar chave de API**
4. **Copiar chave** (só aparece uma vez!)

### 3️⃣ Configurar no Projeto

Crie arquivo `.env` na raiz:
```env
ASAAS_API_KEY=$aact_SUA_CHAVE_AQUI
ASAAS_ENV=sandbox
```

### 4️⃣ Instalar Dependências
```bash
pip install qrcode[pil]
```

### 5️⃣ Testar
```bash
python manage.py runserver
```
Acesse o sistema e teste um pagamento PIX!

---

## 📋 Checklist Completo

### ✅ Sandbox (Testes)
- [ ] Conta criada em sandbox.asaas.com
- [ ] Chave API gerada
- [ ] Arquivo `.env` criado
- [ ] `ASAAS_API_KEY` configurada
- [ ] `ASAAS_ENV=sandbox` configurado
- [ ] `qrcode[pil]` instalado
- [ ] Teste de pagamento funcionando

### ✅ Produção
- [ ] Conta verificada em asaas.com
- [ ] Chave API de produção gerada
- [ ] Variáveis configuradas no servidor
- [ ] `ASAAS_ENV=production` configurado
- [ ] Webhook configurado (opcional)
- [ ] Teste completo em produção

---

## 🔗 Links Importantes

| Recurso | URL |
|---------|-----|
| Sandbox | https://sandbox.asaas.com/ |
| Produção | https://www.asaas.com/ |
| Documentação | https://docs.asaas.com/ |
| Chaves API | https://www.asaas.com/minha-conta/integracoes/chaves-api |

---

## 🆘 Problemas Comuns

| Problema | Solução |
|----------|---------|
| "Chave inválida" | Verifique se copiou a chave completa |
| "QR Code não aparece" | Execute `pip install qrcode[pil]` |
| "Erro 401" | Verifique ambiente (sandbox vs produção) |
| "Webhook não funciona" | Confirme URL pública e token |

---

## 💡 Dica Pro

**Sempre teste no Sandbox primeiro!** É gratuito e não afeta produção.

Para detalhes completos, veja: `_Docs/GUIA_CONFIGURACAO_ASAAS_PIX.md`

