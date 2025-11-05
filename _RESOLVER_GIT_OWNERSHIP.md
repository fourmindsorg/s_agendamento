# 🔧 Resolver: Git "dubious ownership" no servidor

## ❌ Problema
```
fatal: detected dubious ownership in repository at '/opt/s-agendamento'
```

## ✅ Solução

Execute no servidor:

```bash
# Adicionar exceção de segurança para o diretório
git config --global --add safe.directory /opt/s-agendamento

# OU, se você quiser adicionar para o usuário atual apenas (sem --global)
git config --add safe.directory /opt/s-agendamento

# Depois, tentar novamente
git pull origin main
```

## 🔍 Verificar

```bash
# Verificar se foi adicionado
git config --global --get-regexp safe.directory

# Deve mostrar: safe.directory /opt/s-agendamento
```

## 📝 Alternativa: Corrigir propriedade

Se preferir corrigir a propriedade do diretório:

```bash
# Verificar usuário atual
whoami

# Verificar propriedade do diretório
ls -la /opt/s-agendamento | head -5

# Se necessário, ajustar propriedade (substitua 'django' pelo usuário correto)
sudo chown -R django:django /opt/s-agendamento

# Depois, verificar novamente
git pull origin main
```

## ⚠️ Importante

- Se você usar `--global`, a exceção será aplicada para todos os repositórios Git deste usuário
- Se não usar `--global`, a exceção será apenas para este repositório
- A opção mais segura é usar `--global` apenas se você confiar no diretório

