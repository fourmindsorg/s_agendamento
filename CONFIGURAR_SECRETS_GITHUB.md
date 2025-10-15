# 🔐 Configurar Secrets do GitHub Actions

## 📋 Secrets Necessários

Para o deploy funcionar, configure estes secrets no GitHub:

### 1. Acesse as Configurações
- Vá para: https://github.com/fourmindsorg/s_agendamento/settings/secrets/actions
- Clique em "New repository secret"

### 2. Secrets Obrigatórios

#### **AWS_ACCESS_KEY_ID**
```
Valor: [Sua chave de acesso AWS]
Formato: AKIA...
```

#### **AWS_SECRET_ACCESS_KEY**
```
Valor: [Sua chave secreta AWS]
Formato: [string de 40 caracteres]
```

#### **EC2_SSH_KEY**
```
Valor: [Conteúdo completo da chave privada SSH]
```
**Como obter:**
```bash
# No servidor local onde você tem acesso SSH
cat ~/.ssh/id_rsa
# Copie TODO o conteúdo, incluindo -----BEGIN OPENSSH PRIVATE KEY----- e -----END OPENSSH PRIVATE KEY-----
```

#### **DB_PASSWORD**
```
Valor: 4mindsPassword_db_Postgre
```

#### **DB_HOST**
```
Valor: agendamento-4minds-postgres.cgr24gyuwi3d.us-east-1.rds.amazonaws.com
```

### 3. Verificar Secrets Configurados

Após configurar todos os secrets, você deve ver:
- ✅ AWS_ACCESS_KEY_ID
- ✅ AWS_SECRET_ACCESS_KEY  
- ✅ EC2_SSH_KEY
- ✅ DB_PASSWORD
- ✅ DB_HOST

### 4. Testar Deploy

1. **Deploy Automático:**
   ```bash
   git add .
   git commit -m "test: trigger deploy"
   git push origin main
   ```

2. **Deploy Manual:**
   - Acesse: https://github.com/fourmindsorg/s_agendamento/actions
   - Clique em "Deploy to AWS"
   - Clique em "Run workflow"
   - Selecione "main" e clique em "Run workflow"

### 5. Verificar Status

Execute o script de verificação:
```bash
python verificar_deploy.py
```

## 🚨 Problemas Comuns

### Erro: "Credentials could not be loaded"
- ✅ Verifique se AWS_ACCESS_KEY_ID e AWS_SECRET_ACCESS_KEY estão configurados
- ✅ Verifique se as chaves não expiraram

### Erro: "Permission denied (publickey)"
- ✅ Verifique se EC2_SSH_KEY está configurado corretamente
- ✅ A chave deve incluir as linhas BEGIN e END
- ✅ Verifique se a chave pública está no servidor EC2

### Erro: "Database connection failed"
- ✅ Verifique se DB_PASSWORD e DB_HOST estão configurados
- ✅ Verifique se o RDS está rodando
- ✅ Verifique se o Security Group permite conexão da EC2

## 📞 Suporte

Se continuar com problemas:
1. Verifique os logs do workflow: Actions → Deploy to AWS → [último run]
2. Execute: `python testar_aws_credenciais.py`
3. Contato: fourmindsorg@gmail.com
