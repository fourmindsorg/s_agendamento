@echo off
echo === VERIFICANDO STATUS DA INSTÂNCIA i-0077873407e4114b1 ===

echo 1. Verificando status da instância...
aws ec2 describe-instances --instance-ids i-0077873407e4114b1 --query "Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress,StateReason.Message]" --output table

echo.
echo 2. Verificando todas as instâncias do projeto...
aws ec2 describe-instances --filters "Name=tag:Project,Values=s-agendamento" --query "Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress]" --output table

echo.
echo 3. Se a instância estiver parada, iniciando...
aws ec2 start-instances --instance-ids i-0077873407e4114b1

echo.
echo 4. Aguardando instância iniciar (60 segundos)...
timeout /t 60 /nobreak

echo.
echo 5. Verificando status final...
aws ec2 describe-instances --instance-ids i-0077873407e4114b1 --query "Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress]" --output table

echo.
echo 6. Testando conectividade...
for /f "tokens=3" %%i in ('aws ec2 describe-instances --instance-ids i-0077873407e4114b1 --query "Reservations[*].Instances[*].PublicIpAddress" --output text') do (
    echo Testando IP: %%i
    curl -I http://%%i --connect-timeout 10 --max-time 30
    if %errorlevel% equ 0 (
        echo ✅ SISTEMA FUNCIONANDO!
        echo URL: http://%%i
        echo Admin: http://%%i/admin (admin/admin123)
    ) else (
        echo ❌ Sistema não responde
    )
)

echo.
echo === VERIFICAÇÃO CONCLUÍDA ===
pause

