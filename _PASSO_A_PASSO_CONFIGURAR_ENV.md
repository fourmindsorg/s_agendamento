# 📝 Passo a Passo: Configurar .env no Servidor AWS

## 🎯 Objetivo
Configurar as variáveis do Asaas no arquivo `.env` do servidor AWS.

---

## 📋 Passo 1: Conectar ao Servidor

### No seu computador (Windows/Mac/Linux):

```bash
# Conectar via SSH
ssh -i sua-chave.pem ubuntu@52.20.60.108

# OU se usar o domínio:
ssh -i sua-chave.pem ubuntu@fourmindstech.com.br

# Se não tiver a chave, use senha:
ssh ubuntu@52.20.60.108
```

**Dica:** Se estiver usando Windows, pode usar:
- **Git Bash** (já vem com Git)
- **PowerShell** com SSH instalado
- **PuTTY** (interface gráfica)

---

## 📋 Passo 2: Encontrar o Diretório do Projeto

Após conectar, execute:

```bash
# Procurar onde está o manage.py
find / -name "manage.py" 2>/dev/null | grep s-agendamento

# OU verificar diretórios comuns:
ls -la /opt/s-agendamento/
ls -la /home/ubuntu/s-agendamento/
ls -la /var/www/s-agendamento/
```

**Anote o caminho encontrado!** Exemplo: `/opt/s-agendamento`

---

## 📋 Passo 3: Navegar até o Diretório

```bash
# Usar o caminho encontrado no passo anterior
cd /opt/s-agendamento

# OU o caminho que você encontrou
# cd /caminho/encontrado

# Verificar que está no lugar certo
ls -la | grep manage.py
# Deve mostrar: manage.py
```

---

## 📋 Passo 4: Fazer Backup do .env (se existir)

```bash
# Verificar se .env existe
ls -la .env

# Se existir, fazer backup
if [ -f .env ]; then
    cp .env .env.backup.$(date +%Y%m%d)
    echo "✅ Backup criado: .env.backup.$(date +%Y%m%d)"
fi
```

---

## 📋 Passo 5: Obter as Chaves do Asaas

Antes de editar, você precisa das chaves:

### 📌 Chave de Produção:
1. Acesse: https://www.asaas.com/minha-conta/integracoes/chaves-api
2. Faça login
3. Copie a chave que começa com `$aact_`

### 📌 Chave de Sandbox (opcional):
1. Acesse: https://sandbox.asaas.com/minha-conta/integracoes/chaves-api
2. Faça login
3. Copie a chave que começa com `$aact_`

---

## 📋 Passo 6: Editar o Arquivo .env

### Opção A: Usando nano (mais fácil)

```bash
# Abrir o arquivo
nano .env
```

**Se o arquivo não existir**, ele será criado automaticamente.

### Adicionar estas linhas no final do arquivo:

```env
# Configuração Asaas
ASAAS_ENV=production
ASAAS_API_KEY_PRODUCTION=$aact_SUA_CHAVE_PRODUCAO_AQUI
ASAAS_API_KEY_SANDBOX=$aact_SUA_CHAVE_SANDBOX_AQUI
```

**Importante:**
- Substitua `$aact_SUA_CHAVE_PRODUCAO_AQUI` pela chave real de produção
- Substitua `$aact_SUA_CHAVE_SANDBOX_AQUI` pela chave de sandbox (ou remova a linha se não tiver)
- **NÃO deixe espaços** ao redor do `=`
- **NÃO use aspas** ao redor dos valores

### Exemplo correto:

```env
ASAAS_ENV=production
ASAAS_API_KEY_PRODUCTION=$aact_YTU5YTE0M2M2N2I4MTIxN2E2MTExYTBiYjE1MGQ4
ASAAS_API_KEY_SANDBOX=$aact_YTU5YTE0M2M2N2I4MTIxN2E2MTExYTBiYjE1MGQ4
```

### Como salvar no nano:
1. **Ctrl + O** → Salvar (pressione Enter para confirmar)
2. **Ctrl + X** → Sair

---

### Opção B: Usando vi/vim (alternativa)

```bash
# Abrir o arquivo
vi .env
```

1. Pressione **i** para entrar no modo de inserção
2. Adicione as linhas acima
3. Pressione **ESC** para sair do modo de inserção
4. Digite **:wq** e pressione **Enter** para salvar e sair

---

## 📋 Passo 7: Verificar se Está Correto

```bash
# Ver as linhas do Asaas
cat .env | grep ASAAS

# Deve mostrar algo como:
# ASAAS_ENV=production
# ASAAS_API_KEY_PRODUCTION=$aact_...
# ASAAS_API_KEY_SANDBOX=$aact_...
```

**Verificar:**
- ✅ Não há espaços ao redor do `=`
- ✅ As chaves começam com `$aact_`
- ✅ Não há aspas nos valores

---

## 📋 Passo 8: Ajustar Permissões

