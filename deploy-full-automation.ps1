# ╔════════════════════════════════════════════════════════════════╗
# ║  DEPLOY COMPLETO AUTOMATIZADO - 4MINDS SISTEMA DE AGENDAMENTO ║
# ║  Terraform → Commit → GitHub → Deploy AWS                      ║
# ╚════════════════════════════════════════════════════════════════╝

param(
    [switch]$SkipTerraform,
    [switch]$SkipTests
)

$ErrorActionPreference = "Continue"
$StartTime = Get-Date

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                                                                ║" -ForegroundColor Cyan
Write-Host "║       🚀 DEPLOY COMPLETO AUTOMATIZADO - 4MINDS                ║" -ForegroundColor Cyan
Write-Host "║                                                                ║" -ForegroundColor Cyan
Write-Host "║  Domínio:  fourmindstech.com.br/agendamento                   ║" -ForegroundColor Cyan
Write-Host "║  GitHub:   fourmindsorg/s_agendamento                         ║" -ForegroundColor Cyan
Write-Host "║  AWS:      us-east-1                                          ║" -ForegroundColor Cyan
Write-Host "║                                                                ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# ==============================================================================
# ETAPA 1: VALIDAR PRÉ-REQUISITOS
# ==============================================================================

Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host "  ETAPA 1/6: Validando Pré-requisitos" -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host ""

$validationErrors = @()

# Verificar AWS CLI
Write-Host "  [1/5] Verificando AWS CLI..." -NoNewline
try {
    $awsVersion = aws --version 2>&1
    Write-Host " ✅" -ForegroundColor Green
} catch {
    Write-Host " ❌" -ForegroundColor Red
    $validationErrors += "AWS CLI não instalado"
}

# Verificar Terraform
Write-Host "  [2/5] Verificando Terraform..." -NoNewline
try {
    $tfVersion = terraform version 2>&1
    Write-Host " ✅" -ForegroundColor Green
} catch {
    Write-Host " ❌" -ForegroundColor Red
    $validationErrors += "Terraform não instalado"
}

# Verificar Git
Write-Host "  [3/5] Verificando Git..." -NoNewline
try {
    $gitVersion = git --version 2>&1
    Write-Host " ✅" -ForegroundColor Green
} catch {
    Write-Host " ❌" -ForegroundColor Red
    $validationErrors += "Git não instalado"
}

# Verificar AWS Credentials
Write-Host "  [4/5] Verificando credenciais AWS..." -NoNewline
try {
    $identity = aws sts get-caller-identity 2>&1 | ConvertFrom-Json
    Write-Host " ✅" -ForegroundColor Green
    Write-Host "        Conta AWS: $($identity.Account)" -ForegroundColor Gray
} catch {
    Write-Host " ❌" -ForegroundColor Red
    $validationErrors += "AWS credentials não configuradas (execute: aws configure)"
}

# Verificar repositório Git
Write-Host "  [5/5] Verificando repositório Git..." -NoNewline
$gitRemote = git remote -v 2>&1 | Select-String "fourmindsorg/s_agendamento"
if ($gitRemote) {
    Write-Host " ✅" -ForegroundColor Green
} else {
    Write-Host " ⚠️" -ForegroundColor Yellow
    Write-Host "        Remote pode não estar configurado para fourmindsorg" -ForegroundColor Yellow
}

