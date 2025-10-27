# 🔐 Como Configurar AWS Secrets no GitHub

## O Problema
```
Error: The security token included in the request is invalid.
```

Isso significa que os AWS credentials não estão configurados no GitHub.

## ✅ Solução

### Passo 1: Obter AWS Credentials

Você precisa das suas credenciais AWS:
- AWS Access Key ID
- AWS Secret Access Key

**Onde encontrar:**
1. AWS Console → IAM → Users → Seu usuário
2. Security credentials tab
3. Create access key (ou usar existente)

### Passo 2: Adicionar Secrets no GitHub

1. Acesse o repositório: https://github.com/fourmindsorg/s_agendamento
2. Vá em: **Settings** → **Secrets and variables** → **Actions**
3. Clique em **New repository secret**
4. Adicione os seguintes secrets:

#### Secret 1:
- **Name:** `AWS_ACCESS_KEY_ID`
- **Secret:** `<sua access key id>`

#### Secret 2:
- **Name:** `AWS_SECRET_ACCESS_KEY`
- **Secret:** `<sua secret access key>`

#### Secret 3 (para deploy via SSH):
- **Name:** `EC2_SSH_KEY`
- **Secret:** `<conteúdo da chave SSH privada (arquivo .pem)>`
- **Como obter:** Exporte a chave SSH da EC2 ou crie uma nova chave

5. Clique em **Add secret** para cada secret

### Passo 3: Verificar Permissões IAM

Seu usuário AWS precisa ter permissões para:
- `ssm:SendCommand`
- `ssm:GetCommandInvocation`
- `ssm:ListCommands`

### Passo 4: Fazer o Deploy

Após configurar os secrets:

```bash
git push origin main
```

O workflow vai:
1. Verificar se os secrets existem ✅
2. Configurar AWS credentials ✅
3. Tentar deploy via SSM primeiro ✅
4. Se SSM não estiver disponível, fazer deploy via SSH ✅

## 🔍 Troubleshooting

### "The security token included in the request is invalid"
- Verifique se os secrets estão com os nomes corretos
- Verifique se as credenciais são válidas

### "User is not authorized to perform: ssm:SendCommand"
- Adicione a política `AmazonSSMFullAccess` ao seu usuário AWS

### Deploy pula automaticamente
- O workflow avisa: "AWS credentials não configurados"
- Configure os secrets seguindo o Passo 2

## 📝 Alternativa: Deploy Manual

Se não quiser configurar os secrets agora, pode fazer deploy manual:

```bash
# Conectar ao servidor
aws ssm start-session --target i-0077873407e4114b1

# Executar deploy
cd /opt/s-agendamento
sudo bash infrastructure/deploy_completo.sh
```

## 🎯 Próximos Passos

1. Configure os secrets no GitHub ✅
2. Faça push: `git push origin main`
3. Monitore em Actions
4. Teste: http://52.91.139.151

