@echo off
echo ========================================
echo Testando Pipeline CI/CD
echo ========================================

echo.
echo [1/6] Verificando Python...
python --version
if %errorlevel% neq 0 (
    echo ERRO: Python nao encontrado
    exit /b 1
)
echo OK: Python funcionando

echo.
echo [2/6] Verificando Git...
git --version
if %errorlevel% neq 0 (
    echo ERRO: Git nao encontrado
    exit /b 1
)
echo OK: Git funcionando

echo.
echo [3/6] Verificando AWS CLI...
aws --version
if %errorlevel% neq 0 (
    echo ERRO: AWS CLI nao encontrado
    exit /b 1
)
echo OK: AWS CLI funcionando

echo.
echo [4/6] Testando credenciais AWS...
aws sts get-caller-identity
if %errorlevel% neq 0 (
    echo ERRO: Credenciais AWS invalidas
    exit /b 1
)
echo OK: Credenciais AWS funcionando

echo.
echo [5/6] Verificando GitHub CLI...
gh --version
if %errorlevel% neq 0 (
    echo ERRO: GitHub CLI nao encontrado
    exit /b 1
)
echo OK: GitHub CLI funcionando

echo.
echo [6/6] Testando Django...
python manage.py check
if %errorlevel% neq 0 (
    echo ERRO: Django com problemas
    exit /b 1
)
echo OK: Django funcionando

echo.
echo ========================================
echo TODOS OS TESTES PASSARAM!
echo ========================================
echo.
echo Proximos passos:
echo 1. Configure os GitHub Secrets
echo 2. Execute: git add . && git commit -m "Deploy" && git push
echo.
pause
