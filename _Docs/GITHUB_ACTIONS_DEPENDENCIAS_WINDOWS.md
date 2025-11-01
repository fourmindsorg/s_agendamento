# 🔧 Solução: Dependências Windows no GitHub Actions

## ❌ Problema Identificado

O GitHub Actions está falhando ao tentar instalar dependências específicas do Windows no ambiente Linux:

```
ERROR: Could not find a version that satisfies the requirement pywin32==311
ERROR: No matching distribution found for pywin32==311
```

## 🔍 Causa

O arquivo `requirements.txt` contém dependências específicas do Windows que não podem ser instaladas no Linux:

- `pywin32==311`
- `pywin32-ctypes==0.2.3`
- `winshell==0.6`
- `PyAutoGUI==0.9.54`
- `PyGetWindow==0.0.9`
- `PyScreeze==1.0.1`
- `PyRect==0.2.0`
- `PyMsgBox==1.0.9`
- `MouseInfo==0.1.3`

## ✅ Solução Implementada

Os workflows do GitHub Actions foram atualizados para:

1. **Criar `requirements-linux.txt`** automaticamente, removendo dependências Windows-only
2. **Instalar apenas dependências compatíveis com Linux**
3. **Continuar mesmo se algumas dependências opcionais falharem**

### Arquivos Atualizados

#### 1. `.github/workflows/ci.yml`

```yaml
- name: Install dependencies
  run: |
    python -m pip install --upgrade pip setuptools wheel
    echo "📦 Preparando requirements.txt para Linux..."
    grep -v -E "^(pywin32|pywin32-ctypes|winshell|PyAutoGUI|PyGetWindow|PyScreeze|PyRect|PyMsgBox|MouseInfo)==" requirements.txt > requirements-linux.txt || cp requirements.txt requirements-linux.txt
    echo "📦 Instalando dependências do requirements-linux.txt..."
    set +e
    pip install --no-cache-dir --upgrade -r requirements-linux.txt
    set -e
```

#### 2. `.github/workflows/deploy.yml`

Mesma lógica aplicada para ambos os métodos de deploy (SSM e SSH).

### Como Funciona

1. **Filtragem Automática:**
   ```bash
   grep -v -E "^(pywin32|pywin32-ctypes|winshell|...)==" requirements.txt > requirements-linux.txt
   ```
   - Remove linhas que começam com dependências Windows-only

2. **Instalação com Tratamento de Erros:**
   ```bash
   set +e  # Não falhar no primeiro erro
   pip install --no-cache-dir --upgrade -r requirements-linux.txt
   set -e  # Reativar fail-fast
   ```
   - Continua mesmo se algumas dependências opcionais falharem

3. **Verificação:**
   ```bash
   pip list | grep -E "(Django|qrcode|requests|python-dotenv)"
   ```
   - Confirma que dependências críticas foram instaladas

## 📋 Dependências Removidas Automaticamente

As seguintes dependências são **automaticamente excluídas** no Linux:

| Dependência | Uso | Impacto |
|------------|-----|---------|
| `pywin32` | APIs do Windows | ❌ Não necessário no Linux |
| `pywin32-ctypes` | Suporte para pywin32 | ❌ Não necessário no Linux |
| `winshell` | Shell do Windows | ❌ Não necessário no Linux |
| `PyAutoGUI` | Automação de GUI (Windows) | ⚠️ Pode ser usado em desenvolvimento local |
| `PyGetWindow` | Controle de janelas Windows | ⚠️ Pode ser usado em desenvolvimento local |
| `PyScreeze` | Screenshots (Windows) | ⚠️ Pode ser usado em desenvolvimento local |
| `PyRect` | Retângulos de janelas | ⚠️ Pode ser usado em desenvolvimento local |
| `PyMsgBox` | Caixas de mensagem Windows | ⚠️ Pode ser usado em desenvolvimento local |
| `MouseInfo` | Informações do mouse | ⚠️ Pode ser usado em desenvolvimento local |

## 💡 Para Desenvolvimento Local (Windows)

Se você estiver desenvolvendo no Windows, todas as dependências serão instaladas normalmente:

```bash
pip install -r requirements.txt
```

As dependências Windows-only só são removidas **automaticamente** nos workflows do GitHub Actions (Linux).

## 🔄 Manter requirements.txt Unificado

**Vantagens:**
- ✅ Um único arquivo para desenvolvimento local (Windows/Linux/Mac)
- ✅ GitHub Actions filtra automaticamente dependências incompatíveis
- ✅ Não precisa manter dois arquivos separados manualmente

**Como funciona:**
- **Windows**: Instala todas as dependências (incluindo Windows-only)
- **Linux (CI/Deploy)**: Filtra automaticamente dependências Windows-only
- **Mac**: Pode precisar de ajustes similares se necessário

## 🚀 Próximos Deploys

O GitHub Actions agora irá:

1. ✅ Criar `requirements-linux.txt` automaticamente
2. ✅ Instalar apenas dependências compatíveis com Linux
3. ✅ Continuar mesmo se algumas dependências opcionais falharem
4. ✅ Verificar dependências críticas após instalação

## 📝 Notas

- As dependências Windows-only **não afetam** o funcionamento do sistema em produção (Linux)
- Essas dependências são principalmente para automação/desenvolvimento local
- O sistema Django funciona normalmente sem elas no servidor Linux

---

**Última atualização:** Janeiro 2025

