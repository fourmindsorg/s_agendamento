# Script para fazer deploy dos serviços AWS
Write-Host "Inicializando Terraform..." -ForegroundColor Cyan

# Inicializar Terraform
terraform init -upgrade
if ($LASTEXITCODE -ne 0) {
    Write-Host "Erro ao inicializar Terraform" -ForegroundColor Red
    exit 1
}

Write-Host "`nTerraform inicializado com sucesso!" -ForegroundColor Green
Write-Host "`nExecutando terraform plan..." -ForegroundColor Cyan

# Executar plan
terraform plan -out=tfplan
if ($LASTEXITCODE -ne 0) {
    Write-Host "Erro no terraform plan" -ForegroundColor Red
    exit 1
}

Write-Host "`nPlan executado com sucesso!" -ForegroundColor Green
Write-Host "`nAplicando mudanças..." -ForegroundColor Cyan

# Aplicar mudanças
terraform apply tfplan
if ($LASTEXITCODE -ne 0) {
    Write-Host "Erro ao aplicar mudanças" -ForegroundColor Red
    exit 1
}

Write-Host "`n==================================" -ForegroundColor Green
Write-Host "Deploy concluído com sucesso!" -ForegroundColor Green
Write-Host "==================================" -ForegroundColor Green

# Mostrar outputs
Write-Host "`nRecursos criados:" -ForegroundColor Cyan
terraform output

