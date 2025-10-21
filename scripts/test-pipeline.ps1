# ========================================
# Script de Teste do Pipeline CI/CD
# Sistema de Agendamento - 4Minds
# ========================================

param(
    [switch]$DryRun,
    [switch]$Verbose
)

# Configurar output colorido
$Host.UI.RawUI.ForegroundColor = "White"

function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

Write-Host "🧪 Testando Pipeline CI/CD" -ForegroundColor Cyan
Write-Host "===========================" -ForegroundColor Cyan

# Verificar se estamos no diretório correto
if (-not (Test-Path "manage.py")) {
    Write-Error "Execute este script no diretório raiz do projeto Django"
    exit 1
}

# Verificar se estamos em um repositório Git
if (-not (Test-Path ".git")) {
    Write-Error "Este não é um repositório Git. Execute 'git init' primeiro."
    exit 1
}

Write-Status "Verificando configuração do pipeline..."

# 1. Verificar arquivos de configuração
Write-Status "1. Verificando arquivos de configuração..."

$configFiles = @(
    ".env.example",
    "aws-infrastructure/terraform.tfvars.example",
    ".github/workflows/ci.yml",
    ".github/workflows/deploy.yml",
    ".github/workflows/terraform.yml"
)

$missingFiles = @()
foreach ($file in $configFiles) {
    if (Test-Path $file) {
        Write-Success "✅ $file"
    } else {
        Write-Error "❌ $file"
        $missingFiles += $file
    }
}

if ($missingFiles.Count -gt 0) {
    Write-Error "Arquivos de configuração ausentes. Execute setup-ci-cd.ps1 primeiro."
    exit 1
}

# 2. Verificar dependências Python
Write-Status "2. Verificando dependências Python..."

try {
    $requirements = Get-Content "requirements.txt"
    Write-Success "✅ requirements.txt encontrado ($($requirements.Count) dependências)"
    
    # Verificar se as dependências estão instaladas
    Write-Status "Verificando dependências instaladas..."
    pip list | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Success "✅ pip funcionando"
    } else {
        Write-Error "❌ pip não funcionando"
        exit 1
    }
} catch {
    Write-Error "❌ Erro ao verificar dependências Python"
    exit 1
}

# 3. Testar configuração Django
Write-Status "3. Testando configuração Django..."

# Configurar ambiente de teste
Write-Status "Configurando ambiente de teste..."
Copy-Item ".env.example" ".env" -Force
Add-Content ".env" "SECRET_KEY=test-secret-key-for-pipeline-test"
Add-Content ".env" "DEBUG=True"
Add-Content ".env" "ENVIRONMENT=development"

# Testar configuração Django
Write-Status "Executando verificações Django..."
try {
    python manage.py check 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Success "✅ Django check passou"
    } else {
        Write-Error "❌ Django check falhou"
        exit 1
    }
} catch {
    Write-Error "❌ Erro ao executar Django check"
    exit 1
}

# Testar migrações
Write-Status "Testando migrações..."
try {
    python manage.py migrate --dry-run 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Success "✅ Migrações OK"
    } else {
        Write-Error "❌ Erro nas migrações"
        exit 1
    }
} catch {
    Write-Error "❌ Erro ao testar migrações"
    exit 1
}

# 4. Testar coleta de arquivos estáticos
Write-Status "4. Testando coleta de arquivos estáticos..."

try {
    python manage.py collectstatic --noinput --dry-run 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Success "✅ Collectstatic OK"
    } else {
        Write-Error "❌ Erro no collectstatic"
        exit 1
    }
} catch {
    Write-Error "❌ Erro ao testar collectstatic"
    exit 1
}

# 5. Verificar AWS CLI (se disponível)
Write-Status "5. Verificando AWS CLI..."

try {
    $awsVersion = aws --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "✅ AWS CLI encontrado: $awsVersion"
        
        # Testar conectividade AWS
        Write-Status "Testando conectividade AWS..."
        $awsIdentity = aws sts get-caller-identity 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "✅ Conectividade AWS OK"
        } else {
            Write-Warning "⚠️ AWS não configurado ou sem permissões"
        }
    } else {
        Write-Warning "⚠️ AWS CLI não encontrado"
    }
} catch {
    Write-Warning "⚠️ AWS CLI não disponível"
}

# 6. Verificar GitHub CLI (se disponível)
Write-Status "6. Verificando GitHub CLI..."

