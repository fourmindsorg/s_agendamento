# 🔧 Resolver: ASAAS_API_KEY não configurada em produção

## 🔍 Diagnóstico Completo

### Problema Identificado
O sistema detecta corretamente o ambiente como **"production"**, mas a `ASAAS_API_KEY` não está sendo encontrada.

### Causas Possíveis

1. **Arquivo .env não existe ou está em local errado**
   - Deve estar em `/opt/s-agendamento/.env`
   - Permissões incorretas

2. **load_dotenv() não está funcionando em produção**
   - O Gunicorn pode não estar no diretório correto
   - O caminho relativo pode não funcionar

3. **Variável não está sendo carregada pelo systemd**
   - O systemd não carrega .env automaticamente
   - Precisa ser explicitamente configurado

4. **Settings module não está carregando**
   - Se usar `core.settings_production`, pode não estar herdando corretamente

## ✅ Soluções Aplicadas

### 1. Melhorias no carregamento do .env

**Arquivo:** `core/settings.py` e `core/settings_production.py`
- ✅ Uso de caminho absoluto
- ✅ `override=True` para garantir que funcione
- ✅ Logs detalhados para diagnóstico
- ✅ Verificação se a chave foi carregada

### 2. Tentativa de recarregamento automático

**Arquivo:** `financeiro/services/asaas.py`
- ✅ Se a chave não for encontrada, tenta recarregar o .env
- ✅ Logs detalhados mostrando onde a chave está faltando
- ✅ Diagnóstico completo de todas as fontes

### 3. Comando de diagnóstico

**Arquivo:** `financeiro/management/commands/diagnosticar_asaas.py`
- ✅ Verifica arquivo .env
- ✅ Verifica variáveis de ambiente
- ✅ Verifica settings
- ✅ Testa inicialização do AsaasClient
- ✅ Mostra recomendações

## 🛠️ Passos para Resolver no Servidor

### Passo 1: Executar diagnóstico
```bash
cd /opt/s-agendamento
source venv/bin/activate
python manage.py diagnosticar_asaas
```

### Passo 2: Verificar se .env existe
```bash
ls -la /opt/s-agendamento/.env
cat /opt/s-agendamento/.env | grep ASAAS_API_KEY
```

### Passo 3: Se não existir, criar
```bash
# Copiar do exemplo (se existir)
cp .env.example .env

# OU criar manualmente
nano /opt/s-agendamento/.env
```

Adicionar:
```bash
ASAAS_API_KEY=$aact_SUA_CHAVE_PRODUCAO_AQUI
ASAAS_ENV=production
```

**IMPORTANTE:** Substitua `$aact_SUA_CHAVE_PRODUCAO_AQUI` pela chave real do Asaas produção.

### Passo 4: Verificar permissões
```bash
# O arquivo deve ser legível pelo usuário do Gunicorn
chmod 640 /opt/s-agendamento/.env
chown django:django /opt/s-agendamento/.env  # ou o usuário correto
```

### Passo 5: Verificar logs após reiniciar
```bash
# Reiniciar Gunicorn
sudo systemctl restart gunicorn

# Verificar logs
sudo journalctl -u gunicorn -n 50 | grep -i asaas
```

Os logs devem mostrar:
- `✅ [PRODUCTION] Arquivo .env carregado de: /opt/s-agendamento/.env`
- `✅ [PRODUCTION] ASAAS_API_KEY carregada com sucesso`

### Passo 6: Testar novamente
Tente gerar o QR Code novamente. Se ainda não funcionar, verifique os logs detalhados.

## 🔍 Logs Detalhados

Os logs agora mostram:
- ✅ Caminho do arquivo .env
- ✅ Se o arquivo existe
- ✅ Se a chave está em `os.environ`
- ✅ Se a chave está em `settings`
- ✅ BASE_DIR usado
- ✅ Tentativa de recarregamento automático

## 📝 Checklist de Verificação

- [ ] Arquivo `.env` existe em `/opt/s-agendamento/.env`
- [ ] `ASAAS_API_KEY` está definida no `.env`
- [ ] Permissões corretas (640, usuário django)
- [ ] Chave começa com `$aact_` ou `aact_`
- [ ] Comando `diagnosticar_asaas` mostra chave carregada
- [ ] Logs do Gunicorn mostram "ASAAS_API_KEY carregada"
- [ ] Gunicorn reiniciado após configurar

## 🚨 Se Ainda Não Funcionar

1. **Verificar logs detalhados:**
   ```bash
   sudo journalctl -u gunicorn -n 100 | grep -i "ASAAS_API_KEY"
   ```

2. **Testar manualmente:**
   ```bash
   python manage.py shell
   ```
   ```python
   import os
   from pathlib import Path
   from dotenv import load_dotenv
   
   BASE_DIR = Path("/opt/s-agendamento")
   env_path = BASE_DIR / '.env'
   print(f"Arquivo existe: {env_path.exists()}")
   
   if env_path.exists():
       load_dotenv(dotenv_path=str(env_path.absolute()), override=True)
       print(f"ASAAS_API_KEY: {'SIM' if os.environ.get('ASAAS_API_KEY') else 'NÃO'}")
   ```

3. **Verificar configuração do systemd:**
   ```bash
   cat /etc/systemd/system/gunicorn.service | grep -A 5 Environment
   ```

4. **Configurar via systemd (se necessário):**
   ```bash
   sudo systemctl edit gunicorn
   ```
   
   Adicionar:
   ```ini
   [Service]
   EnvironmentFile=/opt/s-agendamento/.env
   ```
   
   Depois:
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl restart gunicorn
   ```

## 📊 Status das Correções

- ✅ Carregamento do .env melhorado
- ✅ Logs detalhados adicionados
- ✅ Tentativa de recarregamento automático
- ✅ Comando de diagnóstico criado
- ✅ Verificação em múltiplas fontes

---

**Última atualização:** Correções aplicadas para melhorar diagnóstico e carregamento automático.

