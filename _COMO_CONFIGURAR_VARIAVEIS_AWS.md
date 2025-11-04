# 🔧 Como Configurar Variáveis de Ambiente no Servidor AWS

## 📋 Opções Disponíveis

Você tem **3 opções** para configurar as variáveis. Recomendamos a **Opção 1** (mais simples) ou **Opção 2** (mais segura).

---

## ✅ Opção 1: Arquivo .env (Recomendado - Mais Simples)

### Passo 1: Conectar ao Servidor

```bash
# Conectar via SSH ao servidor EC2
ssh -i sua-chave.pem ubuntu@52.20.60.108
# OU
ssh -i sua-chave.pem ubuntu@fourmindstech.com.br
```

### Passo 2: Localizar o Projeto

```bash
# Geralmente o projeto está em:
cd /opt/s-agendamento
# OU
cd /home/ubuntu/s-agendamento
# OU
cd /var/www/s-agendamento

# Verificar onde está o manage.py
find / -name "manage.py" 2>/dev/null | grep s-agendamento
```

### Passo 3: Criar/Editar Arquivo .env

```bash
# Navegar até o diretório do projeto
cd /caminho/do/projeto

# Fazer backup do .env existente (se houver)
cp .env .env.backup

# Criar ou editar o arquivo .env
nano .env
# OU
vi .env
```

### Passo 4: Adicionar as Variáveis

Adicione estas linhas no arquivo `.env`:

```env
# Ambiente Asaas
ASAAS_ENV=production

# Chave de API de Produção (obrigatória)
ASAAS_API_KEY_PRODUCTION=$aact_SUA_CHAVE_PRODUCAO_AQUI

# Chave de API de Sandbox (opcional, para testes)
ASAAS_API_KEY_SANDBOX=$aact_SUA_CHAVE_SANDBOX_AQUI

# Webhook Token (opcional)
ASAAS_WEBHOOK_TOKEN=seu_token_webhook_aqui
```

**Importante:**
- Substitua `$aact_SUA_CHAVE_PRODUCAO_AQUI` pela sua chave real de produção
- Substitua `$aact_SUA_CHAVE_SANDBOX_AQUI` pela sua chave de sandbox (se quiser)
- Não deixe espaços ao redor do `=`

### Passo 5: Salvar e Verificar

```bash
# Salvar no nano: Ctrl+O, Enter, Ctrl+X
# Salvar no vi: ESC, :wq, Enter

# Verificar se o arquivo foi criado corretamente
cat .env | grep ASAAS

# Verificar permissões (deve ser legível pelo usuário do Django)
chmod 600 .env  # Apenas o dono pode ler/escrever
```

### Passo 6: Reiniciar o Serviço Django

```bash
# Se estiver usando systemd
sudo systemctl restart s-agendamento
# OU
sudo systemctl restart gunicorn
# OU
sudo systemctl restart django

# Verificar status
sudo systemctl status s-agendamento
```

### Passo 7: Verificar se Funcionou

```bash
# Conectar ao shell do Django
cd /caminho/do/projeto
python manage.py shell

# No shell Python:
>>> import os
>>> print(f"ASAAS_ENV: {os.environ.get('ASAAS_ENV', 'NÃO ENCONTRADO')}")
>>> print(f"ASAAS_API_KEY_PRODUCTION: {'✅' if os.environ.get('ASAAS_API_KEY_PRODUCTION') else '❌'}")
>>> exit()

# OU usar o script de verificação
python _VERIFICAR_CONFIGURACAO_ASAAS.py
```

---

## ✅ Opção 2: Variáveis de Ambiente do Sistema (Para systemd)

### Passo 1: Conectar ao Servidor

```bash
ssh -i sua-chave.pem ubuntu@52.20.60.108
```

### Passo 2: Localizar Arquivo de Serviço

```bash
# Verificar onde está o serviço
sudo systemctl status s-agendamento
# OU
ls -la /etc/systemd/system/ | grep s-agendamento
```

