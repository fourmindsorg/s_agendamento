# 🔧 Troubleshoot: Problema com Chave SSH

## ❌ Erro Atual

```
ec2-user@52.91.139.151: Permission denied (publickey).
Error: Process completed with exit code 255.
```

## ✅ Soluções

### 1. Corrigir o Usuário SSH

O servidor é **Ubuntu 22.04**, então deve usar **`ubuntu`**, não `ec2-user`:

**Antes (ERRADO):**
```bash
ssh -i chave.pem ec2-user@52.91.139.151
```

**Depois (CORRETO):**
```bash
ssh -i chave.pem ubuntu@52.91.139.151
```

### 2. Verificar a Formatação da Chave SSH

A chave SSH deve ter EXATAMENTE este formato:

```
-----BEGIN RSA PRIVATE KEY-----
[CONTEÚDO COMPLETO AQUI]
-----END RSA PRIVATE KEY-----
```

**Importante:**
- ✅ Deve começar com `-----BEGIN RSA PRIVATE KEY-----`
- ✅ Deve terminar com `-----END RSA PRIVATE KEY-----`
- ✅ Não deve ter espaços extras no início ou fim
- ✅ Cada linha deve ter exatamente 64 caracteres (exceto a última)

### 3. Verificar o Secret no GitHub

1. Acesse: https://github.com/fourmindsorg/s_agendamento/settings/secrets/actions
2. Procure por `EC2_SSH_KEY`
3. Abra e verifique se:
   - ✅ Começa com `-----BEGIN RSA PRIVATE KEY-----`
   - ✅ Termina com `-----END RSA PRIVATE KEY-----`
   - ✅ Não tem espaços extras

### 4. Como Obter a Chave Correta

Execute localmente:

```bash
# Ver o conteúdo da chave
cat infrastructure/s-agendamento-key.pem

# Deve mostrar algo como:
-----BEGIN RSA PRIVATE KEY-----
MIIEpQIBAAKCAQEAy+2uxNgQBluOteN2i2P1rhDo82XuGbMtpp+UdC8/WtRsdxGj
... (mais linhas) ...
+YxJddD6fM7UaQ9iRrcpv9SKlt5/zrgwuIPezuA+IF86GgL1DgN8ppE=
-----END RSA PRIVATE KEY-----
```

### 5. Atualizar o Secret no GitHub

1. Copie TODO o conteúdo da chave:
```bash
cat infrastructure/s-agendamento-key.pem
```

2. Vá em: https://github.com/fourmindsorg/s_agendamento/settings/secrets/actions
3. Clique em `EC2_SSH_KEY`
4. Selecione "Update"
5. Cole o conteúdo COMPLETO (incluindo início e fim)
6. Clique em "Update secret"

### 6. Testar Localmente

Teste se a chave funciona localmente:

```bash
# Com usuário ec2-user (para AMI antiga)
ssh -i infrastructure/s-agendamento-key.pem ec2-user@52.91.139.151

# Com usuário ubuntu (para Ubuntu 22.04)
ssh -i infrastructure/s-agendamento-key.pem ubuntu@52.91.139.151
```

Se um funcionar e o outro não, você sabe qual usuário usar.

### 7. Verificar Permissões da Chave

```bash
# Verificar permissões (deve ser 400 ou 600)
ls -la infrastructure/s-agendamento-key.pem

# Corrigir permissões se necessário
chmod 600 infrastructure/s-agendamento-key.pem
```

### 8. Diagnosticar o Servidor

Para descobrir qual usuário usar, conecte via AWS Console:

1. Acesse: https://console.aws.amazon.com/ec2/
2. Selecione a instância: i-0077873407e4114b1
3. Clique em "Connect" → "EC2 Instance Connect"
4. Execute:
```bash
cat /etc/passwd | grep -E "ubuntu|ec2-user|admin"
whoami
```

Isso mostrará qual usuário existe no servidor.

### 9. Alternativa: Criar Nova Chave

Se a chave estiver corrompida:

```bash
# Gerar nova chave
ssh-keygen -t rsa -b 4096 -f nova-chave -N ""

# Adicionar chave pública ao servidor
ssh-copy-id -i nova-chave.pub ubuntu@52.91.139.151

# Ou se for ec2-user
ssh-copy-id -i nova-chave.pub ec2-user@52.91.139.151
```

### 10. Verificar Logs do GitHub Actions

Acesse: https://github.com/fourmindsorg/s_agendamento/actions

Veja os logs do step "Setup SSH" para erros específicos.

## 🎯 Checklist de Verificação

- [ ] Secret `EC2_SSH_KEY` está configurado no GitHub
- [ ] Chave começa com `-----BEGIN RSA PRIVATE KEY-----`
- [ ] Chave termina com `-----END RSA PRIVATE KEY-----`
- [ ] Usuário correto no workflow (ubuntu para Ubuntu, ec2-user para Amazon Linux)
- [ ] Chave tem permissões corretas (600)
- [ ] Porta 22 está aberta no Security Group da EC2
- [ ] IP público da instância é o correto

## 📝 Resumo

**Problema:** Permission denied (publickey)

**Causas possíveis:**
1. ❌ Usuário incorreto (ec2-user vs ubuntu)
2. ❌ Chave SSH incompleta ou mal formatada
3. ❌ Secret não configurado corretamente
4. ❌ Chave pública não está no servidor

**Solução:**
1. ✅ Usar usuário `ubuntu` para Ubuntu 22.04
2. ✅ Verificar formato completo da chave
3. ✅ Atualizar secret no GitHub
4. ✅ Testar localmente primeiro

