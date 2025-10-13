# ✅ Configuração GitHub Completa - @fourmindsorg

**Repositório**: https://github.com/fourmindsorg/s_agendamento  
**Data**: 12/10/2025

---

## 📁 Arquivos GitHub Actions Criados

### 1. **`.github/workflows/deploy.yml`** 
Workflow de deploy automático para AWS EC2
- **Trigger**: Push na branch `main`
- **Ações**:
  - Conecta ao servidor EC2
  - Atualiza código do repositório
  - Executa migrações
  - Coleta arquivos estáticos
  - Reinicia serviços Django e Nginx

### 2. **`.github/workflows/terraform.yml`**
Workflow para gerenciar infraestrutura com Terraform
- **Trigger**: Push/PR em `aws-infrastructure/**`
- **Ações**:
  - Valida configuração Terraform
  - Executa `terraform plan`
  - Aplica mudanças na infraestrutura (apenas em main)

### 3. **`.github/workflows/ci.yml`**
Workflow de CI - Testes e Linting
- **Trigger**: Push/PR em `main` e `develop`
- **Ações**:
  - Executa testes com Python 3.10 e 3.11
  - Roda linting com flake8
  - Gera relatório de cobertura
  - Envia para Codecov

### 4. **`.github/workflows/backup.yml`**
Workflow de backup automático do banco
- **Trigger**: Diariamente às 3h UTC (schedule)
- **Ações**:
  - Cria backup do PostgreSQL
  - Upload para S3 Glacier
  - Remove backups antigos (>30 dias)

---

## 🔧 Arquivos de Configuração

### 5. **`.github/dependabot.yml`**
Configuração do Dependabot para atualizar dependências automaticamente
- Python packages (requirements.txt)
- GitHub Actions
- Terraform modules

### 6. **`.github/CODEOWNERS`**
Define @fourmindsorg como owner de todo o código

### 7. **`.github/FUNDING.yml`**
Configuração de financiamento apontando para @fourmindsorg

---

## 📝 Templates

### 8. **`.github/pull_request_template.md`**
Template padronizado para Pull Requests

### 9. **`.github/ISSUE_TEMPLATE/bug_report.md`**
Template para reportar bugs

### 10. **`.github/ISSUE_TEMPLATE/feature_request.md`**
Template para solicitar novas features

---

## 🔐 Secrets Necessários no GitHub

Configure os seguintes secrets no repositório:
https://github.com/fourmindsorg/s_agendamento/settings/secrets/actions

| Secret | Descrição | Valor |
|--------|-----------|-------|
| `AWS_ACCESS_KEY_ID` | Chave de acesso AWS | *(sua chave AWS)* |
| `AWS_SECRET_ACCESS_KEY` | Chave secreta AWS | *(sua chave secreta)* |
| `EC2_SSH_KEY` | Chave privada SSH | *(conteúdo de id_rsa_terraform)* |
| `DB_PASSWORD` | Senha do PostgreSQL RDS | `senha_segura_postgre` |
| `DB_HOST` | Endpoint do RDS | `sistema-agendamento-4minds-postgres.cgr24gyuwi3d.us-east-1.rds.amazonaws.com` |

---

## 🚀 Como Configurar os Secrets

### Passo 1: Acessar Configurações
1. Vá para: https://github.com/fourmindsorg/s_agendamento
2. Clique em **Settings**
3. No menu lateral, clique em **Secrets and variables** → **Actions**

### Passo 2: Adicionar cada Secret
Para cada secret da tabela acima:
1. Clique em **New repository secret**
2. Digite o **Name** (exatamente como na tabela)
3. Cole o **Value**
4. Clique em **Add secret**

### Passo 3: Obter a Chave SSH
Para o secret `EC2_SSH_KEY`:
```bash
type "C:\Users\Carlos Alberto\.ssh\id_rsa_terraform"
```
Copie TODO o conteúdo (incluindo `-----BEGIN` e `-----END`)

---

## 🔄 Como os Workflows Funcionam

### Deploy Automático
```
git push origin main
    ↓
GitHub Actions detecta push
    ↓
Executa deploy.yml
    ↓
Conecta no EC2 via SSH
    ↓
Atualiza código, migra DB, coleta statics
    ↓
Reinicia Django + Nginx
    ↓
✅ Deploy concluído!
```

### Terraform
```
Modificou arquivo em aws-infrastructure/
    ↓
GitHub Actions detecta mudança
    ↓
Executa terraform.yml
    ↓
Valida e planeja mudanças
    ↓
Se for push em main: aplica mudanças
    ↓
✅ Infraestrutura atualizada!
```

### CI/CD
```
Criou Pull Request
    ↓
GitHub Actions executa ci.yml
    ↓
Roda testes + linting
    ↓
Mostra resultado no PR
    ↓
✅ Aprovado ou ❌ Precisa correção
```

### Backup Diário
```
Todo dia às 3h UTC
    ↓
GitHub Actions executa backup.yml
    ↓
Conecta no EC2, cria backup do banco
    ↓
Upload para S3 Glacier
    ↓
Remove backups antigos
    ↓
✅ Backup concluído!
```

---

## 📊 Status dos Workflows

Após configurar os secrets, você poderá ver o status em:
https://github.com/fourmindsorg/s_agendamento/actions

---

## ✅ Checklist de Configuração

- [ ] Repositório criado em @fourmindsorg
- [ ] Código commitado e pushado
- [ ] Secrets configurados no GitHub
- [ ] Primeiro deploy manual executado
- [ ] Workflows testados
- [ ] DNS configurado
- [ ] SSL instalado
- [ ] Backup funcionando

---

## 🌐 Links Úteis

- **Repositório**: https://github.com/fourmindsorg/s_agendamento
- **GitHub Actions**: https://github.com/fourmindsorg/s_agendamento/actions
- **Settings**: https://github.com/fourmindsorg/s_agendamento/settings
- **Issues**: https://github.com/fourmindsorg/s_agendamento/issues
- **Pull Requests**: https://github.com/fourmindsorg/s_agendamento/pulls

---

## 📝 Próximos Passos

1. ✅ **Configurar DNS** (você precisa fazer agora)
2. ⏳ **Aguardar propagação** (5-30 minutos)
3. ⏳ **Instalar SSL** (automático via script)
4. ✅ **Configurar Secrets do GitHub**
5. ✅ **Fazer primeiro push para testar deploy automático**

---

## 🆘 Suporte

- **Email**: fourmindsorg@gmail.com
- **GitHub**: https://github.com/fourmindsorg
- **Documentação**: Ver arquivos na pasta `aws-infrastructure/`

---

**Última atualização**: 12/10/2025  
**Desenvolvido por**: 4Minds Team

