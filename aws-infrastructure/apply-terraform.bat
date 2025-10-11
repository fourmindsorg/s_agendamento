@echo off
echo ╔════════════════════════════════════════════════════════════╗
echo ║         EXECUTANDO TERRAFORM APPLY                         ║
echo ╚════════════════════════════════════════════════════════════╝
echo.
echo ⏱️  Tempo estimado: 10-15 minutos
echo ☕ Aguarde enquanto criamos a infraestrutura...
echo.

terraform apply -auto-approve

echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║         DEPLOY CONCLUÍDO                                   ║
echo ╚════════════════════════════════════════════════════════════╝
echo.
echo 📊 Obtendo informações da infraestrutura...
echo.

terraform output

echo.
echo ✅ Processo completo!
echo.
pause

