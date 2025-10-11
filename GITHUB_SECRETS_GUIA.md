# 🔐 Guia Completo: GitHub Secrets

## 📋 Visão Geral

Este guia mostra **passo a passo** como obter e configurar cada um dos 10 secrets necessários para o CI/CD funcionar.

---

## 🎯 Acesso Rápido

**Configurar secrets em:**
```
https://github.com/fourmindsorg/s_agendamento/settings/secrets/actions
```

**Clique em:** `New repository secret`

---

## 🔑 1. AWS_ACCESS_KEY_ID

### O Que É
Chave de acesso da AWS para o Terraform criar recursos.

### Como Obter

#### Opção A: Criar Nova Chave (Recomendado)

1. **Acesse AWS Console:**
   ```
   https://console.aws.amazon.com/iam/home#/users
   ```

2. **Clique em seu usuário** (ou crie um novo)

3. **Aba "Security credentials"**

4. **Clique em "Create access key"**

5. **Selecione:** "Application running outside AWS"

6. **Copie a Access Key ID**
   ```
   Exemplo: AKIAIOSFODNN7EXAMPLE
   ```

#### Opção B: Usar Existente

```bash
# Ver suas credenciais locais
cat ~/.aws/credentials

# Procure por:
# [default]
# aws_access_key_id = AKIA...
```

### Configurar no GitHub

```
Nome: AWS_ACCESS_KEY_ID
Valor: AKIAIOSFODNN7EXAMPLE
```

---

## 🔑 2. AWS_SECRET_ACCESS_KEY

### O Que É
Chave secreta da AWS (par da Access Key ID).

### Como Obter

**⚠️ IMPORTANTE:** Só é mostrada UMA vez ao criar!

1. **No mesmo momento que criou a Access Key**
2. **Copie a Secret Access Key**
   ```
   Exemplo: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
   ```
3. **⚠️ Salve em local seguro!**

#### Se Perdeu a Secret Key

```bash
# Precisa criar nova Access Key
# Siga os passos do AWS_ACCESS_KEY_ID novamente
```

### Configurar no GitHub

```
Nome: AWS_SECRET_ACCESS_KEY
Valor: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

---

## 🔑 3. DB_PASSWORD

### O Que É
Senha do banco de dados PostgreSQL RDS.

### Como Definir

Escolha uma senha **forte e segura**:

```bash
# Gerar senha aleatória forte
openssl rand -base64 32

# Ou use um gerenciador de senhas
# Exemplo: 1Password, LastPass, Bitwarden
```

### Requisitos

- Mínimo 8 caracteres
- Letras maiúsculas e minúsculas
- Números
- Símbolos (evitar: @, ", /)

### Exemplo

```
senha_segura_postgre_2024!Abc123
```

### Configurar no GitHub

```
Nome: DB_PASSWORD
Valor: senha_segura_postgre_2024!Abc123
```

**⚠️ ATENÇÃO:** Esta mesma senha deve ser usada no `terraform.tfvars`!

---

## 🔑 4. DB_NAME

### O Que É
Nome do banco de dados.

### Valor Padrão

```
agendamentos_db
```

### Configurar no GitHub

```
Nome: DB_NAME
Valor: agendamentos_db
```

---

## 🔑 5. DB_USER

### O Que É
Usuário do banco de dados PostgreSQL.

### Valor Padrão

```
postgres
```

### Configurar no GitHub

```
Nome: DB_USER
Valor: postgres
```

---

## 🔑 6. DB_HOST

### O Que É
Endpoint do RDS PostgreSQL.

### Como Obter

#### Após Primeiro Deploy Terraform

```bash
# Executar
cd aws-infrastructure
terraform output rds_endpoint

