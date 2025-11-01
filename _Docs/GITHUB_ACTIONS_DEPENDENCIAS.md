# 📦 Configuração de Dependências no GitHub Actions

Este documento descreve como as dependências do `requirements.txt` são instaladas durante o deploy no GitHub Actions.

## 🔄 Mudanças Implementadas

### ✅ Atualização dos Workflows

Os workflows do GitHub Actions foram atualizados para garantir que **todas as dependências** sejam sempre instaladas corretamente durante o deploy.

#### 1. **Workflow de Deploy (`.github/workflows/deploy.yml`)**

**Antes:**
```yaml
pip install -r requirements.txt --upgrade --quiet
```

**Depois:**
```yaml
python -m pip install --upgrade pip setuptools wheel
pip install --no-cache-dir --upgrade --force-reinstall -r requirements.txt
```

**Melhorias:**
- ✅ Atualiza `pip`, `setuptools` e `wheel` antes da instalação
- ✅ Usa `--no-cache-dir` para evitar problemas com cache
- ✅ Usa `--force-reinstall` para garantir instalação limpa
- ✅ Remove `--quiet` para melhor visibilidade do processo
- ✅ Adiciona verificação das dependências críticas após instalação

#### 2. **Workflow de CI (`.github/workflows/ci.yml`)**

**Antes:**
```yaml
python -m pip install --upgrade pip
pip install -r requirements.txt
```

**Depois:**
```yaml
python -m pip install --upgrade pip setuptools wheel
pip install --no-cache-dir --upgrade --force-reinstall -r requirements.txt
```

**Melhorias:**
- ✅ Instala ferramentas de build atualizadas
- ✅ Força reinstalação para garantir versões corretas
- ✅ Verifica dependências críticas após instalação

#### 3. **Workflow de Deploy Manual (`.github/workflows/deploy-manual.yml`)**

Também atualizado com as mesmas melhorias.

---

## 📋 Processo de Instalação Durante Deploy

### Passo a Passo

1. **Atualização das ferramentas:**
   ```bash
   python -m pip install --upgrade pip setuptools wheel
   ```
   - Garante que pip, setuptools e wheel estão nas versões mais recentes

2. **Instalação das dependências:**
   ```bash
   pip install --no-cache-dir --upgrade --force-reinstall -r requirements.txt
   ```
   - `--no-cache-dir`: Não usa cache, evita problemas com versões antigas
   - `--upgrade`: Atualiza pacotes já instalados
   - `--force-reinstall`: Reinstala todos os pacotes (garante instalação limpa)

3. **Verificação:**
   ```bash
   pip list | grep -E "(Django|qrcode|requests|python-dotenv|gunicorn|whitenoise)"
   ```
   - Verifica se dependências críticas foram instaladas corretamente

---

## 🔍 Dependências Críticas Verificadas

As seguintes dependências são verificadas após a instalação:

- `Django` - Framework web
- `qrcode` - Geração de QR Code PIX
- `requests` - Requisições HTTP (API Asaas)
- `python-dotenv` - Carregamento de variáveis de ambiente
- `gunicorn` - Servidor WSGI
- `whitenoise` - Servir arquivos estáticos

---

## 📝 Logs Durante Deploy

Durante o deploy, você verá:

```
📦 Instalando dependências do requirements.txt...
Instalando todas as dependências (isso pode levar alguns minutos)...
Verificando dependências críticas instaladas...
✓ Dependências instaladas e verificadas
```

---

## ⚠️ Solução de Problemas

### Problema: Dependência não instalada

**Sintomas:**
- Erro `ModuleNotFoundError` durante execução
- Dependência não aparece no `pip list`

**Solução:**
1. Verifique se está no `requirements.txt`
2. Execute manualmente no servidor:
   ```bash
   cd /opt/s-agendamento
   source venv/bin/activate
   pip install --no-cache-dir --force-reinstall <nome_da_dependencia>
   ```

### Problema: Versão incorreta instalada

**Sintomas:**
- Comportamento diferente do esperado
- Erros de compatibilidade

**Solução:**
1. Verifique a versão no `requirements.txt`
2. Force reinstalação:
   ```bash
   pip install --no-cache-dir --force-reinstall <pacote>==<versao>
   ```

### Problema: Cache causando problemas

**Sintomas:**
- Dependências antigas sendo usadas
- Instalação não atualiza pacotes

**Solução:**
O workflow já usa `--no-cache-dir` para evitar isso. Se necessário:
```bash
pip cache purge
pip install --no-cache-dir -r requirements.txt
```

---

## 🚀 Benefícios da Nova Configuração

1. **Instalação Limpa:** `--force-reinstall` garante que todas as dependências sejam reinstaladas
2. **Sem Cache:** `--no-cache-dir` evita problemas com versões antigas em cache
3. **Verificação:** Confirma que dependências críticas foram instaladas
4. **Visibilidade:** Logs claros do processo de instalação
5. **Confiabilidade:** Menos problemas de dependências desatualizadas ou faltando

---

## 📚 Referências

- [Documentação do pip](https://pip.pypa.io/en/stable/)
- [GitHub Actions - Python Setup](https://github.com/actions/setup-python)
- [Requirements.txt Format](https://pip.pypa.io/en/stable/reference/requirements-file-format/)

---

**Última atualização:** Janeiro 2025