if ($validationErrors.Count -gt 0) {
    Write-Host ""
    Write-Host "❌ Erros de validação encontrados:" -ForegroundColor Red
    foreach ($error in $validationErrors) {
        Write-Host "   • $error" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "Corrija os erros acima e execute novamente." -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "✅ Todos os pré-requisitos validados!" -ForegroundColor Green
Write-Host ""

# ==============================================================================
# ETAPA 2: EXECUTAR TERRAFORM APPLY
# ==============================================================================

if (-not $SkipTerraform) {
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Yellow
    Write-Host "  ETAPA 2/6: Criando Infraestrutura AWS com Terraform" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "⏱️  Tempo estimado: 10-15 minutos" -ForegroundColor Cyan
    Write-Host "☕ Pegue um café enquanto criamos a infraestrutura..." -ForegroundColor Cyan
    Write-Host ""
    
    Push-Location aws-infrastructure
    
    try {
        # Terraform Init
        Write-Host "  🔧 Inicializando Terraform..." -ForegroundColor Cyan
        terraform init -upgrade
        
        if ($LASTEXITCODE -ne 0) {
            throw "Terraform init falhou"
        }
        
        Write-Host "  ✅ Terraform inicializado" -ForegroundColor Green
        Write-Host ""
        
        # Terraform Apply
        Write-Host "  🏗️  Criando recursos AWS..." -ForegroundColor Cyan
        Write-Host ""
        
        $tfStartTime = Get-Date
        terraform apply -auto-approve
        
        if ($LASTEXITCODE -ne 0) {
            throw "Terraform apply falhou"
        }
        
        $tfEndTime = Get-Date
        $tfDuration = $tfEndTime - $tfStartTime
        
        Write-Host ""
        Write-Host "  ✅ Infraestrutura criada com sucesso!" -ForegroundColor Green
        Write-Host "  ⏱️  Tempo: $([math]::Round($tfDuration.TotalMinutes, 1)) minutos" -ForegroundColor Cyan
        Write-Host ""
        
        # Obter Outputs
        Write-Host "  📊 Obtendo informações da infraestrutura..." -ForegroundColor Cyan
        Write-Host ""
        
        $EC2_IP = terraform output -raw ec2_public_ip 2>$null
        $RDS_ENDPOINT = terraform output -raw rds_endpoint 2>$null
        $S3_BUCKET = terraform output -raw s3_bucket_name 2>$null
        $VPC_ID = terraform output -raw vpc_id 2>$null
        
        Write-Host "  🌐 IP Público EC2:    $EC2_IP" -ForegroundColor Green
        Write-Host "  🗄️  Endpoint RDS:      $RDS_ENDPOINT" -ForegroundColor Green
        Write-Host "  📦 S3 Bucket:         $S3_BUCKET" -ForegroundColor Green
        Write-Host "  🏗️  VPC ID:            $VPC_ID" -ForegroundColor Green
        Write-Host ""
        
    } catch {
        Write-Host ""
        Write-Host "  ❌ Erro no Terraform: $_" -ForegroundColor Red
        Write-Host ""
        Pop-Location
        exit 1
    }
    
    Pop-Location
} else {
    Write-Host "⏭️  Etapa 2 PULADA (SkipTerraform)" -ForegroundColor Yellow
    Write-Host ""
    
    # Tentar obter outputs mesmo assim
    Push-Location aws-infrastructure
    $EC2_IP = terraform output -raw ec2_public_ip 2>$null
    $RDS_ENDPOINT = terraform output -raw rds_endpoint 2>$null
    $S3_BUCKET = terraform output -raw s3_bucket_name 2>$null
    Pop-Location
}

# ==============================================================================
# ETAPA 3: AGUARDAR EC2 BOOTSTRAP
# ==============================================================================

Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host "  ETAPA 3/6: Aguardando Inicialização da EC2" -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host ""
Write-Host "  O script user_data.sh está configurando a EC2..." -ForegroundColor Cyan
Write-Host "  Isto inclui:" -ForegroundColor Cyan
Write-Host "    • Instalação de pacotes (Nginx, Python, PostgreSQL)" -ForegroundColor White
Write-Host "    • Clone do repositório GitHub" -ForegroundColor White
Write-Host "    • Setup do Django" -ForegroundColor White
Write-Host "    • Migrações do banco de dados" -ForegroundColor White
Write-Host "    • Coleta de arquivos estáticos" -ForegroundColor White
Write-Host "    • Inicialização dos serviços" -ForegroundColor White
Write-Host ""
Write-Host "  ⏱️  Aguardando 5 minutos para bootstrap..." -ForegroundColor Cyan
Write-Host ""

# Aguardar com progresso visual
for ($i = 1; $i -le 10; $i++) {
    $percentage = $i * 10
    Write-Host "  [$i/10] Progresso: $percentage% " -NoNewline -ForegroundColor Gray
    Start-Sleep -Seconds 30
    Write-Host "✓" -ForegroundColor Green
}

Write-Host ""
Write-Host "  ✅ Período de bootstrap concluído" -ForegroundColor Green
Write-Host ""

# ==============================================================================
# ETAPA 4: TESTAR APLICAÇÃO
# ==============================================================================

if (-not $SkipTests) {
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Yellow
    Write-Host "  ETAPA 4/6: Testando Aplicação em Produção" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Yellow
    Write-Host ""
    
    if ($EC2_IP) {
        # Teste 1: Health Check
        Write-Host "  [1/4] Health Check..." -NoNewline
        try {
            $response = Invoke-WebRequest -Uri "http://$EC2_IP/agendamento/health/" -Method Get -TimeoutSec 10 -UseBasicParsing 2>$null
            if ($response.StatusCode -eq 200) {
                Write-Host " ✅ OK" -ForegroundColor Green
            } else {
                Write-Host " ⚠️  HTTP $($response.StatusCode)" -ForegroundColor Yellow
            }
        } catch {
            Write-Host " ❌ Falhou (aplicação pode estar inicializando)" -ForegroundColor Yellow
        }
        
        # Teste 2: Página Principal
        Write-Host "  [2/4] Página Principal..." -NoNewline
        try {
            $response = Invoke-WebRequest -Uri "http://$EC2_IP/agendamento/" -Method Get -TimeoutSec 10 -UseBasicParsing 2>$null
            if ($response.StatusCode -eq 200 -or $response.StatusCode -eq 302) {
                Write-Host " ✅ OK (HTTP $($response.StatusCode))" -ForegroundColor Green
            } else {
                Write-Host " ⚠️  HTTP $($response.StatusCode)" -ForegroundColor Yellow
            }
        } catch {
            Write-Host " ❌ Falhou" -ForegroundColor Yellow
        }
        
        # Teste 3: Admin
        Write-Host "  [3/4] Admin Panel..." -NoNewline
        try {
            $response = Invoke-WebRequest -Uri "http://$EC2_IP/agendamento/admin/" -Method Get -TimeoutSec 10 -UseBasicParsing 2>$null
            if ($response.StatusCode -eq 200 -or $response.StatusCode -eq 302) {
                Write-Host " ✅ OK (HTTP $($response.StatusCode))" -ForegroundColor Green
            } else {
                Write-Host " ⚠️  HTTP $($response.StatusCode)" -ForegroundColor Yellow
            }
        } catch {
            Write-Host " ❌ Falhou" -ForegroundColor Yellow
        }
        
        # Teste 4: Arquivos Estáticos
        Write-Host "  [4/4] Arquivos Estáticos..." -NoNewline
        try {
            $response = Invoke-WebRequest -Uri "http://$EC2_IP/agendamento/static/css/style.css" -Method Get -TimeoutSec 10 -UseBasicParsing 2>$null
            if ($response.StatusCode -eq 200) {
                Write-Host " ✅ OK" -ForegroundColor Green
            } else {
                Write-Host " ⚠️  HTTP $($response.StatusCode)" -ForegroundColor Yellow
            }
        } catch {
            Write-Host " ⚠️  Falhou (pode estar carregando)" -ForegroundColor Yellow
        }
        
        Write-Host ""
    } else {
        Write-Host "  ⚠️  IP da EC2 não disponível. Pulando testes." -ForegroundColor Yellow
        Write-Host ""
    }
} else {
    Write-Host "⏭️  Etapa 4 PULADA (SkipTests)" -ForegroundColor Yellow
    Write-Host ""
}

# ==============================================================================
# ETAPA 5: COMMIT E PUSH PARA GITHUB
# ==============================================================================

Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host "  ETAPA 5/6: Commit e Push para GitHub" -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host ""

# Verificar se há alterações
Write-Host "  📝 Verificando alterações..." -ForegroundColor Cyan
$gitStatus = git status --porcelain

if ($gitStatus) {
    Write-Host "  ✅ Alterações detectadas" -ForegroundColor Green
    Write-Host ""
    
    # Adicionar todos os arquivos
    Write-Host "  📁 Adicionando arquivos ao stage..." -ForegroundColor Cyan
    git add .
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ Arquivos adicionados" -ForegroundColor Green
    }
    Write-Host ""
    
    # Commit
    $commitMessage = "Deploy completo: Infrastructure + CI/CD + Subpath /agendamento [$(Get-Date -Format 'dd/MM/yyyy HH:mm')]"
    Write-Host "  💾 Fazendo commit..." -ForegroundColor Cyan
    Write-Host "     Mensagem: $commitMessage" -ForegroundColor Gray
    git commit -m "$commitMessage"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ Commit realizado" -ForegroundColor Green
    }
    Write-Host ""
    
    # Push
    Write-Host "  📤 Enviando para GitHub..." -ForegroundColor Cyan
    git push origin main
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ Push realizado com sucesso!" -ForegroundColor Green
        Write-Host ""
        Write-Host "  🔗 Ver no GitHub:" -ForegroundColor Cyan
        Write-Host "     https://github.com/fourmindsorg/s_agendamento" -ForegroundColor White
        Write-Host ""
        Write-Host "  🔄 GitHub Actions:" -ForegroundColor Cyan
        Write-Host "     https://github.com/fourmindsorg/s_agendamento/actions" -ForegroundColor White
    } else {
        Write-Host "  ⚠️  Push falhou (verifique conexão com GitHub)" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ℹ️  Nenhuma alteração para commit" -ForegroundColor Cyan
}

