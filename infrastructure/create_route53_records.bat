@echo off
echo === CRIANDO REGISTROS ROUTE53 ===

REM Configurações
set DOMAIN=fourmindstech.com.br
set EC2_IP=34.202.149.24
set HOSTED_ZONE_ID=

echo 1. Listando hosted zones disponíveis...
aws route53 list-hosted-zones --query "HostedZones[*].[Id,Name]" --output table

echo.
echo 2. Para continuar, você precisa:
echo    - ID da hosted zone para %DOMAIN%
echo    - Confirmar que o domínio está configurado no Route53

echo.
echo 3. Exemplo de comando para criar registro A:
echo aws route53 change-resource-record-sets --hosted-zone-id Z1234567890 --change-batch file://route53-change.json

echo.
echo 4. Criando arquivo de configuração Route53...

REM Criar arquivo JSON para o Route53
echo { > route53-change.json
echo   "Comment": "Criando registro A para %DOMAIN%", >> route53-change.json
echo   "Changes": [ >> route53-change.json
echo     { >> route53-change.json
echo       "Action": "UPSERT", >> route53-change.json
echo       "ResourceRecordSet": { >> route53-change.json
echo         "Name": "%DOMAIN%", >> route53-change.json
echo         "Type": "A", >> route53-change.json
echo         "TTL": 300, >> route53-change.json
echo         "ResourceRecords": [ >> route53-change.json
echo           { >> route53-change.json
echo             "Value": "%EC2_IP%" >> route53-change.json
echo           } >> route53-change.json
echo         ] >> route53-change.json
echo       } >> route53-change.json
echo     }, >> route53-change.json
echo     { >> route53-change.json
echo       "Action": "UPSERT", >> route53-change.json
echo       "ResourceRecordSet": { >> route53-change.json
echo         "Name": "www.%DOMAIN%", >> route53-change.json
echo         "Type": "A", >> route53-change.json
echo         "TTL": 300, >> route53-change.json
echo         "ResourceRecords": [ >> route53-change.json
echo           { >> route53-change.json
echo             "Value": "%EC2_IP%" >> route53-change.json
echo           } >> route53-change.json
echo         ] >> route53-change.json
echo       } >> route53-change.json
echo     } >> route53-change.json
echo   ] >> route53-change.json
echo } >> route53-change.json

echo.
echo Arquivo route53-change.json criado!
echo.
echo Para aplicar as mudanças:
echo 1. Obtenha o ID da hosted zone
echo 2. Execute: aws route53 change-resource-record-sets --hosted-zone-id [ZONE_ID] --change-batch file://route53-change.json

echo.
echo === CONFIGURAÇÃO ROUTE53 PRONTA ===
pause
