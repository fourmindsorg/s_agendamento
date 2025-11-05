# 🔧 Resolver: Permission denied no arquivo .env

## ❌ Problema
```
PermissionError: [Errno 13] Permission denied: '/opt/s-agendamento/.env'
```

O arquivo `.env` existe, mas o usuário atual não tem permissão para lê-lo.

## 🔍 Diagnóstico

Verifique propriedade e permissões:

```bash
# Ver propriedade e permissões do arquivo
ls -la /opt/s-agendamento/.env

# Ver usuário atual
whoami

# Ver usuário do Gunicorn
ps aux | grep gunicorn | grep -v grep
```

## ✅ Solução 1: Ajustar propriedade (Recomendado)

Se o arquivo pertence a `root` ou outro usuário:

```bash
# Ajustar propriedade para o usuário ubuntu
sudo chown ubuntu:ubuntu /opt/s-agendamento/.env

# Verificar
ls -la /opt/s-agendamento/.env
# Deve mostrar: -rw-r----- 1 ubuntu ubuntu
```

## ✅ Solução 2: Ajustar permissões

Se preferir manter a propriedade atual, mas dar permissão de leitura:

```bash
# Dar permissão de leitura para o grupo (se ubuntu estiver no grupo)
sudo chmod 644 /opt/s-agendamento/.env

# OU dar permissão de leitura para todos (menos seguro, mas funciona)
sudo chmod 644 /opt/s-agendamento/.env
```

## ✅ Solução 3: Ajustar para usuário do Gunicorn

Se o Gunicorn roda como outro usuário (ex: `django`):

```bash
# Verificar usuário do Gunicorn
ps aux | grep gunicorn | grep -v grep | awk '{print $1}'

# Ajustar propriedade para o usuário do Gunicorn
sudo chown django:django /opt/s-agendamento/.env

# Dar permissão de leitura para o grupo (se ubuntu estiver no grupo django)
sudo chmod 640 /opt/s-agendamento/.env
sudo chgrp django /opt/s-agendamento/.env

# Adicionar ubuntu ao grupo django (se necessário)
sudo usermod -a -G django ubuntu
```

## 🔒 Permissões Ideais

Para segurança, mantenha:
- **Propriedade**: usuário do Gunicorn (ou `ubuntu` se for o mesmo)
- **Permissões**: `640` (leitura/escrita para owner, leitura para group, nada para others)

```bash
sudo chown USUARIO_DO_GUNICORN:USUARIO_DO_GUNICORN /opt/s-agendamento/.env
sudo chmod 640 /opt/s-agendamento/.env
```

## 📝 Verificação

```bash
# Verificar propriedade
ls -la /opt/s-agendamento/.env

# Testar leitura
cat /opt/s-agendamento/.env | head -5

# Testar diagnóstico
python manage.py diagnosticar_asaas
```

## ⚠️ Importante

- O arquivo `.env` contém informações sensíveis (chaves de API, senhas)
- Nunca use permissões `666` ou `777` (acesso público)
- Mantenha `640` ou `600` (acesso restrito)
- Se o usuário do Gunicorn for diferente de `ubuntu`, ajuste a propriedade para o usuário do Gunicorn

## 🔄 Sequência Completa

```bash
# 1. Verificar propriedade atual
ls -la /opt/s-agendamento/.env

# 2. Ajustar propriedade (escolha uma opção acima)
sudo chown ubuntu:ubuntu /opt/s-agendamento/.env
# OU
sudo chown django:django /opt/s-agendamento/.env

# 3. Ajustar permissões
sudo chmod 640 /opt/s-agendamento/.env

# 4. Verificar
ls -la /opt/s-agendamento/.env

# 5. Testar
python manage.py diagnosticar_asaas
```

