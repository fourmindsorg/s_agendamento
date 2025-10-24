# 🚀 Scripts de Deploy - Sistema de Agendamento 4Minds

Este diretório contém scripts automatizados para deploy completo do Sistema de Agendamento 4Minds na AWS.

## 📋 Scripts Disponíveis

### 1. **deploy_all.py** - Script Principal (Recomendado)
Script orquestrador que executa todo o processo de deploy automaticamente.

```bash
python deploy_all.py
```

**O que faz:**
- ✅ Verifica pré-requisitos
- ✅ Cria/aplica infraestrutura AWS
- ✅ Coleta informações da infraestrutura
- ✅ Atualiza configurações do sistema
- ✅ Realiza deploy do Django na EC2

### 2. **collect_infrastructure_info.py** - Coletor de Informações
Coleta informações da infraestrutura AWS e atualiza configurações.

```bash
python collect_infrastructure_info.py
```

**O que faz:**
- ✅ Coleta outputs do Terraform
- ✅ Atualiza arquivo `.env`
- ✅ Atualiza `settings_production.py`
- ✅ Salva informações em JSON

### 3. **deploy_django.py** - Deploy do Django
Realiza deploy da aplicação Django na instância EC2.

```bash
python deploy_django.py
```

**O que faz:**
- ✅ Verifica status da instância
- ✅ Prepara pacote de deploy
- ✅ Copia arquivos para EC2
- ✅ Executa script de inicialização
- ✅ Testa deployment

### 4. **deploy_complete.sh** - Script Bash (Linux/Mac)
Script completo em Bash para sistemas Unix.

```bash
chmod +x deploy_complete.sh
./deploy_complete.sh
```

### 5. **deploy_complete.ps1** - Script PowerShell (Windows)
Script completo em PowerShell para Windows.

```powershell
.\deploy_complete.ps1
```

## 🔧 Pré-requisitos

### Obrigatórios
- **Python 3.8+**
- **Terraform** (instalado e configurado)
- **AWS CLI** (configurado com credenciais)
- **SSH** (para conectar na EC2)

### Opcionais
- **requests** (para testes de conectividade)
- **Chave SSH** (`s-agendamento-key.pem`)

## 📦 Instalação de Dependências

```bash
# Instalar dependências Python
pip install requests python-dotenv

# Ou usar requirements.txt
pip install -r ../requirements.txt
```

## 🚀 Uso Rápido

### Opção 1: Deploy Automático (Recomendado)
```bash
cd infrastructure
python deploy_all.py
```

### Opção 2: Deploy Manual
```bash
cd infrastructure

# 1. Criar infraestrutura
terraform init
terraform apply -auto-approve

# 2. Coletar informações
python collect_infrastructure_info.py

# 3. Deploy do Django
python deploy_django.py
```

## 📊 Informações Coletadas

Os scripts coletam e utilizam as seguintes informações:

- **Instance ID**: ID da instância EC2
- **IP Público**: IP público da instância
- **DNS Público**: DNS público da instância
- **RDS Endpoint**: Endpoint do banco PostgreSQL
- **S3 Buckets**: Buckets para arquivos estáticos e mídia
- **VPC ID**: ID da VPC

## ⚙️ Configurações Atualizadas

### Arquivo `.env`
```env
DEBUG=False
SECRET_KEY=django-insecure-4minds-agendamento-2025-super-secret-key
ALLOWED_HOSTS=IP_PUBLICO,DNS_PUBLICO,fourmindstech.com.br,...
DB_HOST=RDS_ENDPOINT
AWS_STORAGE_BUCKET_NAME_STATIC=BUCKET_STATIC
AWS_STORAGE_BUCKET_NAME_MEDIA=BUCKET_MEDIA
```

### Arquivo `settings_production.py`
- Configurações de produção
- Banco PostgreSQL
- Segurança
- Logging
- Cache

## 🌐 URLs de Acesso

Após o deploy, o sistema estará disponível em:

- **Website**: `http://IP_PUBLICO`
- **Admin**: `http://IP_PUBLICO/admin/`
- **API**: `http://IP_PUBLICO/api/`

### Credenciais Padrão
- **Usuário**: `admin`
- **Senha**: `admin123`

## 🔧 Comandos Úteis

### SSH para a Instância
```bash
ssh -i s-agendamento-key.pem ubuntu@IP_PUBLICO
```

### Gerenciar Aplicação
```bash
# Ver status
sudo supervisorctl status s-agendamento

# Ver logs
sudo supervisorctl tail -f s-agendamento

# Reiniciar
sudo supervisorctl restart s-agendamento

# Parar
sudo supervisorctl stop s-agendamento
```

### Gerenciar Nginx
```bash
# Testar configuração
sudo nginx -t

# Reiniciar
sudo systemctl restart nginx

# Ver status
sudo systemctl status nginx
```

## 🐛 Solução de Problemas

### Erro: "Chave SSH não encontrada"
```bash
# Coloque a chave SSH no diretório infrastructure/
cp /caminho/para/sua/chave.pem infrastructure/s-agendamento-key.pem
chmod 600 infrastructure/s-agendamento-key.pem
```

### Erro: "AWS CLI não configurado"
```bash
aws configure
# Digite suas credenciais AWS
```

### Erro: "Terraform não encontrado"
- Instale o Terraform: https://www.terraform.io/downloads
- Adicione ao PATH

### Erro: "Instância não está rodando"
```bash
# Verificar status
aws ec2 describe-instances --instance-ids INSTANCE_ID

# Iniciar se necessário
aws ec2 start-instances --instance-ids INSTANCE_ID
```

### Aplicação não responde
```bash
# Verificar logs
sudo supervisorctl tail -f s-agendamento

# Verificar se está rodando
sudo supervisorctl status s-agendamento

# Reiniciar se necessário
sudo supervisorctl restart s-agendamento
```

## 📝 Logs e Monitoramento

### Logs da Aplicação
```bash
sudo tail -f /var/log/supervisor/s-agendamento.log
```

### Logs do Nginx
```bash
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

### Logs do Sistema
```bash
sudo journalctl -u nginx
sudo journalctl -u supervisor
```

## 🔄 Atualizações

Para atualizar a aplicação:

1. Faça as alterações no código
2. Execute o deploy novamente:
```bash
python deploy_django.py
```

## 🗑️ Limpeza

Para remover a infraestrutura:

```bash
terraform destroy -auto-approve
```

## 📞 Suporte

Em caso de problemas:

1. Verifique os logs
2. Consulte este README
3. Verifique os pré-requisitos
4. Execute os scripts em ordem

---

**✅ Sistema de Agendamento 4Minds - Deploy Automatizado**
