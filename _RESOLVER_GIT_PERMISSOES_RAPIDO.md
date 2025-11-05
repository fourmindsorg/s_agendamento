# 🔧 Resolver: Git Permission Denied - Solução Rápida

## ❌ Problema
```
error: cannot open .git/FETCH_HEAD: Permission denied
```

Mesmo após `git config --global --add safe.directory`, o erro persiste.

## ✅ Solução Imediata

Execute no servidor (como usuário `ubuntu`):

```bash
# Ajustar propriedade de TODO o diretório do projeto
sudo chown -R ubuntu:ubuntu /opt/s-agendamento

# Verificar se funcionou
git pull origin main
```

## 🔍 Por que isso acontece?

O diretório `/opt/s-agendamento` ou o `.git` dentro dele pertence a outro usuário (provavelmente `root` ou foi criado durante deploy). O Git precisa de permissão de escrita no diretório `.git` para funcionar.

## 📝 Alternativa: Apenas .git

Se preferir ajustar apenas o `.git`:

```bash
# Ajustar apenas o diretório .git
sudo chown -R ubuntu:ubuntu /opt/s-agendamento/.git

# Verificar
git pull origin main
```

## ⚠️ Importante

Depois de ajustar as permissões, o Git deve funcionar normalmente. Se você usar `sudo` para fazer pull depois, pode criar problemas novamente. Sempre use o usuário `ubuntu` para operações Git.

## ✅ Verificação

```bash
# Verificar propriedade atual
ls -la /opt/s-agendamento | head -5
ls -la /opt/s-agendamento/.git | head -5

# Deve mostrar: ubuntu ubuntu (ou o usuário correto)
```

## 🔄 Sequência Completa

```bash
# 1. Ajustar propriedade
sudo chown -R ubuntu:ubuntu /opt/s-agendamento

# 2. Configurar safe.directory (se ainda não fez)
git config --global --add safe.directory /opt/s-agendamento

# 3. Atualizar código
git pull origin main

# 4. Continuar com configuração do .env
sudo bash criar_env_producao.sh
```

