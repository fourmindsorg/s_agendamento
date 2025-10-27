# 🔐 Como Configurar o Secret EC2_SSH_KEY no GitHub

## ⚠️ Problema Atual

O deploy está falhando com erro:
```
Permission denied (publickey)
```

Isso acontece porque o secret `EC2_SSH_KEY` não está configurado no GitHub.

## ✅ Solução - Passo a Passo

### 1. Copiar o Conteúdo da Chave SSH

Execute este comando no terminal local para ver o conteúdo completo da chave:

```bash
cat infrastructure/s-agendamento-key.pem
```

**Importante:** Copie TODO o conteúdo, incluindo as linhas:
- `-----BEGIN RSA PRIVATE KEY-----`
- Todo o conteúdo no meio
- `-----END RSA PRIVATE KEY-----`

### 2. Acessar o GitHub Secrets

1. Abra: https://github.com/fourmindsorg/s_agendamento/settings/secrets/actions
2. Clique em **"New repository secret"**

### 3. Adicionar o Secret

- **Nome:** `EC2_SSH_KEY`
- **Valor:** Cole TODO o conteúdo do arquivo `.pem` (incluindo início e fim)
- Clique em **"Add secret"**

### 4. Verificar Secrets Existentes

Você DEVE ter estes 3 secrets configurados:
- ✅ `AWS_ACCESS_KEY_ID` 
- ✅ `AWS_SECRET_ACCESS_KEY`
- ⚠️ `EC2_SSH_KEY` ← **VOCÊ PRECISA ADICIONAR ESTE!**

## 🚀 Após Configurar

Depois de adicionar o secret:
1. Vá em **Actions** → **Deploy to Production**
2. Clique em **"Re-run failed jobs"**
3. O deploy irá executar com sucesso

## 🔍 Verificar se a Chave está Correta

A chave deve ter EXATAMENTE esta estrutura:

```
-----BEGIN RSA PRIVATE KEY-----
[MUITA LINHAS AQUI]
-----END RSA PRIVATE KEY-----
```

**Importante:** 
- Não pode ter espaços extras
- Deve ter a linha de início
- Deve ter a linha de fim
- Deve ter todo o conteúdo do meio

## 🛠️ Comando Completo para Copiar a Chave

Se estiver usando o Windows/Git Bash, execute:

```bash
cat infrastructure/s-agendamento-key.pem
```

Depois:
1. Selecione TODO o texto no terminal
2. Copie (Ctrl+C)
3. Cole no GitHub Secret

## 📝 Alternativa: Verificar o Arquivo

Se o arquivo estiver truncado ou corrompido:

```bash
# Ver linhas do arquivo
wc -l infrastructure/s-agendamento-key.pem

# Deve mostrar: 27 (ou mais)

# Ver última linha
tail -1 infrastructure/s-agendamento-key.pem

# Deve mostrar: -----END RSA PRIVATE KEY-----
```

## ⚠️ Importante

- A chave SSH é SENSÍVEL!
- Não compartilhe publicamente
- Não faça commit da chave no repositório
- Use apenas como GitHub Secret

