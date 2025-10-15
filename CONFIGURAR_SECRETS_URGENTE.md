# 🚨 CONFIGURAR SECRETS URGENTE - GitHub Actions

## ❌ Problema Atual
O deploy está falhando com erro: `Credentials could not be loaded, please check your action inputs: Could not load credentials from any providers`

## ✅ Solução Imediata

### 1. Acesse o GitHub
- Vá para: https://github.com/fourmindsorg/s_agendamento/settings/secrets/actions
- Clique em "New repository secret"

### 2. Configure os Secrets (OBRIGATÓRIO)

#### **AWS_ACCESS_KEY_ID**
- **Nome:** `AWS_ACCESS_KEY_ID`
- **Valor:** `[Sua chave de acesso AWS - Formato: AKIA...]`

#### **AWS_SECRET_ACCESS_KEY**
- **Nome:** `AWS_SECRET_ACCESS_KEY`
- **Valor:** `[Sua chave secreta AWS - 40 caracteres]`

#### **EC2_SSH_KEY**
- **Nome:** `EC2_SSH_KEY`
- **Valor:** [Conteúdo completo do arquivo `s_agendametnos_key_pairs_AWS.pem`]
- **Como obter:**
  ```bash
  cat s_agendametnos_key_pairs_AWS.pem
  # Copie TODO o conteúdo incluindo -----BEGIN RSA PRIVATE KEY----- e -----END RSA PRIVATE KEY-----
  ```

#### **DB_PASSWORD**
- **Nome:** `DB_PASSWORD`
- **Valor:** `4mindsPassword_db_Postgre`

#### **DB_HOST**
- **Nome:** `DB_HOST`
- **Valor:** `agendamento-4minds-postgres.cgr24gyuwi3d.us-east-1.rds.amazonaws.com`

### 3. Verificar Configuração
Após configurar todos os secrets, você deve ver:
- ✅ AWS_ACCESS_KEY_ID
- ✅ AWS_SECRET_ACCESS_KEY
- ✅ EC2_SSH_KEY
- ✅ DB_PASSWORD
- ✅ DB_HOST

### 4. Testar Deploy
Após configurar os secrets:

1. **Deploy Automático:**
   ```bash
   git add .
   git commit -m "test: trigger deploy after secrets config"
   git push origin main
   ```

2. **Deploy Manual:**
   - Acesse: https://github.com/fourmindsorg/s_agendamento/actions
   - Clique em "Deploy to AWS"
   - Clique em "Run workflow"
   - Selecione "main" e clique em "Run workflow"

3. **Verificar Status:**
   ```bash
   python verificar_deploy.py
   ```

## 🔍 Verificar Logs do Deploy
Se ainda falhar após configurar os secrets:
1. Acesse: https://github.com/fourmindsorg/s_agendamento/actions
2. Clique no último workflow "Deploy to AWS"
3. Verifique os logs para identificar o problema específico

## 📞 Suporte
- **Email:** fourmindsorg@gmail.com
- **Status do Site:** https://fourmindstech.com.br (funcionando)
- **Admin:** https://fourmindstech.com.br/admin/

---
**⚠️ IMPORTANTE:** Sem os secrets configurados, o deploy NÃO funcionará!