# Output será algo como:
# sistema-agendamento-4minds-postgres.cgr24gyuwi3d.us-east-1.rds.amazonaws.com:5432
```

#### Via AWS Console

1. **Acesse:** https://console.aws.amazon.com/rds/
2. **Clique no banco:** `sistema-agendamento-4minds-postgres`
3. **Copie o "Endpoint"**

### Configurar no GitHub

```
Nome: DB_HOST
Valor: sistema-agendamento-4minds-postgres.cgr24gyuwi3d.us-east-1.rds.amazonaws.com
```

**⚠️ NÃO incluir a porta `:5432`**

---

## 🔑 7. DB_PORT

### O Que É
Porta do PostgreSQL.

### Valor Padrão

```
5432
```

### Configurar no GitHub

```
Nome: DB_PORT
Valor: 5432
```

---

## 🔑 8. SECRET_KEY

### O Que É
Chave secreta do Django para criptografia.

### Como Gerar

#### Opção A: Via Python

```bash
python -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())'
```

#### Opção B: Via Script

```python
# criar_secret_key.py
from django.core.management.utils import get_random_secret_key
print(get_random_secret_key())
```

```bash
python criar_secret_key.py
```

#### Opção C: Online

```
https://djecrety.ir/
```

### Exemplo de Output

```
django-insecure-+9!x8k@2#4%^&*(mn_abc123xyz789-secretkey-exemplo
```

### Configurar no GitHub

```
Nome: SECRET_KEY
Valor: django-insecure-+9!x8k@2#4%^&*(mn_abc123xyz789-secretkey-exemplo
```

**⚠️ NUNCA compartilhe esta chave!**

---

## 🔑 9. SSH_PRIVATE_KEY

### O Que É
Chave SSH privada para conectar na EC2.

### Como Obter

#### Se Já Tem Chave SSH

```bash
# Ver sua chave privada
cat ~/.ssh/id_rsa

# Output será algo como:
# -----BEGIN OPENSSH PRIVATE KEY-----
# b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAA...
# ... (múltiplas linhas) ...
# -----END OPENSSH PRIVATE KEY-----
```

**Copie TODO o conteúdo**, incluindo:
- `-----BEGIN OPENSSH PRIVATE KEY-----`
- `-----END OPENSSH PRIVATE KEY-----`

#### Se NÃO Tem Chave SSH

```bash
# Gerar nova chave SSH
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""

# Ver chave privada
cat ~/.ssh/id_rsa

# Ver chave pública (para adicionar ao Terraform)
cat ~/.ssh/id_rsa.pub
```

### Windows

```powershell
# PowerShell
# Gerar chave
ssh-keygen -t rsa -b 4096 -f $env:USERPROFILE\.ssh\id_rsa

# Ver chave privada
cat $env:USERPROFILE\.ssh\id_rsa

# Ver chave pública
cat $env:USERPROFILE\.ssh\id_rsa.pub
```

### Configurar no GitHub

```
Nome: SSH_PRIVATE_KEY
Valor: 
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAABlwAAAAdzc2gtcn
... (todas as linhas da chave) ...
-----END OPENSSH PRIVATE KEY-----
```

**⚠️ IMPORTANTE:**
- Cole a chave COMPLETA
- Mantenha as quebras de linha
- Não adicione espaços extras

---

## 🔑 10. NOTIFICATION_EMAIL

### O Que É
Email para receber alertas do CloudWatch.

### Valor

```
fourmindsorg@gmail.com
```

### Configurar no GitHub

```
Nome: NOTIFICATION_EMAIL
Valor: fourmindsorg@gmail.com
```

---

## ✅ Checklist de Verificação

Após configurar todos os secrets:

```
□ AWS_ACCESS_KEY_ID          - Chave AWS
□ AWS_SECRET_ACCESS_KEY      - Secret AWS
□ DB_PASSWORD                - Senha forte criada
□ DB_NAME                    - agendamentos_db
□ DB_USER                    - postgres
□ DB_HOST                    - Endpoint RDS (após deploy)
□ DB_PORT                    - 5432
□ SECRET_KEY                 - Chave Django gerada
□ SSH_PRIVATE_KEY            - Chave SSH completa
□ NOTIFICATION_EMAIL         - fourmindsorg@gmail.com
```

---

## 🧪 Testar Secrets

### Verificar se Secrets Estão Configurados

1. Acesse: https://github.com/fourmindsorg/s_agendamento/settings/secrets/actions
2. Deve listar 10 secrets
3. ✅ Se mostrar todos = OK!

### Testar com Workflow

```bash
# Fazer commit test
git add .
git commit -m "Test CI/CD secrets"
git push origin main

