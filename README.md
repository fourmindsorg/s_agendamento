# Sistema de Agendamentos - 4Minds

Sistema completo para agendamento de clientes com interface moderna, responsiva e sistema de temas personalizáveis.

## Tecnologias

- **Backend:** Django 5.2.6
- **Frontend:** Bootstrap 5.3.0, HTML5, CSS3, JavaScript
- **Banco de Dados:** SQLite (desenvolvimento) / PostgreSQL (produção)
- **Gráficos:** Plotly.js
- **Ícones:** Font Awesome 6.4.0
- **Python:** 3.10+
- **Servidor:** Nginx + Gunicorn
- **Infraestrutura:** AWS (EC2, RDS, S3) - Apenas serviços gratuitos
- **Deploy:** GitHub Actions + Terraform

## Funcionalidades

### **Core Features**
- **Gestão Completa de Clientes** - Cadastro, edição, histórico
- **Sistema de Agendamentos** - Criar, editar, controlar status
- **Catálogo de Serviços** - Preços, duração, categorias
- **Dashboard Interativo** - KPIs, gráficos, visão geral
- **Relatórios e BI** - Análises detalhadas, métricas de crescimento
- **Sistema de Autenticação** - Login, registro, perfis

### **Interface e UX**
- **5 Temas Personalizáveis** - Azul Clássico, Verde Esmeralda, Pôr do Sol, Oceano, Roxo Elegante
- **Interface Responsiva** - Funciona em desktop, tablet e mobile
- **Central de Ajuda** - Tutoriais interativos, FAQ, guias completos
- **Demonstração Interativa** - Tour guiado pelas funcionalidades

### **Analytics e Controle**
- **Controle de Status** - Agendado, Confirmado, Em Andamento, Concluído, Cancelado
- **Validação de Conflitos** - Evita agendamentos sobrepostos
- **Filtros Avançados** - Por data, cliente, serviço, status
- **Gráficos Interativos** - Agendamentos por período, tendências

## Instalação e Configuração

### **Pré-requisitos**
- Python 3.8 ou superior
- Git
- Editor de código (VS Code recomendado)

### **1. Clonar o Repositório**
```bash
git clone https://github.com/fourmindsorg/s_agendamento.git
cd s_agendamento
```

## Deploy Automático na AWS

O sistema inclui uma pipeline completa de deploy automático usando GitHub Actions e Terraform.

### **Deploy Rápido (Recomendado)**

1. **Configure o AWS CLI:**
   ```powershell
   .\scripts\setup-aws-cli.ps1
   ```

2. **Gere as chaves SSH:**
   ```powershell
   .\scripts\generate-ssh-keys.ps1
   ```

3. **Configure os secrets no GitHub:**
   - Acesse: Settings → Secrets and variables → Actions
   - Adicione os secrets necessários (veja `scripts/setup-github-secrets.md`)

4. **Teste a configuração:**
   ```powershell
   .\scripts\test-deployment.ps1
   ```

5. **Faça deploy:**
   ```bash
   git add .
   git commit -m "Deploy to AWS"
   git push origin main
   ```

### **Pipeline de Deploy**

O sistema possui 3 pipelines automatizadas:

#### **Deploy Automático** (`deploy.yml`)
- **Trigger:** Push para `main` ou `master`
- **Função:** Deploy do código para EC2 existente
- **Tempo:** ~5 minutos

#### **Deploy com Terraform** (`terraform-deploy.yml`)
- **Trigger:** Push para `main` ou mudanças na infraestrutura
- **Função:** Cria/atualiza toda a infraestrutura AWS
- **Tempo:** ~10-15 minutos

#### **Atualização de IP** (`update-ip.yml`)
- **Trigger:** A cada 6 horas ou manual
- **Função:** Atualiza IPs dinâmicos da EC2
- **Tempo:** ~2 minutos

### **Infraestrutura AWS Criada**

- **EC2 Instance:** Ubuntu 22.04 (t2.micro)
- **RDS PostgreSQL:** Banco de dados gerenciado
- **S3 Bucket:** Arquivos estáticos
- **VPC:** Rede privada segura
- **Security Groups:** Firewall configurado
- **Logs:** Sistema de logging nativo do Django
- **SNS:** Notificações de alerta

### **URLs de Acesso**

Após o deploy, acesse:
- **Aplicação:** `https://fourmindstech.com.br`
- **Admin:** `https://fourmindstech.com.br/admin/`
- **Dashboard:** `https://fourmindstech.com.br/dashboard/`

**Credenciais Admin:**
- Usuário: `admin`
- Senha: `admin123` (altere após primeiro login)

### **Gerenciamento da Infraestrutura**

#### Deploy Manual via GitHub Actions
1. Acesse: Actions → Terraform Deploy to AWS
2. Clique em "Run workflow"
3. Escolha a ação: `plan`, `apply` ou `destroy`

#### Comandos Terraform Locais
```bash
cd infrastructure
terraform init
terraform plan
terraform apply
```

#### Acesso SSH à EC2
```bash
ssh -i ~/.ssh/id_rsa ubuntu@[IP_DA_EC2]
```

### **Monitoramento**

- **Logs:** Sistema de logging nativo do Django (console)
- **Métricas:** CPU, Memória, Disco
- **Alertas:** Email quando CPU > 80%
- **Health Check:** A cada 5 minutos

### **Backup Automático**

- **Banco de Dados:** Backup diário às 2h UTC
- **Arquivos:** Backup dos arquivos de mídia
- **Retenção:** 7 dias de backups

## Servidor em Produção

### **Status Atual**
- **URL:** https://fourmindstech.com.br
- **Status:** Online e Funcionando
- **Última Atualização:** Outubro 2025
- **Versão:** 2.0 (Produção)

### **Acesso Rápido**
- **Aplicação:** https://fourmindstech.com.br
- **Admin:** https://fourmindstech.com.br/admin/
- **Dashboard:** https://fourmindstech.com.br/dashboard/

### **Credenciais de Teste**
- **Usuário:** admin
- **Senha:** admin123
- ** IMPORTANTE:** Alterar após primeiro login

### **Infraestrutura**
- **Servidor:** AWS EC2 t2.micro (Ubuntu 22.04)
- **Banco:** RDS PostgreSQL 15.4
- **Domínio:** fourmindstech.com.br
- **SSL:** Ativo (Let's Encrypt)
- **Monitoramento:** Logs nativos do Django

### **Documentação da Infraestrutura**
Para informações detalhadas sobre a infraestrutura AWS, consulte:
- [INFRASTRUCTURE_README.md](./INFRASTRUCTURE_README.md) - Visão geral da infraestrutura
- [infrastructure/INFRASTRUCTURE_CONFIG.md](./infrastructure/INFRASTRUCTURE_CONFIG.md) - Configuração detalhada

---

## Desenvolvimento Local