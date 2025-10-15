# 🔧 Troubleshooting - Deploy Falhando

## 🚨 Problema Atual
O deploy está falhando mesmo com os secrets configurados no GitHub.

## 🔍 Diagnóstico Passo a Passo

### 1. Verificar Secrets no GitHub
- Acesse: https://github.com/fourmindsorg/s_agendamento/settings/secrets/actions
- Confirme que TODOS estes secrets existem:
  - ✅ AWS_ACCESS_KEY_ID
  - ✅ AWS_SECRET_ACCESS_KEY
  - ✅ EC2_SSH_KEY
  - ✅ DB_PASSWORD
  - ✅ DB_HOST

### 2. Verificar Logs do Workflow
1. Acesse: https://github.com/fourmindsorg/s_agendamento/actions
2. Clique no último workflow "Deploy to AWS"
3. Clique em "Deploy to Production"
4. Verifique os logs detalhados

### 3. Problemas Comuns e Soluções

#### ❌ Erro: "Credentials could not be loaded"
**Causa:** Secrets AWS não configurados ou incorretos
**Solução:**
- Verifique se AWS_ACCESS_KEY_ID e AWS_SECRET_ACCESS_KEY estão configurados
- Confirme que não há espaços extras nos valores
- Verifique se as chaves não expiraram

#### ❌ Erro: "Permission denied (publickey)"
**Causa:** Chave SSH incorreta ou não configurada
**Solução:**
- Verifique se EC2_SSH_KEY está configurado
- Confirme que a chave inclui as linhas BEGIN e END
- Verifique se não há quebras de linha extras

#### ❌ Erro: "Connection refused" ou "Connection timeout"
**Causa:** Problema de conectividade ou servidor inacessível
**Solução:**
- Verifique se a EC2 está rodando
- Confirme se o IP está correto (34.228.191.215)
- Verifique se o Security Group permite SSH (porta 22)

#### ❌ Erro: "Database connection failed"
**Causa:** Problema com RDS ou configuração de banco
**Solução:**
- Verifique se DB_PASSWORD e DB_HOST estão configurados
- Confirme se o RDS está rodando
- Verifique se o Security Group permite conexão da EC2 para o RDS

### 4. Testar Conectividade Local

#### Teste SSH Local:
```bash
# No Windows, use o arquivo .pem
ssh -i s_agendametnos_key_pairs_AWS.pem ubuntu@34.228.191.215

# Teste rápido de conectividade
ssh -o BatchMode=yes -o ConnectTimeout=10 ubuntu@34.228.191.215 exit
```

#### Teste Ping:
```bash
# Windows
ping -n 4 34.228.191.215

# Linux/Mac
ping -c 4 34.228.191.215
```

### 5. Deploy Manual via GitHub Actions

Se o deploy automático falhar:
1. Acesse: https://github.com/fourmindsorg/s_agendamento/actions
2. Clique em "Deploy to AWS"
3. Clique em "Run workflow"
4. Selecione "main" e clique em "Run workflow"

### 6. Verificar Status do Servidor

#### Status da EC2:
- Acesse AWS Console → EC2 → Instances
- Verifique se a instância está "running"
- Confirme se o IP público está correto

#### Status do RDS:
- Acesse AWS Console → RDS → Databases
- Verifique se o banco está "Available"
- Confirme se o endpoint está correto

### 7. Logs Importantes

#### Logs do Workflow:
- Acesse a URL do último workflow
- Verifique cada step do deploy
- Procure por mensagens de erro específicas

#### Logs do Servidor:
```bash
# Conectar via SSH
ssh -i s_agendametnos_key_pairs_AWS.pem ubuntu@34.228.191.215

# Verificar logs do Django
sudo journalctl -u django -f

# Verificar logs do Nginx
sudo tail -f /var/log/nginx/error.log
```

## 🆘 Suporte

Se o problema persistir:
1. 📧 Email: fourmindsorg@gmail.com
2. 🔗 Repositório: https://github.com/fourmindsorg/s_agendamento
3. 📋 Inclua:
   - URL do workflow que falhou
   - Logs de erro específicos
   - Resultado dos testes de conectividade

---
**Última Atualização:** Outubro 2025
