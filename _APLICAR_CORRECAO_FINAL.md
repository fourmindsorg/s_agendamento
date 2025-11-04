# 🔧 Aplicar Correção Final - Detecção de Produção

## ✅ Status
- ✅ Commit realizado: `044558f`
- ✅ Push concluído para `origin/main`
- ✅ Detecção robusta de produção implementada
- ✅ Script de diagnóstico criado

---

## 📋 Passos para Aplicar no Servidor AWS

### 1. Atualizar Código
```bash
cd ~/s_agendamento
git pull origin main
```

### 2. Executar Diagnóstico (OPCIONAL - mas recomendado)
```bash
# Executar script de diagnóstico
python manage.py shell < _DIAGNOSTICAR_ASAAS_PRODUCAO.py
```

Este script vai mostrar:
- Qual settings module está sendo usado
- Se DEBUG está False
- Se ASAAS_ENV está configurado
- Se as variáveis de ambiente estão configuradas
- Se o cliente Asaas consegue ser criado

### 3. Verificar Arquivo .env
```bash
# Verificar se o arquivo .env existe e contém a chave
cat .env | grep ASAAS_API_KEY_PRODUCTION

# Se não existir, criar/editar:
nano .env
```

Adicione ou verifique:
```bash
ASAAS_API_KEY_PRODUCTION=$aact_SUA_CHAVE_PRODUCAO_AQUI
```

### 4. Reiniciar Gunicorn
```bash
# Reiniciar serviço
sudo systemctl restart gunicorn

# Verificar status
sudo systemctl status gunicorn

# Ver logs (últimas 50 linhas)
sudo journalctl -u gunicorn -n 50
```

### 5. Verificar Logs do Django
```bash
# Se houver arquivo de log
tail -f /opt/s-agendamento/logs/django.log

# Ou via journalctl
sudo journalctl -u gunicorn -f
```

---

## 🔍 O que foi corrigido?

### 1. Detecção de Produção Robusta
Agora o sistema detecta produção usando **MÚLTIPLOS critérios**:
- ✅ `DEBUG=False` → Produção
- ✅ `DJANGO_SETTINGS_MODULE` contém "production" → Produção
- ✅ `ASAAS_ENV="production"` no settings → Produção
- ✅ `env="production"` passado explicitamente → Produção

### 2. Arquivos de Settings Atualizados
- ✅ `core/settings_production.py` → Força `ASAAS_ENV = "production"`
- ✅ `core/settings_production_aws.py` → Já tinha `ASAAS_ENV = "production"`

### 3. Logs Detalhados
- ✅ Logs detalhados em caso de erro para facilitar diagnóstico
- ✅ Mostra exatamente qual critério está sendo usado

---

## 🧪 Teste

Após aplicar, teste novamente o checkout. A mensagem de erro (se aparecer) deve ser:

```
Erro ao processar pagamento: ASAAS_API_KEY não configurada nas variáveis de ambiente. 
Configure ASAAS_API_KEY_PRODUCTION no arquivo .env (ou use ASAAS_API_KEY como fallback). 
Ambiente atual: production
```

**Importante:** A mensagem deve mostrar **"Ambiente atual: production"** (não mais "sandbox").

---

## 🔧 Troubleshooting

### Se ainda aparecer "sandbox":

1. **Verificar qual settings module está sendo usado:**
   ```bash
   # No servidor, verificar variável de ambiente
   echo $DJANGO_SETTINGS_MODULE
   
   # Verificar no systemd service
   sudo systemctl cat gunicorn | grep DJANGO_SETTINGS_MODULE
   ```

2. **Verificar se o arquivo .env está sendo carregado:**
   ```bash
   # Verificar se o arquivo existe
   ls -la .env
   
   # Verificar conteúdo (sem mostrar valores completos)
   grep -E "ASAAS_API_KEY|ASAAS_ENV" .env
   ```

3. **Executar o script de diagnóstico:**
   ```bash
   python manage.py shell < _DIAGNOSTICAR_ASAAS_PRODUCAO.py
   ```

4. **Verificar logs do Django:**
   ```bash
   # Os logs vão mostrar exatamente qual critério está sendo usado
   tail -f /opt/s-agendamento/logs/django.log
   ```

---

## 📝 Notas

- O script de diagnóstico (`_DIAGNOSTICAR_ASAAS_PRODUCAO.py`) mostra **exatamente** o que está acontecendo
- Se o problema persistir, execute o diagnóstico e envie a saída completa
- A detecção agora funciona independente de qual arquivo de settings está sendo usado

---

**Status:** ✅ Pronto para aplicar no servidor!