```bash
# Garantir que apenas o dono pode ler/escrever
chmod 600 .env

# Verificar permissões
ls -la .env
# Deve mostrar: -rw------- (apenas o dono pode ler)
```

---

## 📋 Passo 9: Verificar Qual Serviço Está Rodando

```bash
# Verificar se há serviço systemd
sudo systemctl list-units | grep -E "(s-agendamento|gunicorn|django)"

# OU verificar processos Python
ps aux | grep python | grep manage.py
```

---

## 📋 Passo 10: Reiniciar o Serviço Django

### Se estiver usando systemd:

```bash
# Tentar reiniciar o serviço (pode ter nome diferente)
sudo systemctl restart s-agendamento
# OU
sudo systemctl restart gunicorn
# OU
sudo systemctl restart django

# Verificar se reiniciou corretamente
sudo systemctl status s-agendamento
```

### Se estiver rodando manualmente (screen/tmux):

```bash
# Encontrar o processo
ps aux | grep "python.*manage.py"

# Matar e reiniciar (ou parar com Ctrl+C e reiniciar)
```

### Se estiver usando supervisor:

```bash
sudo supervisorctl restart s-agendamento
```

---

## 📋 Passo 11: Verificar se Funcionou

### Opção A: Usando o script de verificação

```bash
# No diretório do projeto
python3 _VERIFICAR_CONFIGURACAO_ASAAS.py
```

**Deve mostrar:**
- ✅ Ambiente: production
- ✅ API Key: ✅ Configurada
- ✅ Cliente inicializado com sucesso

### Opção B: Verificar manualmente

```bash
# Abrir shell do Django
python3 manage.py shell
```

```python
# No shell Python:
>>> import os
>>> print(f"ASAAS_ENV: {os.environ.get('ASAAS_ENV', 'NÃO ENCONTRADO')}")
>>> print(f"ASAAS_API_KEY_PRODUCTION: {'✅' if os.environ.get('ASAAS_API_KEY_PRODUCTION') else '❌'}")

>>> from django.conf import settings
>>> print(f"ASAAS_ENV: {getattr(settings, 'ASAAS_ENV', 'NÃO CONFIGURADO')}")
>>> print(f"ASAAS_API_KEY: {'✅ Configurada' if getattr(settings, 'ASAAS_API_KEY', None) else '❌ Não configurada'}")

>>> from financeiro.services.asaas import AsaasClient
>>> client = AsaasClient()
>>> print(f"Base URL: {client.base}")
>>> print(f"Ambiente: {client.env}")
>>> exit()
```

**Resultado esperado:**
```
ASAAS_ENV: production
ASAAS_API_KEY_PRODUCTION: ✅
ASAAS_ENV: production
ASAAS_API_KEY: ✅ Configurada
Base URL: https://www.asaas.com/api/v3/
Ambiente: production
```

---

## ✅ Checklist Final

- [ ] Conectado ao servidor via SSH
- [ ] Encontrado o diretório do projeto (com manage.py)
- [ ] Backup do .env criado (se existia)
- [ ] Chaves do Asaas obtidas (produção e sandbox)
- [ ] Arquivo .env editado com as variáveis corretas
- [ ] Verificado que não há espaços ao redor do `=`
- [ ] Permissões ajustadas (chmod 600)
- [ ] Serviço Django reiniciado
- [ ] Verificação executada com sucesso
- [ ] Ambiente mostra "production"
- [ ] API Key mostra "✅ Configurada"

---

## 🚨 Problemas Comuns

### "Variável não encontrada"

**Solução:**
```bash
# Verificar se o .env está no diretório correto
pwd
ls -la .env

# Verificar se o Django está lendo o .env
# Se usar python-dotenv, precisa estar instalado
pip3 list | grep python-dotenv
```

### "Erro 401 - Não autorizado"

**Solução:**
```bash
# Verificar se a chave está correta
cat .env | grep ASAAS_API_KEY_PRODUCTION

# Verificar se não há espaços extras
# Deve ser: ASAAS_API_KEY_PRODUCTION=$aact_...
# NÃO: ASAAS_API_KEY_PRODUCTION = $aact_... (com espaços)
```

### "Ambiente sempre em sandbox"

**Solução:**
```bash
# Verificar valor do ASAAS_ENV
cat .env | grep ASAAS_ENV

# Deve ser: ASAAS_ENV=production
# NÃO: ASAAS_ENV=PRODUCTION (maiúsculas)
# NÃO: ASAAS_ENV = production (com espaços)
```

---

## 📞 Próximos Passos

Após configurar com sucesso:

1. ✅ Testar criação de pagamento (use valor mínimo R$ 5,00)
2. ✅ Verificar logs: `tail -f /opt/s-agendamento/logs/django.log`
3. ✅ Monitorar funcionamento por alguns dias

---

**Status**: ✅ Guia completo passo a passo
**Data**: Janeiro 2025

