@echo off
echo === TESTANDO CONECTIVIDADE DO SISTEMA ===

echo 1. Obtendo IPs das instâncias ativas...
for /f "tokens=3" %%i in ('aws ec2 describe-instances --filters "Name=tag:Project,Values=s-agendamento" --query "Reservations[*].Instances[?State.Name=='running'].PublicIpAddress" --output text') do (
    echo Testando IP: %%i
    echo.
    echo Testando HTTP...
    curl -I http://%%i --connect-timeout 10 --max-time 30
    if %errorlevel% equ 0 (
        echo.
        echo ✅ SISTEMA FUNCIONANDO!
        echo.
        echo URLs para testar:
        echo - http://%%i
        echo - http://%%i/admin
        echo.
        echo Credenciais admin:
        echo - Usuário: admin
        echo - Senha: admin123
        echo.
        goto :end
    ) else (
        echo ❌ Sistema não responde no IP %%i
        echo.
    )
)

echo.
echo ❌ Nenhuma instância ativa encontrada ou sistema não está respondendo
echo.
echo Verificando instâncias...
aws ec2 describe-instances --filters "Name=tag:Project,Values=s-agendamento" --query "Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress]" --output table

:end
echo.
echo === TESTE CONCLUÍDO ===
pause
