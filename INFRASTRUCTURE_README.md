# 🏗️ Infraestrutura AWS - Sistema de Agendamento 4Minds

## 📁 Organização da Infraestrutura

Todos os arquivos relacionados à infraestrutura AWS foram organizados na pasta `infrastructure/` para melhor organização e manutenção.

## 🚀 Status da Infraestrutura

✅ **Infraestrutura AWS criada e funcionando!**

### 🖥️ Instância EC2
- **Instance ID**: `i-0f63bd23ef4437f68`
- **Status**: `running`
- **IP Público**: `44.205.204.166` (Elastic IP)
- **Tipo**: `t2.micro` com Django

### 🌐 DNS Configurado
- `fourmindstech.com.br` → `44.205.204.166`
- `www.fourmindstech.com.br` → `44.205.204.166`
- `api.fourmindstech.com.br` → `44.205.204.166`
- `admin.fourmindstech.com.br` → `44.205.204.166`

### 🗄️ Banco de Dados RDS
- **PostgreSQL** rodando e disponível
- **Endpoint**: `s-agendamento-db.cgr24gyuwi3d.us-east-1.rds.amazonaws.com:5432`

### 📦 Storage S3
- **Static Bucket**: `s-agendamento-static-djet24kp`
- **Media Bucket**: `s-agendamento-media-djet24kp`

## 🛠️ Como Gerenciar a Infraestrutura

### 1. Navegar para a pasta da infraestrutura
```bash
cd infrastructure/
```

### 2. Aplicar configurações
```bash
terraform apply -var-file="terraform.tfvars.simple" -auto-approve
```

### 3. Verificar estado
```bash
terraform state list
terraform output
```

### 4. Destruir infraestrutura
```bash
terraform destroy -var-file="terraform.tfvars.simple" -auto-approve
```

## 📁 Estrutura de Arquivos

```
infrastructure/
├── main.tf                    # Configuração principal do Terraform
├── variables.tf               # Variáveis de entrada
├── outputs.tf                 # Saídas da infraestrutura
├── data.tf                    # Data sources para recursos existentes
├── terraform.tfvars           # Configuração padrão
├── terraform.tfvars.simple    # Configuração simplificada
├── terraform.tfvars.existing  # Configuração para recursos existentes
├── terraform.tfvars.auto      # Configuração gerada automaticamente
├── auto_adopt_resources.py    # Script para detectar recursos existentes
├── deploy_infra.sh            # Script de deploy da infraestrutura
├── user_data.sh               # Script de inicialização da instância EC2
├── user_data_simple.sh        # Script simplificado de inicialização
├── terraform.tfstate          # Estado atual do Terraform
├── terraform.tfstate.backup   # Backup do estado
├── route53-changes.json       # Configurações DNS
└── INFRASTRUCTURE_CONFIG.md   # Documentação detalhada
```

## 🔗 Acessos

### SSH
```bash
ssh -i ~/.ssh/s-agendamento-key.pem ubuntu@44.205.204.166
```

### URLs
- **Website**: https://fourmindstech.com.br
- **Admin**: https://admin.fourmindstech.com.br
- **API**: https://api.fourmindstech.com.br

## 📝 Notas Importantes

1. **Terraform State**: O estado está salvo em `infrastructure/terraform.tfstate`
2. **Configurações**: Use `terraform.tfvars.simple` para criar tudo novo
3. **Recursos Existentes**: Use `terraform.tfvars.existing` para usar recursos já criados
4. **Backup**: Sempre mantenha backup do `terraform.tfstate`

## 🔄 Próximos Passos

1. Deploy da aplicação Django na instância EC2
2. Configuração do SSL/TLS
3. Configuração do CI/CD
4. Monitoramento e logs

---

**📧 Contato**: admin@fourmindstech.com.br  
**🌐 Website**: https://fourmindstech.com.br  
**📱 Projeto**: Sistema de Agendamento 4Minds
