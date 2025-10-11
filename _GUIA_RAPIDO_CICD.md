# ⚡ Guia Rápido CI/CD

## 🎯 Setup em 5 Minutos

### 1. Configurar Secrets (2 min)

Acesse: https://github.com/fourmindsorg/s_agendamento/settings/secrets/actions

**Adicione os 10 secrets obrigatórios:**

```bash
AWS_ACCESS_KEY_ID          → Sua AWS access key
AWS_SECRET_ACCESS_KEY      → Sua AWS secret key
DB_PASSWORD                → senha_segura_postgre
DB_NAME                    → agendamentos_db
DB_USER                    → postgres
DB_HOST                    → <RDS_ENDPOINT>
DB_PORT                    → 5432
SECRET_KEY                 → <DJANGO_SECRET_KEY>
SSH_PRIVATE_KEY            → <SSH_PRIVATE_KEY>
NOTIFICATION_EMAIL         → fourmindsorg@gmail.com
```

### 2. Fazer Push (1 min)

```bash
git add .
git commit -m "Configure CI/CD"
git push origin main
```

### 3. Acompanhar Deploy (2 min)

Acesse: https://github.com/fourmindsorg/s_agendamento/actions

---

## 🚀 Uso Diário

### Deploy Automático

```bash
# Qualquer push para main = deploy automático
git push origin main
```

### Testar Antes de Merge

```bash
# Criar PR = testes automáticos
git checkout -b feature/nova-funcionalidade
git push origin feature/nova-funcionalidade
# Criar PR no GitHub
```

### Deploy Manual

1. Acesse: https://github.com/fourmindsorg/s_agendamento/actions
2. Clique em "Deploy to AWS"
3. Clique em "Run workflow"

---

## 🧪 Testar Localmente

```bash
# Antes de fazer push
flake8 .
python manage.py check
python manage.py test
```

---

## 📊 Ver Status

**URL da aplicação:**
```
http://fourmindstech.com.br/agendamento/
```

**Ver workflows:**
```
https://github.com/fourmindsorg/s_agendamento/actions
```

---

## 🛠️ Troubleshooting Rápido

### Erro no deploy?

1. Ver logs: https://github.com/fourmindsorg/s_agendamento/actions
2. Verificar secrets estão corretos
3. Ver documentação completa: `GITHUB_CICD_SETUP.md`

### SSH falhou?

```bash
# Verificar se a chave SSH está correta
cat ~/.ssh/id_rsa
# Copiar TODO o conteúdo para o secret SSH_PRIVATE_KEY
```

### Terraform falhou?

```bash
# Verificar AWS credentials
aws sts get-caller-identity
```

---

## 📚 Documentação Completa

- `GITHUB_CICD_SETUP.md` - Guia completo do CI/CD
- `.github/workflows/deploy.yml` - Workflow de deploy
- `.github/workflows/test.yml` - Workflow de testes

---

## ✅ Checklist

```
□ Secrets configurados no GitHub
□ SSH key adicionada
□ AWS credentials válidas
□ Push para main realizado
□ Workflow executou com sucesso
□ Aplicação acessível
```

---

**Pronto para usar!** 🚀

*Ver documentação completa: GITHUB_CICD_SETUP.md*

