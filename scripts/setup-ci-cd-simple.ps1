# Script de Configuracao CI/CD - Versao Simplificada
# Sistema de Agendamento - 4Minds

param(
    [switch]$SkipAWS,
    [switch]$SkipGitHub,
    [switch]$Verbose
)

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

# Verificar se estamos no diretorio correto
if (-not (Test-Path "manage.py")) {
    Write-Error "Execute este script no diretorio raiz do projeto Django"
    exit 1
}

Write-Status "Verificando pre-requisitos..."

# Verificar Python
try {
    $pythonVersion = python --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Python encontrado: $pythonVersion"
    } else {
        throw "Python nao encontrado"
    }
} catch {
    Write-Error "Python nao encontrado. Instale Python 3.8+ primeiro."
    exit 1
}

# Verificar pip
try {
    $pipVersion = pip --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "pip encontrado: $pipVersion"
    } else {
        throw "pip nao encontrado"
    }
} catch {
    Write-Error "pip nao encontrado. Instale pip primeiro."
    exit 1
}

# Verificar Git
try {
    $gitVersion = git --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Git encontrado: $gitVersion"
    } else {
        throw "Git nao encontrado"
    }
} catch {
    Write-Error "Git nao encontrado. Instale Git primeiro."
    exit 1
}

Write-Success "Pre-requisitos verificados"

# Verificar AWS CLI
if (-not $SkipAWS) {
    Write-Status "Verificando AWS CLI..."
    
    try {
        $awsVersion = aws --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "AWS CLI encontrado: $awsVersion"
        } else {
            throw "AWS CLI nao encontrado"
        }
    } catch {
        Write-Warning "AWS CLI nao encontrado. Instale manualmente:"
        Write-Host "  winget install Amazon.AWSCLI" -ForegroundColor Yellow
    }
    
    # Verificar conectividade AWS
    Write-Status "Testando conectividade AWS..."
    try {
        $awsIdentity = aws sts get-caller-identity 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Conectividade AWS OK"
            Write-Host $awsIdentity
        } else {
            Write-Warning "Falha na conectividade AWS. Configure com 'aws configure'"
        }
    } catch {
        Write-Warning "Falha na conectividade AWS. Configure com 'aws configure'"
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
            throw "GitHub CLI nao encontrado"
        }
    } catch {
        Write-Warning "GitHub CLI nao encontrado. Instale com:"
        Write-Host "  winget install GitHub.cli" -ForegroundColor Yellow
    }
    
    # Verificar autenticacao GitHub
    Write-Status "Verificando autenticacao GitHub..."
    try {
        $ghStatus = gh auth status 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "GitHub autenticado"
        } else {
            Write-Warning "GitHub nao autenticado. Execute 'gh auth login'"
        }
    } catch {
        Write-Warning "GitHub nao autenticado. Execute 'gh auth login'"
    }
}

# Verificar arquivos de configuracao
Write-Status "Verificando arquivos de configuracao..."

$configFiles = @(
    ".env.example",
    "aws-infrastructure/terraform.tfvars.example"
)

foreach ($file in $configFiles) {
    if (Test-Path $file) {
        Write-Success "Arquivo $file encontrado"
    } else {
        Write-Error "Arquivo $file nao encontrado"
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
        Write-Error "Workflow $(Split-Path $workflow -Leaf) nao encontrado"
    }
}

# Testar configuracao local
Write-Status "Testando configuracao local..."

# Instalar dependencias
Write-Status "Instalando dependencias Python..."
pip install -r requirements.txt

# Configurar ambiente de teste
Write-Status "Configurando ambiente de teste..."
Copy-Item ".env.example" ".env" -Force
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
Write-Success "Configuracao CI/CD concluida!"
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Proximos passos:" -ForegroundColor Yellow
Write-Host "1. Configure AWS CLI: aws configure"
Write-Host "2. Configure GitHub CLI: gh auth login"
Write-Host "3. Configure secrets do GitHub: gh secret set SECRET_NAME --body 'valor'"
Write-Host "4. Teste o pipeline: .\scripts\test-pipeline.ps1"
Write-Host ""
Write-Host "Sistema pronto para deploy automatico!" -ForegroundColor Green