# Ver workflow
# https://github.com/fourmindsorg/s_agendamento/actions

# Se passar = Secrets estão corretos! ✅
```

---

## ⚠️ Segurança

### ✅ Boas Práticas

```
✅ NUNCA commitar secrets no código
✅ Usar secrets do GitHub
✅ Rotacionar chaves periodicamente
✅ Usar senhas fortes
✅ Restringir acesso aos secrets
✅ Auditar uso dos secrets
```

### ❌ Evitar

```
❌ Compartilhar secrets por email
❌ Colocar secrets em arquivos públicos
❌ Usar senhas fracas
❌ Reutilizar senhas
❌ Deixar secrets em logs
```

---

## 🔄 Atualizar Secrets

### Quando Atualizar

- **Imediatamente:** Se secret foi comprometido
- **Periodicamente:** A cada 90 dias
- **Após saída de membro:** Da equipe

### Como Atualizar

1. **Acesse:** https://github.com/fourmindsorg/s_agendamento/settings/secrets/actions
2. **Clique no secret**
3. **Update**
4. **Cole novo valor**
5. **Update secret**

---

## 🛠️ Troubleshooting

### Erro: "AWS credentials not found"

**Causa:** AWS_ACCESS_KEY_ID ou AWS_SECRET_ACCESS_KEY incorretos

**Solução:**
```bash
# Verificar credenciais localmente
aws sts get-caller-identity

# Se funcionar localmente, copiar os mesmos valores para GitHub
cat ~/.aws/credentials
```

### Erro: "Permission denied (publickey)"

**Causa:** SSH_PRIVATE_KEY incorreto

**Solução:**
```bash
# Verificar chave SSH
cat ~/.ssh/id_rsa

# Deve começar com: -----BEGIN OPENSSH PRIVATE KEY-----
# Copiar TODO o conteúdo para o secret
```

### Erro: "Database connection failed"

**Causa:** DB_HOST, DB_PASSWORD ou DB_USER incorretos

**Solução:**
```bash
# Verificar endpoint RDS
cd aws-infrastructure
terraform output rds_endpoint

# Verificar senha no terraform.tfvars
cat terraform.tfvars | grep db_password
```

---

## 📚 Documentação Relacionada

- `GITHUB_CICD_SETUP.md` - Guia completo CI/CD
- `_GUIA_RAPIDO_CICD.md` - Setup rápido
- `_RESUMO_CICD.md` - Resumo do CI/CD

---

## 📞 Suporte

**Email:** fourmindsorg@gmail.com  
**GitHub:** https://github.com/fourmindsorg  

**Precisa de ajuda?**
1. Verifique este guia primeiro
2. Veja `GITHUB_CICD_SETUP.md`
3. Entre em contato se ainda tiver dúvidas

---

## ✅ Conclusão

```
╔══════════════════════════════════════════════════════════╗
║                                                          ║
║     📋 GUIA DE SECRETS COMPLETO                         ║
║                                                          ║
║  Total de Secrets:        10                            ║
║  Obrigatórios:            10                            ║
║  Opcionais:               0                             ║
║                                                          ║
║  🔐 Segurança:            Máxima                        ║
║  📚 Documentação:         Completa                      ║
║  ✅ Pronto para usar                                    ║
║                                                          ║
╚══════════════════════════════════════════════════════════╝
```

---

*Guia de Secrets - Versão 1.0*  
*Data: 11 de Outubro de 2025*  
*Organização: fourmindsorg*

