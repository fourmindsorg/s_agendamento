# 🔐 Configuração Detalhada dos Secrets - GitHub Actions

## 🚨 Problema Atual
```
Error: Credentials could not be loaded, please check your action inputs: 
Could not load credentials from any providers
```

Este erro indica que os secrets AWS não estão configurados no GitHub Actions.

## 📋 Passo a Passo para Configurar

### 1. Acesse as Configurações do Repositório
- Vá para: https://github.com/fourmindsorg/s_agendamento
- Clique em **Settings** (aba superior)
- No menu lateral esquerdo, clique em **Secrets and variables**
- Clique em **Actions**

### 2. Configure os Secrets Obrigatórios

#### **Secret 1: AWS_ACCESS_KEY_ID**
- Clique em **"New repository secret"**
- **Name:** `AWS_ACCESS_KEY_ID`
- **Secret:** `[Sua chave de acesso AWS - formato AKIA...]`
- Clique em **"Add secret"**

#### **Secret 2: AWS_SECRET_ACCESS_KEY**
- Clique em **"New repository secret"**
- **Name:** `AWS_SECRET_ACCESS_KEY`
- **Secret:** `[Sua chave secreta AWS - string de 40 caracteres]`
- Clique em **"Add secret"**

#### **Secret 3: EC2_SSH_KEY**
- Clique em **"New repository secret"**
- **Name:** `EC2_SSH_KEY`
- **Secret:** [Conteúdo completo do arquivo `s_agendametnos_key_pairs_AWS.pem`]
- Clique em **"Add secret"**

**Como obter o conteúdo da chave SSH:**
```bash
# No seu computador local, onde está o arquivo .pem
cat s_agendametnos_key_pairs_AWS.pem
# Copie TODO o conteúdo, incluindo as linhas:
# -----BEGIN RSA PRIVATE KEY-----
# [conteúdo da chave]
# -----END RSA PRIVATE KEY-----
```

#### **Secret 4: DB_PASSWORD**
- Clique em **"New repository secret"**
- **Name:** `DB_PASSWORD`
- **Secret:** `4mindsPassword_db_Postgre`
- Clique em **"Add secret"**

#### **Secret 5: DB_HOST**
- Clique em **"New repository secret"**
- **Name:** `DB_HOST`
- **Secret:** `agendamento-4minds-postgres.cgr24gyuwi3d.us-east-1.rds.amazonaws.com`
- Clique em **"Add secret"**

### 3. Verificar Secrets Configurados

Após configurar todos, você deve ver na lista:
- ✅ AWS_ACCESS_KEY_ID
- ✅ AWS_SECRET_ACCESS_KEY
- ✅ EC2_SSH_KEY
- ✅ DB_PASSWORD
- ✅ DB_HOST

### 4. Testar o Deploy

#### Opção A: Deploy Automático
```bash
git add .
git commit -m "test: trigger deploy"
git push origin main
```

#### Opção B: Deploy Manual
1. Acesse: https://github.com/fourmindsorg/s_agendamento/actions
2. Clique em **"Deploy to AWS"**
3. Clique em **"Run workflow"**
4. Selecione **"main"** e clique em **"Run workflow"**

### 5. Verificar Status

Execute o script de verificação:
```bash
# Windows
py verificar_deploy.py

# Linux/Mac
python verificar_deploy.py
```

**Se der erro de módulo não encontrado:**
```bash
# Instalar dependência
py -m pip install requests
```

## 🔍 Troubleshooting

### Erro: "Credentials could not be loaded"
- ✅ Verifique se AWS_ACCESS_KEY_ID e AWS_SECRET_ACCESS_KEY estão configurados
- ✅ Verifique se não há espaços extras nos valores
- ✅ Verifique se as chaves não expiraram

### Erro: "Permission denied (publickey)"
- ✅ Verifique se EC2_SSH_KEY está configurado corretamente
- ✅ A chave deve incluir as linhas BEGIN e END
- ✅ Verifique se não há quebras de linha extras

### Erro: "Database connection failed"
- ✅ Verifique se DB_PASSWORD e DB_HOST estão configurados
- ✅ Verifique se o RDS está rodando
- ✅ Verifique se o Security Group permite conexão da EC2

## 📞 Suporte

Se continuar com problemas:
1. Verifique os logs do workflow: Actions → Deploy to AWS → [último run]
2. Contato: fourmindsorg@gmail.com

---
**Importante:** NUNCA commite credenciais no código. Sempre use GitHub Secrets!
