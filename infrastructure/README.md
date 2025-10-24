# Infraestrutura AWS - Sistema de Agendamento 4Minds

Este diretório contém os arquivos Terraform para criar a infraestrutura AWS necessária para o sistema de agendamento 4Minds.

## 📋 Pré-requisitos

1. **AWS CLI** instalado e configurado
2. **Terraform** versão 1.0 ou superior
3. **Credenciais AWS** configuradas
4. **Domínio Route 53** configurado (fourmindstech.com.br)

## 🚀 Como usar

### 1. Configurar credenciais AWS

```bash
aws configure
```

### 2. Configurar variáveis

Copie o arquivo de exemplo e configure suas variáveis:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edite o arquivo `terraform.tfvars` e configure:
- `db_password`: Senha segura para o banco de dados
- `secret_key`: Chave secreta do Django
- `hosted_zone_id`: ID da zona hospedada Route 53

### 3. Inicializar Terraform

```bash
terraform init
```

### 4. Planejar a infraestrutura

```bash
terraform plan
```

### 5. Aplicar a infraestrutura

```bash
terraform apply
```

### 6. Verificar outputs

```bash
terraform output
```

## 🏗️ Recursos criados

### Rede
- **VPC**: Rede virtual privada (10.0.0.0/16)
- **Subnets**: Pública e privada em zonas de disponibilidade diferentes
- **Internet Gateway**: Para acesso à internet
- **Route Tables**: Configuração de roteamento

### Segurança
- **Security Groups**: Regras de firewall para EC2 e RDS
- **S3 Buckets**: Criptografados com políticas de acesso

### Compute
- **EC2 Instance**: Servidor Ubuntu com Django pré-configurado
- **Elastic IP**: IP público estático
- **RDS PostgreSQL**: Banco de dados gerenciado

### DNS
- **Route 53 Records**: Configuração de DNS para o domínio

### Storage
- **S3 Buckets**: Para arquivos estáticos e mídia
- **Backups automáticos**: RDS com backup configurado

## 🔧 Configurações

### Ambiente de Produção
- **Região**: us-east-1
- **Instância**: t2.micro (Free Tier)
- **Banco**: db.t4g.micro (Free Tier)
- **Storage**: 20GB (Free Tier)

### URLs configuradas
- `https://fourmindstech.com.br`
- `https://www.fourmindstech.com.br`
- `https://api.fourmindstech.com.br`
- `https://admin.fourmindstech.com.br`

## 🛠️ Troubleshooting

### Erro "execution halted"
Este erro geralmente indica problemas com:
1. Credenciais AWS inválidas
2. Permissões insuficientes
3. Recursos já existentes

**Solução**:
```bash
# Verificar credenciais
aws sts get-caller-identity

# Limpar estado se necessário
terraform destroy
terraform init
terraform apply
```

### Problemas de conectividade
```bash
# Verificar status dos recursos
terraform state list
terraform show

# Verificar logs da instância
ssh -i sua-chave.pem ubuntu@IP_PUBLICO
```

## 📊 Monitoramento

- **Logs**: Sistema de logging nativo do Django
- **RDS**: Monitoramento de performance
- **EC2**: Métricas de CPU, memória e rede

## 🔒 Segurança

- **SSL/TLS**: Configure certificados SSL após o deploy
- **Backup**: Backups automáticos do RDS
- **Firewall**: Security Groups configurados
- **Criptografia**: S3 e RDS criptografados

## 🗑️ Limpeza

Para remover toda a infraestrutura:

```bash
terraform destroy
```

## 📞 Suporte

Para problemas ou dúvidas, entre em contato com a equipe 4Minds.

---

**Desenvolvido por 4Minds** 🚀


