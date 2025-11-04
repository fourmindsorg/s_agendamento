# 🚨 URGENTE: Resolver Erro 500

## ⚠️ Passo 1: Verificar se wsgi.py foi realmente alterado

```bash
# Verificar conteúdo atual do arquivo
cat core/wsgi.py | grep DJANGO_SETTINGS_MODULE

# Deve mostrar:
# os.environ.setdefault("DJANGO_SETTINGS_MODULE", "core.settings")

# Se ainda mostrar "core.settings_production", o arquivo não foi salvo!
```

## ⚠️ Passo 2: Se ainda mostrar settings_production, ALTERAR AGORA

```bash
# Editar arquivo
nano core/wsgi.py

# Encontrar linha 15-16 e alterar para:
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "core.settings")

# Salvar: Ctrl+O, Enter, Ctrl+X
```

## ⚠️ Passo 3: Forçar Restart Completo do Gunicorn

```bash
# Parar completamente o gunicorn
sudo systemctl stop gunicorn
# OU
sudo systemctl stop s-agendamento

# Matar qualquer processo restante
sudo pkill -f gunicorn

# Aguardar 3 segundos
sleep 3

# Reiniciar
sudo systemctl start gunicorn
# OU
sudo systemctl start s-agendamento

# Verificar status
sudo systemctl status gunicorn
```

## ⚠️ Passo 4: Ver Logs para Identificar Erro Real

```bash
# Ver logs do gunicorn (IMPORTANTE - mostra o erro real)
sudo journalctl -u gunicorn -n 100 --no-pager | tail -50

# OU
sudo journalctl -u s-agendamento -n 100 --no-pager | tail -50
```

**Copie e cole a saída dos logs aqui!** Isso vai mostrar o erro exato.

## ⚠️ Passo 5: Verificar se Gunicorn Está Rodando

```bash
# Ver processos
ps aux | grep gunicorn

# Se não mostrar nada, o gunicorn não está rodando!
# Tentar iniciar manualmente:
cd ~/s_agendamento
source .venv/bin/activate
gunicorn core.wsgi:application --bind 0.0.0.0:8000

# Se der erro aqui, o problema está no código Django
```

## 🔍 Possíveis Causas do Erro 500

1. **Erro de Importação** - Algum módulo não encontrado
2. **Erro de Database** - Conexão com banco falhando
3. **Erro de SECRET_KEY** - Chave não configurada
4. **Erro de MIDDLEWARE** - Algum middleware causando problema
5. **Erro de Static Files** - Problema com arquivos estáticos

## 🚨 Solução de Emergência: Voltar para Commit Anterior

Se nada funcionar, volte para antes da mudança:

```bash
# Ver último commit
git log --oneline -5

# Voltar para commit antes de mudar wsgi.py
git checkout 56bfc9b^ core/wsgi.py

# OU restaurar do git
git checkout HEAD -- core/wsgi.py

# Reiniciar
sudo systemctl restart gunicorn
```

## 📋 Checklist Rápido

- [ ] wsgi.py mostra "core.settings" (não settings_production)
- [ ] Gunicorn foi parado completamente
- [ ] Gunicorn foi reiniciado
- [ ] Logs verificados (qual é o erro específico?)
- [ ] Gunicorn está rodando (ps aux | grep gunicorn)

---

**IMPORTANTE:** Execute o comando dos logs e envie a saída para identificar o erro exato!