### Passo 3: Editar Arquivo de Serviço

```bash
# Editar o arquivo de serviço
sudo nano /etc/systemd/system/s-agendamento.service
# OU
sudo vi /etc/systemd/system/s-agendamento.service
```

### Passo 4: Adicionar Variáveis na Seção [Service]

O arquivo deve ter uma estrutura similar a esta:

```ini
[Unit]
Description=Sistema de Agendamento Django
After=network.target

[Service]
Type=notify
User=ubuntu
WorkingDirectory=/opt/s-agendamento
Environment="ASAAS_ENV=production"
Environment="ASAAS_API_KEY_PRODUCTION=$aact_SUA_CHAVE_PRODUCAO_AQUI"
Environment="ASAAS_API_KEY_SANDBOX=$aact_SUA_CHAVE_SANDBOX_AQUI"
Environment="ASAAS_WEBHOOK_TOKEN=seu_token_aqui"
ExecStart=/usr/bin/python3 /opt/s-agendamento/manage.py runserver 0.0.0.0:8000
Restart=always

[Install]
WantedBy=multi-user.target
```

**Importante:** Adicione as linhas `Environment=` dentro da seção `[Service]`.

### Passo 5: Recarregar e Reiniciar

```bash
# Recarregar configurações do systemd
sudo systemctl daemon-reload

# Reiniciar o serviço
sudo systemctl restart s-agendamento

# Verificar status
sudo systemctl status s-agendamento
```

### Passo 6: Verificar se Funcionou

```bash
# Verificar variáveis no serviço
sudo systemctl show s-agendamento | grep ASAAS

# Testar no shell do Django
python manage.py shell
>>> import os
>>> print(os.environ.get('ASAAS_ENV'))
```

---

## ✅ Opção 3: AWS Systems Manager Parameter Store (Mais Seguro)

### Passo 1: Instalar AWS CLI (se não estiver instalado)

```bash
# No servidor AWS
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Verificar instalação
aws --version
```

### Passo 2: Configurar Credenciais AWS

```bash
# Configurar credenciais (se ainda não estiver)
aws configure
# Digite:
# - AWS Access Key ID: sua_access_key
# - AWS Secret Access Key: sua_secret_key
# - Default region: us-east-1
# - Default output format: json
```

### Passo 3: Criar Parâmetros no Parameter Store

```bash
# Ambiente
aws ssm put-parameter \
  --name "/s_agendamento/ASAAS_ENV" \
  --value "production" \
  --type "String" \
  --region us-east-1

# Chave de Produção (SecureString para segurança)
aws ssm put-parameter \
  --name "/s_agendamento/ASAAS_API_KEY_PRODUCTION" \
  --value "$aact_SUA_CHAVE_PRODUCAO_AQUI" \
  --type "SecureString" \
  --region us-east-1

# Chave de Sandbox (opcional)
aws ssm put-parameter \
  --name "/s_agendamento/ASAAS_API_KEY_SANDBOX" \
  --value "$aact_SUA_CHAVE_SANDBOX_AQUI" \
  --type "SecureString" \
  --region us-east-1
```

### Passo 4: Verificar Parâmetros Criados

```bash
# Listar parâmetros
aws ssm get-parameters-by-path \
  --path "/s_agendamento/" \
  --region us-east-1

# Ver um parâmetro específico
aws ssm get-parameter \
  --name "/s_agendamento/ASAAS_ENV" \
  --region us-east-1
```

### Passo 5: Atualizar Código para Ler do Parameter Store

**⚠️ IMPORTANTE:** Esta opção requer modificar o código para ler do Parameter Store. Se você escolher esta opção, precisamos criar um script que carrega as variáveis do Parameter Store antes do Django iniciar.

Criar arquivo `/opt/s-agendamento/load_ssm_params.sh`:

