# 🚀 Como Executar o Sistema de Agendamento

## 📋 Pré-requisitos
- Python 3.8+
- Virtual environment ativado
- Dependências instaladas: `pip install -r requirements.txt`

## 🔧 Desenvolvimento (Local)

### 1. Ativar ambiente virtual
```bash
# Windows
.venv\Scripts\activate

# Linux/Mac
source .venv/bin/activate
```

### 2. Executar servidor de desenvolvimento
```bash
py manage.py runserver
```

**Acesso:** http://127.0.0.1:8000

### 3. Configurações de desenvolvimento
- Usa `core.settings` (configuração padrão)
- `DEBUG = True`
- Banco SQLite
- WhiteNoise **não é obrigatório**

---

## 🌐 Produção

### Opção 1: Script Automático
```bash
py run_production.py
```

### Opção 2: Manual

#### 1. Configurar variáveis de ambiente
```bash
# Windows
set DJANGO_SETTINGS_MODULE=core.settings_production
set DEBUG=False
set SECRET_KEY=sua-chave-secreta-forte
set ALLOWED_HOSTS=seu-dominio.com,www.seu-dominio.com
set DB_NAME=agendamentos_db
set DB_USER=postgres
set DB_PASSWORD=senha
set DB_HOST=localhost
set DB_PORT=5432

# Linux/Mac
export DJANGO_SETTINGS_MODULE=core.settings_production
export DEBUG=False
export SECRET_KEY=sua-chave-secreta-forte
export ALLOWED_HOSTS=seu-dominio.com,www.seu-dominio.com
export DB_NAME=agendamentos_db
export DB_USER=postgres
export DB_PASSWORD=senha
export DB_HOST=localhost
export DB_PORT=5432
```

#### 2. Instalar dependências
```bash
pip install -r requirements.txt
```

#### 3. Executar migrações
```bash
py manage.py migrate
```

#### 4. Coletar arquivos estáticos
```bash
py manage.py collectstatic --noinput
```

#### 5. Executar servidor

**Com Gunicorn (recomendado):**
```bash
gunicorn core.wsgi:application --bind 0.0.0.0:8000 --workers 3
```

**Com Waitress (Windows):**
```bash
pip install waitress
waitress-serve --listen=0.0.0.0:8000 core.wsgi:application
```

**Com Django runserver (apenas para testes):**
```bash
py manage.py runserver 0.0.0.0:8000
```

---

## 🔍 Verificação

### Desenvolvimento
- ✅ Servidor inicia sem erros
- ✅ Acesso em http://127.0.0.1:8000
- ✅ WhiteNoise não é obrigatório

### Produção
- ✅ WhiteNoise instalado e configurado
- ✅ Arquivos estáticos coletados
- ✅ Banco de dados configurado
- ✅ Variáveis de ambiente definidas

---

## 🐛 Solução de Problemas

### Erro: "No module named 'whitenoise'"
**Desenvolvimento:** Normal, WhiteNoise é opcional
**Produção:** Execute `pip install -r requirements.txt`

### Erro: "WSGI application could not be loaded"
- Verifique se `DJANGO_SETTINGS_MODULE` está correto
- Para desenvolvimento: `core.settings`
- Para produção: `core.settings_production`

### Erro de banco de dados em produção
- Configure as variáveis `DB_*` corretamente
- Execute `py manage.py migrate`

---

## 📁 Estrutura de Configuração

```
core/
├── settings.py          # Desenvolvimento (padrão)
├── settings_production.py # Produção
└── wsgi.py              # WSGI (usa settings.py por padrão)

run_production.py        # Script para produção
requirements.txt         # Dependências
```

---

## 🎯 Resumo Rápido

**Desenvolvimento:**
```bash
py manage.py runserver
```

**Produção:**
```bash
py run_production.py
```
