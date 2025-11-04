# 🔑 Configurar ASAAS_API_KEY em Produção

## ❌ Problema
Erro: "ASAAS_API_KEY não configurada nas variáveis de ambiente. Ambiente atual: sandbox"

## ✅ Solução

### 1. Atualizar Código
```bash
cd ~/s_agendamento
git pull origin main
```

### 2. Verificar se ASAAS_API_KEY está configurada
```bash
# Verificar no arquivo .env
cat .env | grep ASAAS_API_KEY

# Se não mostrar nada, precisa adicionar
```

### 3. Adicionar ASAAS_API_KEY no .env
```bash
# Editar arquivo .env
nano .env
```

Adicionar a linha (se não existir):
```bash
ASAAS_API_KEY=$aact_SUA_CHAVE_PRODUCAO_AQUI
```

**IMPORTANTE:**
- Substitua `$aact_SUA_CHAVE_PRODUCAO_AQUI` pela sua chave real do Asaas
- A chave deve começar com `$aact_` ou `aact_`
- Não deixe espaços antes ou depois do `=`

Exemplo:
```bash
ASAAS_API_KEY=$aact_YTU5YTE0M2M2N2I4MTIxN2E2MTExYTBiYjE1MGQ4
```

### 4. Verificar se foi salvo
```bash
# Verificar se a linha existe
cat .env | grep ASAAS_API_KEY

# Deve mostrar a linha com a chave
```

### 5. Testar se está sendo carregada
```bash
python manage.py shell
```

```python
>>> import os
>>> from dotenv import load_dotenv
>>> load_dotenv()
>>> print(os.environ.get('ASAAS_API_KEY'))
# Deve mostrar a chave (ou None se não estiver configurada)
```

### 6. Reiniciar Gunicorn
```bash
sudo systemctl restart gunicorn
# OU
sudo systemctl restart s-agendamento

# Verificar status
sudo systemctl status gunicorn
```

### 7. Testar Novamente
Tente gerar o QR Code PIX novamente. A mensagem de erro deve mostrar:
- "Ambiente atual: production" (não mais sandbox)
- Se ainda mostrar erro, será porque a chave não está configurada, mas pelo menos o ambiente estará correto

---

## 🔍 Verificar Detecção de Produção

```bash
python manage.py shell
```

```python
>>> from financeiro.services.asaas import AsaasClient
>>> import socket
>>> print("Hostname:", socket.gethostname())
>>> # Se o hostname contiver "ip-", "ec2", "aws" ou "fourmindstech", será detectado como produção
>>> 
>>> try:
...     client = AsaasClient()
...     print("✅ Cliente criado")
...     print("Ambiente:", client.env)
... except RuntimeError as e:
...     print("❌ Erro:", e)
```

---

## 📋 Checklist

- [ ] Código atualizado: `git pull origin main`
- [ ] ASAAS_API_KEY configurada no `.env`
- [ ] Chave testada no shell Python
- [ ] Gunicorn reiniciado
- [ ] Teste de geração de QR Code realizado
- [ ] Mensagem mostra "Ambiente atual: production"

---

## 🚨 Se ainda mostrar "sandbox"

1. **Verificar hostname:**
   ```bash
   hostname
   # Se mostrar algo como "ip-10-0-1-9", deve detectar como produção
   ```

2. **Forçar produção no .env:**
   ```bash
   # Adicionar no .env
   ASAAS_ENV=production
   ```

3. **Verificar logs:**
   ```bash
   sudo journalctl -u gunicorn -n 50 | grep AsaasClient
   # Deve mostrar logs de detecção de produção
   ```

---

**Status:** ✅ Pronto para configurar ASAAS_API_KEY

