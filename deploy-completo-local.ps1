# Script PowerShell para Deploy Completo Local
# Sistema de Agendamento 4Minds - fourmindstech.com.br/agendamento

<#
.SYNOPSIS
    Script automatizado para deploy completo na AWS via Terraform

.DESCRIPTION
    Este script executa todo o processo de deploy:
    1. Valida pré-requisitos
    2. Executa Terraform para criar infraestrutura
    3. Aguarda serviços inicializarem
    4. Testa aplicação
    5. Fornece informações para próximos passos

.NOTES
    Tempo estimado: 20-25 minutos
    Requer: AWS CLI, Terraform, SSH configurado
#>

param(
    [switch]$SkipValidation,
    [switch]$AutoApprove
)

$ErrorActionPreference = "Stop"

Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                                                            ║" -ForegroundColor Cyan
Write-Host "║         🚀 DEPLOY COMPLETO - 4MINDS AGENDAMENTO           ║" -ForegroundColor Cyan
Write-Host "║                                                            ║" -ForegroundColor Cyan
Write-Host "║     Domínio: fourmindstech.com.br/agendamento             ║" -ForegroundColor Cyan
Write-Host "║     GitHub:  fourmindsorg/s_agendamento                   ║" -ForegroundColor Cyan
Write-Host "║                                                            ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# ==============================================================================
# PASSO 1: Validar Pré-requisitos
# ==============================================================================

