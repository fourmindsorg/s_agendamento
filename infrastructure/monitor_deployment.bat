@echo off
echo === MONITORANDO DEPLOY AUTOMÁTICO ===

:loop
echo.
echo Verificando instâncias ativas...
aws ec2 describe-instances --filters "Name=tag:Project,Values=s-agendamento" --query "Reservations[*].Instances[?State.Name=='running'].[InstanceId,PublicIpAddress,Tags[?Key=='Name'].Value|[0]]" --output table

echo.
echo Testando conectividade...
for /f "tokens=2" %%i in ('aws ec2 describe-instances --filters "Name=tag:Project,Values=s-agendamento" --query "Reservations[*].Instances[?State.Name=='running'].PublicIpAddress" --output text') do (
    echo Testando IP: %%i
    curl -I http://%%i --connect-timeout 5 --max-time 10 2>nul
    if %errorlevel% equ 0 (
        echo ✅ SISTEMA FUNCIONANDO!
        echo URL: http://%%i
        echo Admin: http://%%i/admin (admin/admin123)
        goto :success
    ) else (
        echo ❌ Sistema ainda não responde
    )
)

echo.
echo Aguardando 30 segundos...
timeout /t 30 /nobreak
goto :loop

:success
echo.
echo === DEPLOY CONCLUÍDO COM SUCESSO! ===
pause
