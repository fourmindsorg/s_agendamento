@echo off
echo ========================================
echo DIAGNOSTICO COMPLETO - INFRAESTRUTURA AWS
echo ========================================
echo.

set INSTANCE_ID=i-0bb8edf79961f187a
set EIP_ALLOC=eipalloc-07528d039f65583cf
set SG_ID=sg-04a916a777c8b1a5d

echo [1] Status da Instancia EC2
echo ========================================
aws ec2 describe-instances --instance-ids %INSTANCE_ID% --query "Reservations[0].Instances[0].[InstanceId,State.Name,PublicIpAddress,PrivateIpAddress]" --output table
echo.

echo [2] Verificando Elastic IP
echo ========================================
aws ec2 describe-addresses --allocation-ids %EIP_ALLOC% --output table
echo.

echo [3] Verificando Security Group (Regras de Entrada)
echo ========================================
aws ec2 describe-security-groups --group-ids %SG_ID% --query "SecurityGroups[0].IpPermissions" --output table
echo.

echo [4] Verificando DNS Route53
echo ========================================
aws route53 list-resource-record-sets --hosted-zone-id Z07390493BQT3ED4UA3XK --query "ResourceRecordSets[?Name=='fourmindstech.com.br.']" --output table
echo.

echo [5] Testando Conectividade com a Instancia
echo ========================================
ping -n 2 44.205.204.166
echo.

echo [6] Testando Porta 80 (HTTP)
echo ========================================
powershell -Command "Test-NetConnection -ComputerName 44.205.204.166 -Port 80"
echo.

echo ========================================
echo DIAGNOSTICO CONCLUIDO
echo ========================================
pause
