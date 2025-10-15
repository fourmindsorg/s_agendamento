# 🔧 Informações Atuais do Servidor - Sistema de Agendamento 4Minds

## 📊 Dados de Conexão

### **AWS Credentials**
```
AWS_ACCESS_KEY_ID = [Configure no GitHub Secrets]
AWS_SECRET_ACCESS_KEY = [Configure no GitHub Secrets]
```

### **EC2 Instance**
```
IP Público: 34.228.191.215 (atualizado no workflow)
Hostname: ec2-34-228-191-215.compute-1.amazonaws.com
SSH Key: s_agendametnos_key_pairs_AWS.pem
Comando SSH: ssh -i "s_agendametnos_key_pairs_AWS.pem" ubuntu@34.228.191.215
```

### **RDS PostgreSQL**
```
DB_HOST = agendamento-4minds-postgres.cgr24gyuwi3d.us-east-1.rds.amazonaws.com
DB_NAME = agendamentos_db
DB_USER = postgres
DB_PASSWORD = 4mindsPassword_db_Postgre
DB_PORT = 5432
```

### **Domínio**
```
URL: https://fourmindstech.com.br
Admin: https://fourmindstech.com.br/admin/
Dashboard: https://fourmindstech.com.br/dashboard/
```

## 🔐 GitHub Secrets Necessários

Para o deploy funcionar, configure estes secrets no GitHub Actions:

1. **AWS_ACCESS_KEY_ID**: `[Sua chave de acesso AWS]`
2. **AWS_SECRET_ACCESS_KEY**: `[Sua chave secreta AWS]`
3. **EC2_SSH_KEY**: [Conteúdo do arquivo `s_agendametnos_key_pairs_AWS.pem`]
4. **DB_PASSWORD**: `4mindsPassword_db_Postgre`
5. **DB_HOST**: `agendamento-4minds-postgres.cgr24gyuwi3d.us-east-1.rds.amazonaws.com`

## 📁 Arquivos Atualizados

- ✅ `env.production.example` - DB_HOST e DB_PASSWORD atualizados
- ✅ `CONFIGURAR_SECRETS_GITHUB.md` - Guia de configuração
- ✅ `.github/workflows/deploy.yml` - IP da EC2 atualizado para 34.228.191.215

## 🚀 Próximos Passos

1. **Configure os secrets no GitHub:**
   - Acesse: https://github.com/fourmindsorg/s_agendamento/settings/secrets/actions
   - Adicione todos os secrets listados acima

2. **Teste o deploy:**
   ```bash
   python verificar_deploy.py
   ```

3. **Deploy manual (se necessário):**
   - Acesse: https://github.com/fourmindsorg/s_agendamento/actions
   - Execute "Deploy to AWS" manualmente

## 📞 Suporte

- **Email:** fourmindsorg@gmail.com
- **Repositório:** https://github.com/fourmindsorg/s_agendamento
- **Status:** https://fourmindstech.com.br

---
**Última Atualização:** Outubro 2025  
**Versão:** 2.0 (Produção)