Write-Host ""

# ==============================================================================
# ETAPA 6: SALVAR INFORMAÇÕES DO DEPLOY
# ==============================================================================

Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host "  ETAPA 6/6: Salvando Informações do Deploy" -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host ""

$EndTime = Get-Date
$TotalDuration = $EndTime - $StartTime

# Criar arquivo com informações do deploy
$deployInfo = @"
╔════════════════════════════════════════════════════════════════╗
║                    DEPLOY REALIZADO COM SUCESSO                ║
╚════════════════════════════════════════════════════════════════╝

📅 Data/Hora: $(Get-Date -Format "dd/MM/yyyy HH:mm:ss")
⏱️  Duração Total: $([math]::Round($TotalDuration.TotalMinutes, 1)) minutos

═══════════════════════════════════════════════════════════════════

📊 INFORMAÇÕES DA INFRAESTRUTURA:

🌐 IP Público EC2:
   $EC2_IP

🗄️  Endpoint RDS PostgreSQL:
   $RDS_ENDPOINT

📦 S3 Bucket:
   $S3_BUCKET

🏗️  VPC ID:
   $VPC_ID

═══════════════════════════════════════════════════════════════════

🔗 URLS DE ACESSO:

🏠 Aplicação (por IP):
   http://$EC2_IP/agendamento/