try {
    $ghVersion = gh --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "✅ GitHub CLI encontrado: $ghVersion"
        
        # Verificar autenticação GitHub
        Write-Status "Verificando autenticação GitHub..."
        $ghStatus = gh auth status 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "✅ GitHub autenticado"
        } else {
            Write-Warning "⚠️ GitHub não autenticado"
        }
    } else {
        Write-Warning "⚠️ GitHub CLI não encontrado"
    }
} catch {
    Write-Warning "⚠️ GitHub CLI não disponível"
}

# 7. Verificar Terraform (se disponível)
Write-Status "7. Verificando Terraform..."

try {
    $terraformVersion = terraform --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "✅ Terraform encontrado: $terraformVersion"
        
        # Verificar configuração Terraform
        Write-Status "Verificando configuração Terraform..."
        Push-Location "aws-infrastructure"
        
        try {
            terraform init 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Success "✅ Terraform init OK"
                
                terraform validate 2>&1 | Out-Null
                if ($LASTEXITCODE -eq 0) {
                    Write-Success "✅ Terraform validate OK"
                } else {
                    Write-Warning "⚠️ Terraform validate falhou"
                }
            } else {
                Write-Warning "⚠️ Terraform init falhou"
            }
        } catch {
            Write-Warning "⚠️ Erro ao verificar Terraform"
        } finally {
            Pop-Location
        }
    } else {
        Write-Warning "⚠️ Terraform não encontrado"
    }
} catch {
    Write-Warning "⚠️ Terraform não disponível"
}

# 8. Verificar status do Git
Write-Status "8. Verificando status do Git..."

try {
    $gitStatus = git status --porcelain 2>&1
    $gitBranch = git branch --show-current 2>&1
    
    Write-Success "✅ Git funcionando (branch: $gitBranch)"
    
    if ($gitStatus) {
        Write-Warning "⚠️ Há mudanças não commitadas:"
        Write-Host $gitStatus -ForegroundColor Yellow
    } else {
        Write-Success "✅ Working directory limpo"
    }
} catch {
    Write-Error "❌ Erro ao verificar Git"
    exit 1
}

# 9. Simular teste de deploy (se não for dry run)
if (-not $DryRun) {
    Write-Status "9. Simulando teste de deploy..."
    
    # Verificar se há mudanças para commit
    $gitStatus = git status --porcelain
    if ($gitStatus) {
        Write-Status "Fazendo commit das mudanças de teste..."
        git add .
        git commit -m "Teste pipeline CI/CD - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        
        Write-Status "Fazendo push para testar pipeline..."
        git push origin main
        
        Write-Success "✅ Push realizado. Verifique os workflows em:"
        Write-Host "   https://github.com/$(gh repo view --json nameWithOwner -q .nameWithOwner)/actions" -ForegroundColor Cyan
    } else {
        Write-Warning "⚠️ Nenhuma mudança para commit"
    }
} else {
    Write-Status "9. Dry run - pulando teste de deploy"
}

# Limpeza
Write-Status "Limpando arquivos de teste..."
if (Test-Path ".env") {
    Remove-Item ".env" -Force
}

# Resumo final
Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Success "Teste do Pipeline Concluído!"
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📊 Resumo dos Testes:" -ForegroundColor Yellow
Write-Host "✅ Arquivos de configuração" -ForegroundColor Green
Write-Host "✅ Dependências Python" -ForegroundColor Green
Write-Host "✅ Configuração Django" -ForegroundColor Green
Write-Host "✅ Migrações" -ForegroundColor Green
Write-Host "✅ Collectstatic" -ForegroundColor Green
Write-Host "✅ Status Git" -ForegroundColor Green

if (-not $DryRun) {
    Write-Host ""
    Write-Host "🚀 Pipeline testado com sucesso!" -ForegroundColor Green
    Write-Host "Verifique os workflows no GitHub Actions para confirmar o deploy." -ForegroundColor Yellow
} else {
    Write-Host ""
    Write-Host "🧪 Dry run concluído. Execute sem -DryRun para testar o deploy real." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "📚 Para mais informações:" -ForegroundColor Cyan
Write-Host "  - CI/CD Analysis: CI_CD_ANALYSIS.md" -ForegroundColor White
Write-Host "  - Configuração: CONFIGURACAO.md" -ForegroundColor White
Write-Host "  - Segurança: SECURITY.md" -ForegroundColor White
