# ========================================
# Script de Configuração CI/CD - PowerShell
# Sistema de Agendamento - 4Minds
# ========================================

param(
    [switch]$SkipAWS,
    [switch]$SkipGitHub,
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

Write-Host "Configurando CI/CD para Sistema de Agendamento" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# Verificar se estamos no diretório correto
if (-not (Test-Path "manage.py")) {
    Write-Error "Execute este script no diretório raiz do projeto Django"
    exit 1
}

Write-Status "Verificando pré-requisitos..."

# Verificar Python
try {
    $pythonVersion = python --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Python encontrado: $pythonVersion"
    } else {
        throw "Python não encontrado"
    }
} catch {
    Write-Error "Python não encontrado. Instale Python 3.8+ primeiro."
    exit 1
}

# Verificar pip
try {
    $pipVersion = pip --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "pip encontrado: $pipVersion"
    } else {
        throw "pip não encontrado"
    }
} catch {
    Write-Error "pip não encontrado. Instale pip primeiro."
    exit 1
}

# Verificar Git
try {
    $gitVersion = git --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Git encontrado: $gitVersion"
    } else {
        throw "Git não encontrado"
    }
} catch {
    Write-Error "Git não encontrado. Instale Git primeiro."
    exit 1
}

Write-Success "Pré-requisitos verificados"

# Verificar AWS CLI
if (-not $SkipAWS) {
    Write-Status "Verificando AWS CLI..."
    
    try {
        $awsVersion = aws --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "AWS CLI encontrado: $awsVersion"
        } else {
            throw "AWS CLI não encontrado"
        }
    } catch {
        Write-Warning "AWS CLI não encontrado. Instalando..."
        
        # Baixar e instalar AWS CLI
        $awsInstaller = "AWSCLIV2.msi"
        $awsUrl = "https://awscli.amazonaws.com/AWSCLIV2.msi"
        
        Write-Status "Baixando AWS CLI..."
        Invoke-WebRequest -Uri $awsUrl -OutFile $awsInstaller
        
        Write-Status "Instalando AWS CLI..."
        Start-Process msiexec.exe -Wait -ArgumentList "/i $awsInstaller /quiet"
        
        # Limpar arquivo temporário
        Remove-Item $awsInstaller -Force
        
        Write-Success "AWS CLI instalado"
    }
    
    # Configurar AWS CLI
    Write-Status "Configurando AWS CLI..."
    Write-Host "Você precisará das seguintes credenciais AWS:" -ForegroundColor Yellow
    Write-Host "- Access Key ID" -ForegroundColor Yellow
    Write-Host "- Secret Access Key" -ForegroundColor Yellow
    Write-Host "- Região (padrão: us-east-1)" -ForegroundColor Yellow
    Write-Host ""
    
    $configureAWS = Read-Host "Deseja configurar AWS CLI agora? (y/n)"
    
    if ($configureAWS -eq "y" -or $configureAWS -eq "Y") {
        aws configure
        Write-Success "AWS CLI configurado"
    } else {
        Write-Warning "AWS CLI não configurado. Configure manualmente com 'aws configure'"
    }
    
    # Verificar conectividade AWS
    Write-Status "Testando conectividade AWS..."
    try {
        $awsIdentity = aws sts get-caller-identity 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Conectividade AWS OK"
            Write-Host $awsIdentity
        } else {
            Write-Error "Falha na conectividade AWS. Verifique suas credenciais."
            exit 1
        }
    } catch {
        Write-Error "Falha na conectividade AWS. Verifique suas credenciais."
        exit 1
    }
}