```bash
#!/bin/bash
# Carregar variáveis do Parameter Store
export ASAAS_ENV=$(aws ssm get-parameter --name "/s_agendamento/ASAAS_ENV" --query "Parameter.Value" --output text --region us-east-1)
export ASAAS_API_KEY_PRODUCTION=$(aws ssm get-parameter --name "/s_agendamento/ASAAS_API_KEY_PRODUCTION" --with-decryption --query "Parameter.Value" --output text --region us-east-1)
export ASAAS_API_KEY_SANDBOX=$(aws ssm get-parameter --name "/s_agendamento/ASAAS_API_KEY_SANDBOX" --with-decryption --query "Parameter.Value" --output text --region us-east-1 2>/dev/null || echo "")
```

E no arquivo de serviço systemd, modificar o ExecStart:

```ini
[Service]
ExecStart=/bin/bash -c 'source /opt/s-agendamento/load_ssm_params.sh && /usr/bin/python3 /opt/s-agendamento/manage.py runserver 0.0.0.0:8000'
```

**Nota:** Esta opção é mais complexa. Recomendamos usar a **Opção 1** ou **Opção 2** primeiro.

---

## 🎯 Qual Opção Escolher?

| Opção | Complexidade | Segurança | Recomendação |
|-------|--------------|-----------|--------------|
| **Opção 1: .env** | ⭐ Fácil | ⭐⭐ Média | ✅ **Recomendado** |
| **Opção 2: systemd** | ⭐⭐ Média | ⭐⭐ Média | ✅ Boa opção |
| **Opção 3: Parameter Store** | ⭐⭐⭐ Complexa | ⭐⭐⭐ Alta | Para ambiente mais crítico |

**Para começar rápido:** Use a **Opção 1** (arquivo .env).

---

## 🔍 Verificar se Está Funcionando

Após configurar, execute:

```bash
# No servidor
cd /caminho/do/projeto
python manage.py shell

# No shell Python:
>>> from django.conf import settings
>>> print(f"ASAAS_ENV: {getattr(settings, 'ASAAS_ENV', 'NÃO CONFIGURADO')}")
>>> print(f"ASAAS_API_KEY: {'✅ Configurada' if getattr(settings, 'ASAAS_API_KEY', None) else '❌ Não configurada'}")
>>> print(f"ASAAS_ENABLED: {getattr(settings, 'ASAAS_ENABLED', False)}")

>>> from financeiro.services.asaas import AsaasClient
>>> client = AsaasClient()
>>> print(f"Base URL: {client.base}")
>>> print(f"Ambiente: {client.env}")
```

**Deve mostrar:**
- `ASAAS_ENV: production`
- `ASAAS_API_KEY: ✅ Configurada`
- `ASAAS_ENABLED: True`
- `Base URL: https://www.asaas.com/api/v3/`
- `Ambiente: production`

---

## 🚨 Problemas Comuns

### "Variável não encontrada"

**Solução:**
1. Verificar se o arquivo `.env` está no diretório correto (onde está o `manage.py`)
2. Verificar se o serviço foi reiniciado após adicionar variáveis
3. Verificar se não há espaços ao redor do `=` no `.env`

### "Erro 401 - Não autorizado"

**Solução:**
1. Verificar se a chave está correta (começa com `$aact_`)
2. Verificar se não há espaços extras na chave
3. Verificar se está usando `ASAAS_API_KEY_PRODUCTION` e não `ASAAS_API_KEY`

### "Ambiente sempre em sandbox"

**Solução:**
1. Verificar se `ASAAS_ENV=production` está configurado
2. Verificar se o valor está em minúsculas (`production`, não `PRODUCTION`)
3. Reiniciar o serviço após mudar

---

## 📞 Próximos Passos

Após configurar as variáveis:
1. ✅ Reiniciar o serviço Django
2. ✅ Verificar configuração com o script
3. ✅ Testar criação de pagamento (cuidado em produção!)
4. ✅ Monitorar logs: `tail -f /opt/s-agendamento/logs/django.log`

---

**Status**: ✅ Guia completo
**Data**: Janeiro 2025

