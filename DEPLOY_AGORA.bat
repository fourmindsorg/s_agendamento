@echo off
chcp 65001 >nul
cls
echo ╔════════════════════════════════════════════════════════════════╗
echo ║                                                                ║
echo ║         🚀 DEPLOY COMPLETO - 4MINDS AGENDAMENTO               ║
echo ║                                                                ║
echo ║  Domínio: fourmindstech.com.br/agendamento                    ║
echo ║  GitHub:  fourmindsorg/s_agendamento                          ║
echo ║                                                                ║
echo ╚════════════════════════════════════════════════════════════════╝
echo.
echo.
echo ⏱️  Tempo estimado: 10-15 minutos
echo ☕ Pegue um café...
echo.
echo.

cd /d "%~dp0aws-infrastructure"

echo ═══════════════════════════════════════════════════════════════
echo   ETAPA 1: Inicializando Terraform
echo ═══════════════════════════════════════════════════════════════
echo.

terraform init -upgrade

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ❌ Erro ao inicializar Terraform
    pause
    exit /b 1
)

echo.
echo ✅ Terraform inicializado!
echo.
echo.

echo ═══════════════════════════════════════════════════════════════
echo   ETAPA 2: Criando Infraestrutura AWS
echo ═══════════════════════════════════════════════════════════════
echo.
echo 🏗️  Criando recursos AWS...
echo    • EC2 Instance (t2.micro)
echo    • SSH Key Pair  
echo    • CloudWatch Alarms
echo.

terraform apply -auto-approve

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ❌ Erro ao criar infraestrutura
    echo.
    echo 💡 Tente novamente ou veja os logs acima
    pause
    exit /b 1
)

echo.
echo.
echo ╔════════════════════════════════════════════════════════════════╗
echo ║                                                                ║
echo ║              ✅ INFRAESTRUTURA CRIADA COM SUCESSO!            ║
echo ║                                                                ║
echo ╚════════════════════════════════════════════════════════════════╝
echo.
echo.

echo ═══════════════════════════════════════════════════════════════
echo   ETAPA 3: Informações da Infraestrutura
echo ═══════════════════════════════════════════════════════════════
echo.

terraform output

echo.
echo.
echo ═══════════════════════════════════════════════════════════════
echo   PRÓXIMOS PASSOS
echo ═══════════════════════════════════════════════════════════════
echo.
echo 1. Aguarde 5 minutos para aplicação inicializar
echo 2. Acesse: http://^<EC2_IP^>/agendamento/
echo 3. Configure DNS (ver DEPLOY_INFO.txt)
echo 4. Configure SSL (após DNS)
echo.
echo.
echo ✅ Deploy concluído!
echo.
echo 💡 Ver informações completas em: DEPLOY_INFO.txt
echo.
pause

