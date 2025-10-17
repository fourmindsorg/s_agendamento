#!/usr/bin/env python3
"""
Script para configurar Task Scheduler do Windows para desativação automática de usuários
Sistema de Agendamento - 4Minds

Este script cria uma tarefa agendada que executa diariamente o comando de desativação
de usuários que completaram 14 dias de cadastro.

Uso:
    python scripts/setup_windows_task.py
"""

import os
import sys
import subprocess
import json
from pathlib import Path
from datetime import datetime

# Adicionar o diretório raiz do projeto ao Python path
PROJECT_ROOT = Path(__file__).parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

# Configurações
TASK_NAME = "4Minds-UserDeactivation"
TASK_DESCRIPTION = "Desativação automática de usuários após 14 dias de cadastro"
PYTHON_EXE = sys.executable
MANAGE_PY = PROJECT_ROOT / "manage.py"
LOG_DIR = PROJECT_ROOT / "logs"
LOG_FILE = LOG_DIR / "user_deactivation.log"


def create_log_directory():
    """Cria diretório de logs se não existir"""
    LOG_DIR.mkdir(exist_ok=True)
    return LOG_DIR


def run_powershell_command(command):
    """Executa comando PowerShell e retorna resultado"""
    try:
        result = subprocess.run(
            ["powershell", "-Command", command],
            capture_output=True,
            text=True,
            check=True,
        )
        return True, result.stdout
    except subprocess.CalledProcessError as e:
        return False, e.stderr


def check_task_exists():
    """Verifica se a tarefa já existe"""
    command = f"Get-ScheduledTask -TaskName '{TASK_NAME}' -ErrorAction SilentlyContinue"
    success, output = run_powershell_command(command)
    return success and TASK_NAME in output


def create_task():
    """Cria a tarefa agendada"""
    # Criar diretório de logs
    create_log_directory()

    # Comando para executar
    action_command = f'"{PYTHON_EXE}" "{MANAGE_PY}" deactivate_expired_users'

    # Script PowerShell para criar a tarefa
    ps_script = f"""
$Action = New-ScheduledTaskAction -Execute "{PYTHON_EXE}" -Argument '"{MANAGE_PY}" deactivate_expired_users' -WorkingDirectory "{PROJECT_ROOT}"
$Trigger = New-ScheduledTaskTrigger -Daily -At 2:00AM
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
$Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

Register-ScheduledTask -TaskName "{TASK_NAME}" -Action $Action -Trigger $Trigger -Settings $Settings -Principal $Principal -Description "{TASK_DESCRIPTION}"
"""

    success, output = run_powershell_command(ps_script)

    if success:
        print("✅ Tarefa agendada criada com sucesso!")
        print(f"📅 Nome: {TASK_NAME}")
        print(f"⏰ Agendamento: Diariamente às 2:00 AM")
        print(f"📝 Logs em: {LOG_FILE}")
        return True
    else:
        print(f"❌ Erro ao criar tarefa: {output}")
        return False


def delete_task():
    """Remove a tarefa agendada"""
    command = f"Unregister-ScheduledTask -TaskName '{TASK_NAME}' -Confirm:$false"
    success, output = run_powershell_command(command)

    if success:
        print("✅ Tarefa agendada removida com sucesso!")
        return True
    else:
        print(f"❌ Erro ao remover tarefa: {output}")
        return False


def show_task_status():
    """Mostra status da tarefa"""
    if not check_task_exists():
        print("❌ Tarefa não encontrada")
        return

    # Obter informações da tarefa
    command = f"Get-ScheduledTask -TaskName '{TASK_NAME}' | Get-ScheduledTaskInfo"
    success, output = run_powershell_command(command)

    if success:
        print("✅ Tarefa encontrada:")
        print(output)
    else:
        print(f"❌ Erro ao obter informações: {output}")


def run_task_now():
    """Executa a tarefa imediatamente"""
    command = f"Start-ScheduledTask -TaskName '{TASK_NAME}'"
    success, output = run_powershell_command(command)

    if success:
        print("✅ Tarefa executada com sucesso!")
        print("📝 Verifique os logs para detalhes")
    else:
        print(f"❌ Erro ao executar tarefa: {output}")


def test_command():
    """Testa o comando de desativação"""
    print("🧪 Testando comando de desativação...")

    try:
        # Executar comando em modo dry-run
        result = subprocess.run(
            [str(PYTHON_EXE), str(MANAGE_PY), "deactivate_expired_users", "--dry-run"],
            cwd=PROJECT_ROOT,
            capture_output=True,
            text=True,
            timeout=30,
        )

        if result.returncode == 0:
            print("✅ Comando executado com sucesso!")
            print("📋 Saída:")
            print(result.stdout)
        else:
            print(f"❌ Erro no comando: {result.stderr}")

    except subprocess.TimeoutExpired:
        print("⏰ Comando demorou muito para executar")
    except Exception as e:
        print(f"❌ Erro: {e}")


def main():
    """Função principal"""
    print("🔧 Configurador de Task Scheduler - Desativação de Usuários")
    print("=" * 60)

    # Verificar se estamos no Windows
    if os.name != "nt":
        print("❌ Este script é específico para Windows")
        print("💡 Use o script setup_user_deactivation_cron.py para Linux/macOS")
        return

    print("Escolha uma opção:")
    print("1. Criar tarefa agendada")
    print("2. Remover tarefa agendada")
    print("3. Verificar status da tarefa")
    print("4. Executar tarefa agora")
    print("5. Testar comando de desativação")
    print("6. Sair")

    choice = input("\nDigite sua escolha (1-6): ").strip()

    if choice == "1":
        if check_task_exists():
            print("⚠️  Tarefa já existe!")
            overwrite = input("Deseja recriar? (s/N): ").lower().strip()
            if overwrite in ["s", "sim", "y", "yes"]:
                delete_task()
                create_task()
        else:
            create_task()
    elif choice == "2":
        delete_task()
    elif choice == "3":
        show_task_status()
    elif choice == "4":
        run_task_now()
    elif choice == "5":
        test_command()
    elif choice == "6":
        print("👋 Até logo!")
    else:
        print("❌ Opção inválida")


if __name__ == "__main__":
    main()
