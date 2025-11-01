# Changelog - Deploy Configuration

## Mudanças em Janeiro 2025

### Remoção de Instalação de Dependências Durante Deploy

**Motivo**: A instalação do `requirements.txt` durante o deploy não estava funcionando corretamente e as dependências já estão instaladas no venv do servidor.

**Arquivos Modificados**:

1. **`.github/workflows/deploy.yml`**
   - ✅ Comentada instalação de Python/pip (linhas 136-137 SSM, 244-245 SSH)
   - ✅ Comentada recriação do venv (linha 143)
   - ✅ Comentada instalação do requirements.txt (linha 145 SSM, linha 258 SSH)

2. **`.github/workflows/deploy-manual.yml`**
   - ✅ Comentada linha de instalação nas instruções manuais (linha 61)

3. **`infrastructure/deploy_completo.sh`**
   - ✅ Comentada instalação do requirements.txt (linha 24)
   - ✅ Atualizada mensagem de sucesso

**O que foi removido**:
```bash
# Estas linhas foram comentadas:
sudo apt-get install -y python3 python3-venv python3-pip
rm -rf venv && python3 -m venv venv
venv/bin/pip install --upgrade pip
venv/bin/pip install -r requirements.txt --upgrade --quiet
```

**O que permanece ativo**:
- ✅ Atualização do código (git fetch, git reset)
- ✅ Verificações Django (manage.py check)
- ✅ Migrações (manage.py migrate)
- ✅ Coleta de arquivos estáticos (collectstatic)
- ✅ Reinício de serviços (supervisorctl, nginx)

**Nota**: O arquivo `ci.yml` mantém a instalação do requirements.txt pois é usado apenas para testes no CI, não para deploy em produção.