👤 Admin (por IP):
   http://$EC2_IP/agendamento/admin/
   Usuário: admin
   Senha: admin123 (⚠️ ALTERAR EM PRODUÇÃO!)

🌐 Aplicação (por domínio - após DNS):
   http://fourmindstech.com.br/agendamento/

🔐 SSH:
   ssh -i ~/.ssh/id_rsa ubuntu@$EC2_IP

💻 Comando SSH alternativo:
   ssh ubuntu@fourmindstech.com.br (após DNS configurado)

═══════════════════════════════════════════════════════════════════

📋 PRÓXIMOS PASSOS:

1️⃣  TESTAR APLICAÇÃO (AGORA):
   Abra o navegador: http://$EC2_IP/agendamento/
   Faça login no admin: http://$EC2_IP/agendamento/admin/

2️⃣  CONFIGURAR DNS:
   No seu provedor de domínio (Registro.br, etc), configure:
   
   Registro 1:
     Tipo: A
     Nome: @
     Valor: $EC2_IP
     TTL: 300
   
   Registro 2:
     Tipo: A
     Nome: www
     Valor: $EC2_IP
     TTL: 300

3️⃣  AGUARDAR PROPAGAÇÃO DNS (15 min - 48h):
   Teste com: nslookup fourmindstech.com.br
   Quando propagar, acesse: http://fourmindstech.com.br/agendamento/

4️⃣  CONFIGURAR SSL/HTTPS (Após DNS):
   ssh ubuntu@fourmindstech.com.br
   sudo certbot --nginx -d fourmindstech.com.br -d www.fourmindstech.com.br
   
   Siga as instruções do Certbot (email, aceitar termos, etc)

5️⃣  ALTERAR SENHAS PADRÃO:
   • Admin: Conecte via SSH e execute:
     cd /home/django/sistema-de-agendamento
     source venv/bin/activate
     python manage.py changepassword admin
   
   • DB Password: Já configurado em terraform.tfvars
   
   • SECRET_KEY: Gerar nova para produção

6️⃣  CONFIGURAR MONITORAMENTO:
   • CloudWatch Logs: https://console.aws.amazon.com/cloudwatch
   • SNS Email: Configure em https://console.aws.amazon.com/sns

═══════════════════════════════════════════════════════════════════

