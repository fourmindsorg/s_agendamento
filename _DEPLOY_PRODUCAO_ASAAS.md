# 🚀 Deploy em Produção - Configuração Asaas

## ✅ Checklist Antes do Deploy

- [ ] Chave de API de produção obtida do Asaas
- [ ] Variáveis de ambiente configuradas no servidor AWS
- [ ] Testes locais realizados com sucesso
- [ ] Script de verificação executado

## 📋 Configuração no Servidor AWS

### Opção 1: AWS Systems Manager Parameter Store (Recomendado)

```bash
# Conectar ao servidor AWS via SSH ou usar AWS CLI

# Configurar ambiente
aws ssm put-parameter \
  --name "/s_agendamento/ASAAS_ENV" \
  --value "production" \
  --type "String" \
  --overwrite

# Configurar chave de produção
aws ssm put-parameter \
  --name "/s_agendamento/ASAAS_API_KEY_PRODUCTION" \
  --value "$aact_SUA_CHAVE_PRODUCAO_AQUI" \
  --type "SecureString" \
  --overwrite

# Opcional: Configurar chave de sandbox (para testes)
aws ssm put-parameter \
  --name "/s_agendamento/ASAAS_API_KEY_SANDBOX" \
  --value "$aact_SUA_CHAVE_SANDBOX_AQUI" \
  --type "SecureString" \
  --overwrite
```

### Opção 2: Arquivo .env no Servidor

```bash
# Conectar ao servidor AWS
ssh user@servidor

# Editar .env
nano /opt/s-agendamento/.env

# Adicionar:
ASAAS_ENV=production
ASAAS_API_KEY_PRODUCTION=$aact_SUA_CHAVE_PRODUCAO_AQUI
ASAAS_API_KEY_SANDBOX=$aact_SUA_CHAVE_SANDBOX_AQUI
```

### Opção 3: Variáveis de Ambiente do Sistema

Se o servidor usar systemd ou outro gerenciador de processos:

```bash
# Editar arquivo de serviço
sudo nano /etc/systemd/system/s-agendamento.service

# Adicionar na seção [Service]:
Environment="ASAAS_ENV=production"
Environment="ASAAS_API_KEY_PRODUCTION=$aact_SUA_CHAVE_PRODUCAO_AQUI"
Environment="ASAAS_API_KEY_SANDBOX=$aact_SUA_CHAVE_SANDBOX_AQUI"

# Recarregar e reiniciar
sudo systemctl daemon-reload
sudo systemctl restart s-agendamento
```

## 🔍 Verificar Configuração Após Deploy

### 1. Verificar Variáveis de Ambiente

```bash
# No servidor AWS
python manage.py shell
>>> import os
>>> print(f"ASAAS_ENV: {os.environ.get('ASAAS_ENV', 'NÃO CONFIGURADO')}")
>>> print(f"ASAAS_API_KEY_PRODUCTION: {'✅' if os.environ.get('ASAAS_API_KEY_PRODUCTION') else '❌'}")
>>> print(f"ASAAS_API_KEY_SANDBOX: {'✅' if os.environ.get('ASAAS_API_KEY_SANDBOX') else '❌'}")
```

### 2. Verificar Settings do Django

```python
python manage.py shell
>>> from django.conf import settings
>>> print(f"ASAAS_ENV: {getattr(settings, 'ASAAS_ENV', 'NÃO CONFIGURADO')}")
>>> print(f"ASAAS_API_KEY: {'✅ Configurada' if getattr(settings, 'ASAAS_API_KEY', None) else '❌ Não configurada'}")
>>> print(f"ASAAS_ENABLED: {getattr(settings, 'ASAAS_ENABLED', False)}")

>>> from financeiro.services.asaas import AsaasClient
>>> client = AsaasClient()
>>> print(f"Base URL: {client.base}")
>>> print(f"Ambiente: {client.env}")
```

### 3. Testar Conexão

```bash
# No servidor AWS
python manage.py shell
>>> from financeiro.services.asaas import AsaasClient
>>> client = AsaasClient()
>>> # Testar listar clientes (não deve dar erro)
>>> try:
...     client.list_customers(limit=1)
...     print("✅ Conexão com Asaas OK!")
... except Exception as e:
...     print(f"❌ Erro: {e}")
```

## 📝 Estrutura de Arquivos

### settings_production_aws.py

O arquivo `core/settings_production_aws.py` **herda** todas as configurações do `settings.py`, incluindo:
- ✅ Lógica de chaves por ambiente (`ASAAS_API_KEY_SANDBOX` e `ASAAS_API_KEY_PRODUCTION`)
- ✅ Seleção automática da chave baseada em `ASAAS_ENV`
- ✅ Habilitar/desabilitar baseado na presença da chave

**Não é necessário** configurar nada adicional no código, apenas as variáveis de ambiente!

## 🚨 Problemas Comuns

### Asaas não funciona após deploy

**Sintomas:**
- Erro ao criar pagamento
- QR Code não aparece
- Erro 401 (não autorizado)

**Soluções:**
1. Verificar se `ASAAS_ENV=production` está configurado
2. Verificar se `ASAAS_API_KEY_PRODUCTION` está configurada
3. Verificar se a chave está correta (começa com `$aact_`)
4. Verificar logs do Django: `/opt/s-agendamento/logs/django.log`

### Erro: "ASAAS_API_KEY não configurada"

**Causa:** Variáveis de ambiente não estão sendo carregadas

**Solução:**
1. Verificar se as variáveis estão no Parameter Store ou .env
2. Verificar se o sistema está lendo as variáveis (ver passo "Verificar Configuração")
3. Reiniciar o serviço Django após configurar variáveis

### Ambiente sempre em sandbox

**Causa:** `ASAAS_ENV` não está configurado ou está com valor errado

**Solução:**
```bash
# Verificar valor atual
echo $ASAAS_ENV

# Configurar para produção
export ASAAS_ENV=production
# OU configurar no .env/Parameter Store
```

## ✅ Validação Final

Após o deploy, execute:

```bash
# 1. Verificar configuração
python manage.py shell < _VERIFICAR_CONFIGURACAO_ASAAS.py

# 2. Testar criação de pagamento (com cuidado!)
python financeiro/teste_producao_asaas.py

# 3. Verificar logs
tail -f /opt/s-agendamento/logs/django.log | grep -i asaas
```

## 📞 Próximos Passos

1. ✅ Configurar variáveis de ambiente no servidor
2. ✅ Fazer deploy do código atualizado
3. ✅ Verificar configuração após deploy
4. ✅ Testar criação de pagamento
5. ✅ Monitorar logs e funcionamento

---

**Status**: ✅ Pronto para deploy
**Data**: Janeiro 2025

