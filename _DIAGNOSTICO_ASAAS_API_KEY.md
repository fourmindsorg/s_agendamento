# 🔍 Diagnóstico: ASAAS_API_KEY não configurada em produção

## 📋 Análise do Problema

### Situação Atual
- ✅ Ambiente detectado corretamente como **"production"**
- ❌ **ASAAS_API_KEY não está sendo encontrada**
- ❌ QR Code não é gerado

### Fluxo de Carregamento da Chave

1. **settings.py (linha 7-19)**: Tenta carregar `.env` usando `load_dotenv()`
2. **settings.py (linha 99)**: `ASAAS_API_KEY = os.environ.get("ASAAS_API_KEY")`
3. **AsaasClient.__init__ (linha 125-128)**: 
   ```python
   self.api_key = (
       os.environ.get("ASAAS_API_KEY") or
       getattr(settings, "ASAAS_API_KEY", None)
   )
   ```

## 🔎 Possíveis Causas

### 1. **Arquivo .env não existe ou não está no local correto**
- Em produção, o `.env` deve estar em `/opt/s-agendamento/.env`
- O Gunicorn roda de `/opt/s-agendamento`, então o `BASE_DIR / '.env'` deve funcionar

### 2. **load_dotenv() não está funcionando em produção**
- O `load_dotenv()` pode falhar silenciosamente
- Em produção, o working directory pode ser diferente

### 3. **Variável de ambiente não está sendo passada pelo systemd**
- O systemd pode não estar carregando o `.env`
- Variáveis de ambiente precisam ser explicitamente definidas no systemd

### 4. **Settings module não está carregando corretamente**
- Se estiver usando `core.settings_production`, pode não estar carregando o `.env`

## 🛠️ Solução Passo a Passo

### Passo 1: Verificar se o .env existe e está no lugar certo
```bash
# No servidor
cd /opt/s-agendamento
ls -la .env
cat .env | grep ASAAS_API_KEY
```

### Passo 2: Verificar se a chave está configurada
```bash
# Verificar conteúdo (sem mostrar a chave completa)
cat .env | grep -E "^ASAAS_API_KEY=" | head -c 30
# Deve mostrar algo como: ASAAS_API_KEY=$aact_...
```

### Passo 3: Verificar se o load_dotenv está funcionando
```bash
# Testar via shell do Django
python manage.py shell
```

```python
import os
from pathlib import Path
from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parent.parent
env_path = BASE_DIR / '.env'
print(f"BASE_DIR: {BASE_DIR}")
print(f"env_path: {env_path}")
print(f"env_path.exists(): {env_path.exists()}")

if env_path.exists():
    load_dotenv(dotenv_path=env_path)
    print(f"ASAAS_API_KEY após load_dotenv: {'SIM' if os.environ.get('ASAAS_API_KEY') else 'NÃO'}")
else:
    print("❌ Arquivo .env não encontrado!")
```

### Passo 4: Verificar variáveis de ambiente do Gunicorn
```bash
# Verificar processo do Gunicorn
ps aux | grep gunicorn

# Verificar variáveis de ambiente do processo
sudo cat /proc/$(pgrep -f gunicorn | head -1)/environ | tr '\0' '\n' | grep ASAAS
```

### Passo 5: Verificar configuração do systemd
```bash
# Verificar arquivo de serviço
cat /etc/systemd/system/s-agendamento.service | grep -A 5 Environment
```

## 🔧 Correções Necessárias

### Correção 1: Melhorar carregamento do .env em produção

O `load_dotenv()` pode falhar silenciosamente. Precisamos:
1. Garantir que o caminho absoluto seja usado
2. Adicionar logs para diagnóstico
3. Tentar múltiplos caminhos

### Correção 2: Adicionar variáveis de ambiente no systemd

O systemd precisa ter acesso às variáveis. Opções:
1. Carregar via `EnvironmentFile=/opt/s-agendamento/.env`
2. Definir explicitamente no arquivo de serviço
3. Usar `load_dotenv()` no código (já implementado, mas precisa melhorar)

### Correção 3: Adicionar fallback robusto

Se o `.env` não funcionar, tentar:
1. Carregar de variáveis de ambiente do sistema
2. Verificar se está definido no systemd
3. Logs detalhados para diagnóstico

## 📝 Próximos Passos

1. ✅ Criar versão melhorada do load_dotenv com logs
2. ✅ Adicionar diagnóstico automático
3. ✅ Criar script de verificação
4. ✅ Atualizar documentação de configuração