# Verificar GitHub CLI
if (-not $SkipGitHub) {
    Write-Status "Verificando GitHub CLI..."
    
    try {
        $ghVersion = gh --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "GitHub CLI encontrado: $ghVersion"
        } else {
            throw "GitHub CLI não encontrado"
        }
    } catch {
        Write-Warning "GitHub CLI não encontrado. Instalando..."
        
        # Instalar GitHub CLI via winget
        try {
            winget install GitHub.cli
            Write-Success "GitHub CLI instalado"
        } catch {
            Write-Error "Falha ao instalar GitHub CLI. Instale manualmente:"
            Write-Host "  winget install GitHub.cli" -ForegroundColor Yellow
            exit 1
        }
    }
    
    # Verificar autenticação GitHub
    Write-Status "Verificando autenticação GitHub..."
    try {
        $ghStatus = gh auth status 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "GitHub autenticado"
        } else {
            throw "GitHub não autenticado"
        }
    } catch {
        Write-Warning "GitHub não autenticado. Fazendo login..."
        gh auth login
    }
    
    # Verificar secrets do GitHub
    Write-Status "Verificando secrets do GitHub..."
    $repo = gh repo view --json nameWithOwner -q .nameWithOwner
    
    Write-Host "Secrets necessarios para o repositorio $repo:" -ForegroundColor Yellow
    Write-Host ""
    
    # Lista de secrets necessários
    $secrets = @(
        "AWS_ACCESS_KEY_ID",
        "AWS_SECRET_ACCESS_KEY", 
        "EC2_HOST",
        "EC2_USERNAME",
        "EC2_SSH_KEY",
        "CLOUDFLARE_API_TOKEN"
    )
    
    # Verificar cada secret
    $missingSecrets = @()
    $configuredSecrets = @()
    
    foreach ($secret in $secrets) {
        $secretExists = gh secret list | Select-String $secret
        if ($secretExists) {
            Write-Success "✅ $secret - Configurado"
            $configuredSecrets += $secret
        } else {
            Write-Warning "❌ $secret - NÃO CONFIGURADO"
            $missingSecrets += $secret
        }
    }
    
    Write-Host ""
    Write-Host "=================================" -ForegroundColor Cyan
    Write-Host "📊 RESUMO DA VERIFICAÇÃO" -ForegroundColor Cyan
    Write-Host "=================================" -ForegroundColor Cyan
    
    Write-Host "✅ Secrets configurados: $($configuredSecrets.Count)" -ForegroundColor Green
    Write-Host "❌ Secrets ausentes: $($missingSecrets.Count)" -ForegroundColor Red
    
    if ($missingSecrets.Count -gt 0) {
        Write-Host ""
        Write-Warning "Secrets ausentes encontrados:"
        Write-Host ""
        
        foreach ($secret in $missingSecrets) {
            Write-Host "🔧 $secret" -ForegroundColor Yellow
        }
        
        Write-Host ""
        Write-Host "Para configurar secrets ausentes, use:" -ForegroundColor Yellow
        Write-Host "gh secret set SECRET_NAME --body 'valor_do_secret'" -ForegroundColor Yellow
    }
}

# Verificar arquivos de configuração
Write-Status "Verificando arquivos de configuração..."

$configFiles = @(
    ".env.example",
    "aws-infrastructure/terraform.tfvars.example"
)

foreach ($file in $configFiles) {
    if (Test-Path $file) {
        Write-Success "Arquivo $file encontrado"
    } else {
        Write-Error "Arquivo $file não encontrado"
        exit 1
    }
}

# Verificar workflows
Write-Status "Verificando workflows do GitHub Actions..."

$workflows = @(
    ".github/workflows/ci.yml",
    ".github/workflows/deploy.yml", 
    ".github/workflows/terraform.yml",
    ".github/workflows/complete-setup.yml"
)

foreach ($workflow in $workflows) {
    if (Test-Path $workflow) {
        Write-Success "Workflow $(Split-Path $workflow -Leaf) encontrado"
    } else {
        Write-Error "Workflow $(Split-Path $workflow -Leaf) não encontrado"
    }
}

# Testar configuração local
Write-Status "Testando configuração local..."

# Instalar dependências
Write-Status "Instalando dependências Python..."
pip install -r requirements.txt

# Configurar ambiente de teste
Write-Status "Configurando ambiente de teste..."
Copy-Item ".env.example" ".env"
Add-Content ".env" "SECRET_KEY=test-secret-key-for-ci-cd"
Add-Content ".env" "DEBUG=True"
Add-Content ".env" "ENVIRONMENT=development"

# Executar testes
Write-Status "Executando testes Django..."
python manage.py check
python manage.py test --verbosity=0

Write-Success "Testes Django executados com sucesso"

# Resumo final
Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Success "Configuração CI/CD concluída!"
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 Próximos passos:" -ForegroundColor Yellow
Write-Host "1. Configure os secrets ausentes no GitHub:"
Write-Host "   gh secret set SECRET_NAME --body 'valor'"
Write-Host ""
Write-Host "2. Configure o arquivo terraform.tfvars:"
Write-Host "   notepad aws-infrastructure/terraform.tfvars"
Write-Host ""
Write-Host "3. Teste o deploy:"
Write-Host "   git add ."
Write-Host "   git commit -m 'Teste CI/CD'"
Write-Host "   git push origin main"
Write-Host ""
Write-Host "4. Monitore os workflows em:"
Write-Host "   https://github.com/$repo/actions"
Write-Host ""
Write-Host "Sistema pronto para deploy automatico!" -ForegroundColor Green