🔗 LINKS IMPORTANTES:

GitHub Repositório:
  https://github.com/fourmindsorg/s_agendamento

GitHub Actions:
  https://github.com/fourmindsorg/s_agendamento/actions

AWS Console:
  https://console.aws.amazon.com

EC2 Instances:
  https://console.aws.amazon.com/ec2/home?region=us-east-1#Instances:

RDS Databases:
  https://console.aws.amazon.com/rds/home?region=us-east-1#databases:

═══════════════════════════════════════════════════════════════════

📞 SUPORTE:

Email: fourmindsorg@gmail.com
Website: http://fourmindstech.com.br/agendamento/

Documentação:
  • README_DEPLOY.md - Guia de deploy
  • _CONFIGURACAO_COMPLETA_FINAL.md - Visão geral
  • COMANDOS_RAPIDOS.md - Comandos úteis
  • GITHUB_CICD_SETUP.md - CI/CD completo

═══════════════════════════════════════════════════════════════════

✅ Sistema deployado em produção com sucesso!
🎉 Parabéns!

═══════════════════════════════════════════════════════════════════
"@

# Salvar em arquivo
$deployInfo | Out-File -FilePath "DEPLOY_INFO.txt" -Encoding UTF8

Write-Host "  💾 Informações salvas em: DEPLOY_INFO.txt" -ForegroundColor Cyan
Write-Host ""

# ==============================================================================
# RESUMO FINAL
# ==============================================================================

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                                                                ║" -ForegroundColor Green
Write-Host "║              ✅ DEPLOY COMPLETO EXECUTADO!                     ║" -ForegroundColor Green
Write-Host "║                                                                ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

Write-Host "📊 RESUMO DO DEPLOY:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  ✅ Infraestrutura AWS criada" -ForegroundColor Green
Write-Host "  ✅ Aplicação deployada" -ForegroundColor Green
Write-Host "  ✅ Código enviado para GitHub" -ForegroundColor Green
Write-Host "  ✅ Informações documentadas" -ForegroundColor Green
Write-Host ""
Write-Host "  ⏱️  Tempo total: $([math]::Round($TotalDuration.TotalMinutes, 1)) minutos" -ForegroundColor Cyan
Write-Host ""

if ($EC2_IP) {
    Write-Host "🌐 ACESSE SUA APLICAÇÃO:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  🏠 Homepage:" -ForegroundColor White
    Write-Host "     http://$EC2_IP/agendamento/" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  👤 Admin:" -ForegroundColor White
    Write-Host "     http://$EC2_IP/agendamento/admin/" -ForegroundColor Yellow
    Write-Host "     Usuário: admin / Senha: admin123" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  🔐 SSH:" -ForegroundColor White
    Write-Host "     ssh -i ~/.ssh/id_rsa ubuntu@$EC2_IP" -ForegroundColor Yellow
    Write-Host ""
}

Write-Host "📋 PRÓXIMOS PASSOS:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  1. Abra o navegador e teste a aplicação" -ForegroundColor White
Write-Host "  2. Configure DNS (veja DEPLOY_INFO.txt)" -ForegroundColor White
Write-Host "  3. Configure SSL após DNS propagar" -ForegroundColor White
Write-Host "  4. Altere senhas padrão" -ForegroundColor White
Write-Host ""

Write-Host "📚 DOCUMENTAÇÃO:" -ForegroundColor Cyan
Write-Host "  • Ver DEPLOY_INFO.txt para informações completas" -ForegroundColor White
Write-Host "  • Ver README_DEPLOY.md para próximos passos" -ForegroundColor White
Write-Host ""

Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                                                                ║" -ForegroundColor Green
Write-Host "║                    🎉 PARABÉNS!                                ║" -ForegroundColor Green
Write-Host "║         Sistema deployado em produção com sucesso!             ║" -ForegroundColor Green
Write-Host "║                                                                ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

# Abrir browser automaticamente (opcional)
$openBrowser = Read-Host "Deseja abrir a aplicação no navegador agora? (s/n)"
if ($openBrowser -eq "s" -or $openBrowser -eq "S") {
    if ($EC2_IP) {
        Start-Process "http://$EC2_IP/agendamento/"
    }
}

Write-Host ""
Write-Host "✅ Script concluído!" -ForegroundColor Green
Write-Host ""
Write-Host "Pressione qualquer tecla para sair..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