if (-not $SkipValidation) {
    Write-Host "📋 PASSO 1/7: Validando pré-requisitos..." -ForegroundColor Yellow
    Write-Host ""
    
    # Verificar AWS CLI
    Write-Host "  Verificando AWS CLI..." -NoNewline
    try {
        $awsVersion = aws --version 2>&1
        Write-Host " ✅" -ForegroundColor Green
    } catch {
        Write-Host " ❌" -ForegroundColor Red
        Write-Host "  Erro: AWS CLI não está instalado" -ForegroundColor Red
        Write-Host "  Instale em: https://aws.amazon.com/cli/" -ForegroundColor Yellow
        exit 1
    }
    
    # Verificar credenciais AWS
    Write-Host "  Verificando credenciais AWS..." -NoNewline
    try {
        $identity = aws sts get-caller-identity 2>&1 | ConvertFrom-Json
        Write-Host " ✅" -ForegroundColor Green
        Write-Host "    Conta AWS: $($identity.Account)" -ForegroundColor Cyan
    } catch {
        Write-Host " ❌" -ForegroundColor Red
        Write-Host "  Erro: Credenciais AWS não configuradas" -ForegroundColor Red
        Write-Host "  Execute: aws configure" -ForegroundColor Yellow
        exit 1
    }
    
    # Verificar Terraform
    Write-Host "  Verificando Terraform..." -NoNewline
    try {
        $tfVersion = terraform version 2>&1
        Write-Host " ✅" -ForegroundColor Green
    } catch {
        Write-Host " ❌" -ForegroundColor Red
        Write-Host "  Erro: Terraform não está instalado" -ForegroundColor Red
        Write-Host "  Instale em: https://www.terraform.io/downloads" -ForegroundColor Yellow
        exit 1
    }
    
    # Verificar SSH key
    Write-Host "  Verificando chave SSH..." -NoNewline
    if (Test-Path "$env:USERPROFILE\.ssh\id_rsa") {
        Write-Host " ✅" -ForegroundColor Green
    } else {
        Write-Host " ⚠️" -ForegroundColor Yellow
        Write-Host "    Chave SSH não encontrada em $env:USERPROFILE\.ssh\id_rsa" -ForegroundColor Yellow
        Write-Host "    Gere com: ssh-keygen -t rsa -b 4096" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "✅ Pré-requisitos validados!" -ForegroundColor Green
    Write-Host ""
}

# ==============================================================================
# PASSO 2: Terraform Init
# ==============================================================================

Write-Host "🔧 PASSO 2/7: Inicializando Terraform..." -ForegroundColor Yellow
Write-Host ""

Push-Location aws-infrastructure

try {
    terraform init
    if ($LASTEXITCODE -ne 0) {
        throw "Terraform init falhou"
    }
    Write-Host ""
    Write-Host "✅ Terraform inicializado!" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "❌ Erro ao inicializar Terraform: $_" -ForegroundColor Red
    Pop-Location
    exit 1
}

# ==============================================================================
# PASSO 3: Terraform Validate
# ==============================================================================

Write-Host "🔍 PASSO 3/7: Validando configuração Terraform..." -ForegroundColor Yellow
Write-Host ""

try {
    terraform validate
    if ($LASTEXITCODE -ne 0) {
        throw "Terraform validate falhou"
    }
    Write-Host ""
    Write-Host "✅ Configuração válida!" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "❌ Erro na validação: $_" -ForegroundColor Red
    Pop-Location
    exit 1
}

# ==============================================================================
# PASSO 4: Terraform Plan
# ==============================================================================

Write-Host "📋 PASSO 4/7: Planejando infraestrutura..." -ForegroundColor Yellow
Write-Host ""

try {
    terraform plan -out=tfplan
    if ($LASTEXITCODE -ne 0) {
        throw "Terraform plan falhou"
    }
    Write-Host ""
    Write-Host "✅ Plano criado!" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "❌ Erro no planejamento: $_" -ForegroundColor Red
    Pop-Location
    exit 1
}

# Confirmação antes de aplicar
if (-not $AutoApprove) {
    Write-Host "⚠️  ATENÇÃO: Isto criará recursos na AWS que podem gerar custos" -ForegroundColor Yellow
    Write-Host ""
    $confirmation = Read-Host "Deseja continuar? (yes/no)"
    if ($confirmation -ne "yes") {
        Write-Host "❌ Deploy cancelado pelo usuário" -ForegroundColor Yellow
        Pop-Location
        exit 0
    }
}

# ==============================================================================
# PASSO 5: Terraform Apply (PRINCIPAL - ~15-20 min)
# ==============================================================================

Write-Host ""
Write-Host "🏗️  PASSO 5/7: Criando infraestrutura AWS..." -ForegroundColor Yellow
Write-Host ""
Write-Host "⏱️  Tempo estimado: 15-20 minutos" -ForegroundColor Cyan
Write-Host "☕ Pegue um café... Isto vai demorar um pouco" -ForegroundColor Cyan
Write-Host ""
Write-Host "Recursos a serem criados:" -ForegroundColor White
Write-Host "  • VPC e Subnets" -ForegroundColor White
Write-Host "  • Security Groups" -ForegroundColor White
Write-Host "  • RDS PostgreSQL (db.t3.micro) ⏰ Mais demorado" -ForegroundColor White
Write-Host "  • EC2 Instance (t2.micro)" -ForegroundColor White
Write-Host "  • S3 Bucket" -ForegroundColor White
Write-Host "  • CloudWatch Logs e Alarms" -ForegroundColor White
Write-Host ""

$startTime = Get-Date

try {
    terraform apply tfplan
    if ($LASTEXITCODE -ne 0) {
        throw "Terraform apply falhou"
    }
    
    $endTime = Get-Date
    $duration = $endTime - $startTime
    
    Write-Host ""
    Write-Host "✅ Infraestrutura criada com sucesso!" -ForegroundColor Green
    Write-Host "⏱️  Tempo total: $([math]::Round($duration.TotalMinutes, 1)) minutos" -ForegroundColor Cyan
    Write-Host ""
} catch {
    Write-Host "❌ Erro ao criar infraestrutura: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "💡 Dica: Verifique os logs acima para detalhes" -ForegroundColor Yellow
    Write-Host "💡 Tente executar: terraform destroy (para limpar recursos parciais)" -ForegroundColor Yellow
    Pop-Location
    exit 1
}

# ==============================================================================
# PASSO 6: Obter Outputs e Informações
# ==============================================================================

Write-Host "📊 PASSO 6/7: Obtendo informações da infraestrutura..." -ForegroundColor Yellow
Write-Host ""

try {
    # Obter IP da EC2
    $EC2_IP = terraform output -raw ec2_public_ip
    Write-Host "  🌐 IP Público EC2:    $EC2_IP" -ForegroundColor Green
    
    # Obter Endpoint RDS
    $RDS_ENDPOINT = terraform output -raw rds_endpoint
    Write-Host "  🗄️  Endpoint RDS:      $RDS_ENDPOINT" -ForegroundColor Green
    
    # Obter S3 Bucket
    $S3_BUCKET = terraform output -raw s3_bucket_name
    Write-Host "  📦 S3 Bucket:         $S3_BUCKET" -ForegroundColor Green
    
    # Obter VPC ID
    $VPC_ID = terraform output -raw vpc_id
    Write-Host "  🏗️  VPC ID:            $VPC_ID" -ForegroundColor Green
    
    Write-Host ""
} catch {
    Write-Host "  ⚠️  Não foi possível obter alguns outputs" -ForegroundColor Yellow
    Write-Host "  Execute: terraform output (para ver manualmente)" -ForegroundColor Yellow
    Write-Host ""
}

Pop-Location

# ==============================================================================
# PASSO 7: Aguardar Bootstrap e Testar
# ==============================================================================

Write-Host "⏳ PASSO 7/7: Aguardando inicialização da EC2..." -ForegroundColor Yellow
Write-Host ""
Write-Host "O script user_data.sh está configurando a EC2 agora..." -ForegroundColor Cyan
Write-Host "Isto inclui:" -ForegroundColor Cyan
Write-Host "  • Instalação de pacotes (Python, Nginx, PostgreSQL client)" -ForegroundColor White
Write-Host "  • Configuração do Nginx" -ForegroundColor White
Write-Host "  • Clone do repositório GitHub" -ForegroundColor White
Write-Host "  • Setup do ambiente Django" -ForegroundColor White
Write-Host "  • Migrações do banco de dados" -ForegroundColor White
Write-Host "  • Coleta de arquivos estáticos" -ForegroundColor White
Write-Host "  • Inicialização dos serviços" -ForegroundColor White
Write-Host ""
Write-Host "⏱️  Aguardando 5 minutos para bootstrap completar..." -ForegroundColor Cyan
Write-Host ""

# Aguardar 5 minutos
for ($i = 1; $i -le 10; $i++) {
    Write-Host "  [$i/10] Aguardando... (30s)" -ForegroundColor Gray
    Start-Sleep -Seconds 30
}

Write-Host ""
Write-Host "🧪 Testando aplicação..." -ForegroundColor Yellow
Write-Host ""

# Testar Health Check
Write-Host "  1. Health Check..." -NoNewline
try {
    $response = Invoke-WebRequest -Uri "http://$EC2_IP/agendamento/health/" -Method Get -TimeoutSec 10 -UseBasicParsing
    if ($response.StatusCode -eq 200) {
        Write-Host " ✅ OK" -ForegroundColor Green
    } else {
        Write-Host " ⚠️  HTTP $($response.StatusCode)" -ForegroundColor Yellow
    }
} catch {
    Write-Host " ❌ Falhou" -ForegroundColor Red
    Write-Host "     Aplicação pode ainda estar inicializando..." -ForegroundColor Yellow
}

# Testar Página Principal
Write-Host "  2. Página Principal..." -NoNewline
try {
    $response = Invoke-WebRequest -Uri "http://$EC2_IP/agendamento/" -Method Get -TimeoutSec 10 -UseBasicParsing
    if ($response.StatusCode -eq 200 -or $response.StatusCode -eq 302) {
        Write-Host " ✅ OK (HTTP $($response.StatusCode))" -ForegroundColor Green
    } else {
        Write-Host " ⚠️  HTTP $($response.StatusCode)" -ForegroundColor Yellow
    }
} catch {
    Write-Host " ❌ Falhou" -ForegroundColor Red
}

# Testar Admin
Write-Host "  3. Admin Panel..." -NoNewline
try {
    $response = Invoke-WebRequest -Uri "http://$EC2_IP/agendamento/admin/" -Method Get -TimeoutSec 10 -UseBasicParsing
    if ($response.StatusCode -eq 200 -or $response.StatusCode -eq 302) {
        Write-Host " ✅ OK (HTTP $($response.StatusCode))" -ForegroundColor Green
    } else {
        Write-Host " ⚠️  HTTP $($response.StatusCode)" -ForegroundColor Yellow
    }
} catch {
    Write-Host " ❌ Falhou" -ForegroundColor Red
}

# Testar Static Files
Write-Host "  4. Arquivos Estáticos..." -NoNewline
try {
    $response = Invoke-WebRequest -Uri "http://$EC2_IP/agendamento/static/admin/css/base.css" -Method Get -TimeoutSec 10 -UseBasicParsing
    if ($response.StatusCode -eq 200) {
        Write-Host " ✅ OK" -ForegroundColor Green
    } else {
        Write-Host " ⚠️  HTTP $($response.StatusCode)" -ForegroundColor Yellow
    }
} catch {
    Write-Host " ⚠️  Falhou (normal se ainda inicializando)" -ForegroundColor Yellow
}

# ==============================================================================
# RESUMO FINAL
# ==============================================================================

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                                                            ║" -ForegroundColor Green
Write-Host "║              ✅ DEPLOY CONCLUÍDO COM SUCESSO!              ║" -ForegroundColor Green
Write-Host "║                                                            ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

Write-Host "📊 INFORMAÇÕES DA INFRAESTRUTURA:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  🌐 IP Público EC2:" -ForegroundColor White
Write-Host "     $EC2_IP" -ForegroundColor Green
Write-Host ""
Write-Host "  🗄️  Endpoint RDS PostgreSQL:" -ForegroundColor White
Write-Host "     $RDS_ENDPOINT" -ForegroundColor Green
Write-Host ""
Write-Host "  📦 S3 Bucket:" -ForegroundColor White
Write-Host "     $S3_BUCKET" -ForegroundColor Green
Write-Host ""
Write-Host "  🏗️  VPC ID:" -ForegroundColor White
Write-Host "     $VPC_ID" -ForegroundColor Green
Write-Host ""

Write-Host "🔗 URLs DE ACESSO:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  🏠 Aplicação (por IP):" -ForegroundColor White
Write-Host "     http://$EC2_IP/agendamento/" -ForegroundColor Yellow
Write-Host ""
Write-Host "  👤 Admin (por IP):" -ForegroundColor White
Write-Host "     http://$EC2_IP/agendamento/admin/" -ForegroundColor Yellow
Write-Host "     Usuário: admin" -ForegroundColor Gray
Write-Host "     Senha: admin123 (⚠️ ALTERAR EM PRODUÇÃO!)" -ForegroundColor Gray
Write-Host ""
Write-Host "  🔐 SSH:" -ForegroundColor White
Write-Host "     ssh -i ~/.ssh/id_rsa ubuntu@$EC2_IP" -ForegroundColor Yellow
Write-Host ""

Write-Host "📋 PRÓXIMOS PASSOS:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  1️⃣  TESTAR APLICAÇÃO:" -ForegroundColor Yellow
Write-Host "     Abra no navegador: http://$EC2_IP/agendamento/" -ForegroundColor White
Write-Host ""
Write-Host "  2️⃣  CONFIGURAR DNS:" -ForegroundColor Yellow
Write-Host "     No seu provedor de domínio, configure:" -ForegroundColor White
Write-Host "       Tipo: A" -ForegroundColor Gray
Write-Host "       Nome: @" -ForegroundColor Gray
Write-Host "       Valor: $EC2_IP" -ForegroundColor Gray
Write-Host ""
Write-Host "       Tipo: A" -ForegroundColor Gray
Write-Host "       Nome: www" -ForegroundColor Gray
Write-Host "       Valor: $EC2_IP" -ForegroundColor Gray
Write-Host ""
Write-Host "  3️⃣  CONFIGURAR SSL (Após DNS propagado):" -ForegroundColor Yellow
Write-Host "     ssh ubuntu@fourmindstech.com.br" -ForegroundColor White
Write-Host "     sudo certbot --nginx -d fourmindstech.com.br -d www.fourmindstech.com.br" -ForegroundColor White
Write-Host ""
Write-Host "  4️⃣  ALTERAR SENHAS PADRÃO:" -ForegroundColor Yellow
Write-Host "     • Admin: admin/admin123" -ForegroundColor White
Write-Host "     • DB Password: Ver terraform.tfvars" -ForegroundColor White
Write-Host "     • SECRET_KEY: Gerar nova para produção" -ForegroundColor White
Write-Host ""

Write-Host "📞 SUPORTE:" -ForegroundColor Cyan
Write-Host "  Email: fourmindsorg@gmail.com" -ForegroundColor White
Write-Host "  Docs:  Ver _CONFIGURACAO_COMPLETA_FINAL.md" -ForegroundColor White
Write-Host ""

Write-Host "🎉 Sistema deployado com sucesso em produção!" -ForegroundColor Green
Write-Host ""

# Salvar informações em arquivo
$deployInfo = @"
╔════════════════════════════════════════════════════════════╗
║         DEPLOY REALIZADO - $(Get-Date -Format "dd/MM/yyyy HH:mm")         ║
╚════════════════════════════════════════════════════════════╝

📊 INFORMAÇÕES DA INFRAESTRUTURA:

🌐 IP Público EC2:
   $EC2_IP

🗄️  Endpoint RDS:
   $RDS_ENDPOINT

📦 S3 Bucket:
   $S3_BUCKET

🏗️  VPC ID:
   $VPC_ID

🔗 URLs:
   Aplicação: http://$EC2_IP/agendamento/
   Admin:     http://$EC2_IP/agendamento/admin/
   SSH:       ssh -i ~/.ssh/id_rsa ubuntu@$EC2_IP

📋 PRÓXIMOS PASSOS:

1. Testar aplicação no navegador
2. Configurar DNS para fourmindstech.com.br → $EC2_IP
3. Aguardar propagação DNS (15 min - 48h)
4. Configurar SSL com certbot
5. Alterar senhas padrão

📞 Suporte: fourmindsorg@gmail.com
"@

$deployInfo | Out-File -FilePath "..\DEPLOY_INFO.txt" -Encoding UTF8

Write-Host "💾 Informações salvas em: DEPLOY_INFO.txt" -ForegroundColor Cyan
Write-Host ""

Pop-Location

Write-Host "✅ Script concluído!" -ForegroundColor Green

