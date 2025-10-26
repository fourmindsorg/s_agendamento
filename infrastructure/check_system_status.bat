@echo off
echo === VERIFICANDO STATUS DO SISTEMA EM PRODUÇÃO ===

echo 1. Verificando status da instância EC2...
aws ec2 describe-instances --instance-ids i-000e6aecf9ad53679 --query "Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress,PublicDnsName]" --output table

echo.
echo 2. Verificando status do RDS...
aws rds describe-db-instances --db-instance-identifier s-agendamento-db --query "DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus,Endpoint.Address]" --output table

echo.
echo 3. Verificando Security Groups...
aws ec2 describe-security-groups --group-ids sg-0c66bf0346b9729ca --query "SecurityGroups[*].[GroupId,GroupName,IngressRules[*].[FromPort,ToPort,Protocol,CidrIpv4]]" --output table

echo.
echo 4. Verificando S3 Buckets...
aws s3api list-buckets --query "Buckets[?contains(Name, 's-agendamento')].[Name,CreationDate]" --output table

echo.
echo 5. Testando conectividade (se curl estiver disponível)...
curl -I http://34.202.149.24 --connect-timeout 10 --max-time 30 2>nul
if %errorlevel% equ 0 (
    echo ✅ Sistema respondendo via HTTP
) else (
    echo ❌ Sistema não respondendo via HTTP
)

echo.
echo 6. Verificando Route53...
aws route53 list-resource-record-sets --hosted-zone-id Z07390493BQT3ED4UA3XK --query "ResourceRecordSets[?Type=='A'].[Name,Type,ResourceRecords[0].Value]" --output table

echo.
echo === DIAGNÓSTICO CONCLUÍDO ===
echo.
echo Para acessar o sistema:
echo - IP Direto: http://34.202.149.24
echo - Domínio: http://fourmindstech.com.br
echo - Admin: http://34.202.149.24/admin
echo.
echo Se o sistema não estiver respondendo:
echo 1. Verifique se a chave SSH está disponível
echo 2. Conecte via SSH e verifique os serviços
echo 3. Verifique os logs do Nginx e Django
echo.
pause
