# 🔧 Resolver: Git "Permission denied" no servidor

## ❌ Problema
```
error: cannot open .git/FETCH_HEAD: Permission denied
```

## 🔍 Diagnóstico

Primeiro, verifique as permissões:

```bash
# Verificar usuário atual
whoami

# Verificar propriedade do diretório .git
ls -la /opt/s-agendamento/.git | head -10

# Verificar propriedade do diretório raiz
ls -la /opt/s-agendamento | grep -E "^d"
```

## ✅ Solução 1: Ajustar propriedade (Recomendado)

Se o usuário atual é `ubuntu`, mas o diretório pertence a outro usuário:

```bash
# Ajustar propriedade para o usuário atual
sudo chown -R ubuntu:ubuntu /opt/s-agendamento

# Verificar se funcionou
git pull origin main
```

## ✅ Solução 2: Ajustar apenas permissões do .git

Se preferir manter a propriedade atual, apenas ajustar permissões:

```bash
# Dar permissão de escrita ao grupo ou outros
sudo chmod -R g+w /opt/s-agendamento/.git

# OU, se o usuário ubuntu não está no grupo, dar permissão completa temporariamente
sudo chmod -R 755 /opt/s-agendamento/.git
```

## ✅ Solução 3: Usar sudo (Temporário)

Se precisar atualizar rapidamente:

```bash
# Clonar novamente em um diretório temporário (se necessário)
sudo git pull origin main

# Depois ajustar propriedade
sudo chown -R ubuntu:ubuntu /opt/s-agendamento
```

## 🔍 Verificar após correção

```bash
# Verificar se o git funciona
git status

# Verificar permissões
ls -la /opt/s-agendamento/.git/FETCH_HEAD

# Tentar pull novamente
git pull origin main
```

## 📝 Configuração permanente

Para evitar problemas futuros, configure o usuário do Gunicorn corretamente:

```bash
# Verificar qual usuário roda o Gunicorn
ps aux | grep gunicorn

# Se o Gunicorn roda como outro usuário (ex: django), considere:
# 1. Mudar para o mesmo usuário do Git
# 2. OU criar um grupo comum e dar permissões adequadas
```

## ⚠️ Importante

- **Nunca** use `sudo` para commits/push regulares - apenas para correções de permissão
- Após ajustar propriedade, o Git deve funcionar normalmente
- Se o Gunicorn roda como outro usuário, pode precisar de configuração adicional

