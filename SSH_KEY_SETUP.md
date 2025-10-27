# 🔑 Como Configurar a Chave SSH para GitHub Actions

## ❌ Erro Atual
```
Permission denied (publickey)
```

## ✅ Solução: Adicionar Chave SSH ao GitHub Secrets

### Opção 1: Usar SSM (Mais Fácil - Recomendado)

O workflow agora tentará **SSM primeiro** e só usará SSH se SSM falhar. SSM não requer chave SSH!

Para isso, apenas certifique-se de que o SSM Agent está rodando no EC2:

```bash
# No servidor EC2
sudo systemctl status amazon-ssm-agent
```

Se não estiver rodando:
```bash
sudo systemctl start amazon-ssm-agent
sudo systemctl enable amazon-ssm-agent
```

### Opção 2: Configurar Chave SSH (Se necessário)

Se quiser configurar SSH como fallback:

#### Passo 1: Gerar Chave SSH (se não tiver)

```bash
# No seu computador
ssh-keygen -t rsa -b 4096 -C "github-actions-deploy"
# Pressione Enter para aceitar o local padrão: ~/.ssh/id_rsa
# Deixe a senha vazia (pressione Enter duas vezes)
```

#### Passo 2: Obter o Conteúdo da Chave Privada

```bash
# No seu computador
cat ~/.ssh/id_rsa
```

Copie todo o conteúdo (desde `-----BEGIN OPENSSH PRIVATE KEY-----` até `-----END OPENSSH PRIVATE KEY-----`)

#### Passo 3: Adicionar ao GitHub Secrets

1. Acesse: https://github.com/fourmindsorg/s_agendamento/settings/secrets/actions
2. Clique em **"New repository secret"**
3. Nome: `EC2_SSH_KEY`
4. Secret: Cole o conteúdo completo da chave privada
5. Clique em **"Add secret"**

#### Passo 4: Adicionar Chave Pública ao Servidor

Conecte ao servidor via SSM:
```bash
aws ssm start-session --target i-0077873407e4114b1
```

No servidor, execute:
```bash
# Criar diretório .ssh se não existir
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Adicionar chave pública (cole sua chave pública aqui)
echo "ssh-rsa AAAA..." >> ~/.ssh/authorized_keys

# Ajustar permissões
chmod 600 ~/.ssh/authorized_keys
```

Para obter sua chave pública:
```bash
# No seu computador
cat ~/.ssh/id_rsa.pub
```

### Opção 3: Usar chave existente

Se você já tem uma chave SSH (.pem), pode usá-la:

```bash
# No seu computador
cat infrastructure/s-agendamento-key.pem
```

Depois siga o **Passo 3** e **Passo 4** acima, mas use o conteúdo do arquivo .pem no lugar da chave RSA.

## 🎯 Recomendação

**Use SSM!** É mais seguro e não requer configuração de chaves SSH:
1. Ative o SSM Agent no servidor (já deve estar ativo)
2. O workflow usará SSM automaticamente
3. Se SSM falhar, aí sim tentará SSH

## 🔍 Verificar SSM Agent

Execute no servidor EC2:
```bash
sudo systemctl status amazon-ssm-agent
```

Se estiver inativo:
```bash
sudo systemctl start amazon-ssm-agent
sudo systemctl enable amazon-ssm-agent
```

## ✅ Testar Conectividade

Após configurar, teste a conexão SSH (opcional):
```bash
ssh -i ~/.ssh/id_rsa ubuntu@52.91.139.151
```

Ou teste SSM:
```bash
aws ssm start-session --target i-0077873407e4114b1
```

## 📋 Resumo

Para este erro específico, você tem 3 opções:

1. **Usar SSM (Mais fácil)** - Certifique-se de que SSM Agent está rodando
2. **Configurar chave SSH** - Seguir opções 2 ou 3 acima
3. **Deploy manual** - Conectar manualmente ao servidor e executar

O workflow já foi atualizado para tentar SSM primeiro, então normalmente funcionará sem precisar configurar SSH.

