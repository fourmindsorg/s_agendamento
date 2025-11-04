# ✅ Aplicar Correção em Produção

## Status
- ✅ Commit realizado: `1f5873a`
- ✅ Push concluído para `origin/main`
- ⏳ Aguardando aplicação no servidor

---

## 📋 Passos para Aplicar no Servidor AWS

Execute os seguintes comandos **no servidor AWS**:

### 1. Atualizar Código
```bash
cd ~/s_agendamento
git pull origin main
```

### 2. Verificar Mudanças
```bash
# Ver último commit
git log --oneline -1

# Verificar se os arquivos foram atualizados
grep -n "ASAAS_ENV.*production" core/settings_production_aws.py
grep -n "ASAAS_API_KEY_PRODUCTION" financeiro/services/asaas.py
```

### 3. Reiniciar Gunicorn
```bash
# Reiniciar serviço
sudo systemctl restart gunicorn

# Verificar status
sudo systemctl status gunicorn

# Verificar logs (últimas 20 linhas)
sudo journalctl -u gunicorn -n 20
```

### 4. Verificar Socket
```bash
# Verificar se socket foi criado
ls -la /opt/s-agendamento/s-agendamento.sock

# Verificar permissões
stat /opt/s-agendamento/s-agendamento.sock
```

### 5. Recarregar Nginx (se necessário)
```bash
sudo systemctl reload nginx
sudo systemctl status nginx
```

---

## ✅ Verificação

1. **Acesse o site:**
   - https://fourmindstech.com.br/authentication/pagamento/pix/8/

2. **Teste o checkout:**
   - Clique em "Finalizar Compra"
   - Se aparecer erro, a mensagem deve ser:
     ```
     Erro ao processar pagamento: ASAAS_API_KEY não configurada nas variáveis de ambiente. 
     Configure ASAAS_API_KEY_PRODUCTION no arquivo .env (ou use ASAAS_API_KEY como fallback). 
     Ambiente atual: production
     ```

3. **Verificar logs do Django:**
   ```bash
   tail -f /opt/s-agendamento/logs/django.log
   ```

---

## 🔧 O que foi corrigido?

1. **`core/settings_production_aws.py`:**
   - Força `ASAAS_ENV = "production"` em produção
   - Recarrega `ASAAS_API_KEY` usando `ASAAS_API_KEY_PRODUCTION`

2. **`financeiro/services/asaas.py`:**
   - Detecta produção automaticamente via `DEBUG=False`
   - Sempre mostra `ASAAS_API_KEY_PRODUCTION` na mensagem de erro em produção

---

## 📝 Nota

Se ainda aparecer erro após aplicar, verifique se `ASAAS_API_KEY_PRODUCTION` está configurado no arquivo `.env` do servidor:

```bash
# Verificar se variável existe (sem mostrar valor)
grep -q "ASAAS_API_KEY_PRODUCTION" .env && echo "Variável encontrada" || echo "Variável NÃO encontrada"
```

---

**Status:** ✅ Pronto para aplicar no servidor!


