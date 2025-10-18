#!/usr/bin/env python
"""
Script para configurar o agendamento automático da limpeza de usuários expirados
no Windows Task Scheduler.
"""
import os
import sys
import subprocess
import json
from pathlib import Path


def create_cleanup_script():
    """Cria o script batch para executar a limpeza"""

    # Caminho do projeto
    project_root = Path(__file__).parent.parent
    manage_py = project_root / "manage.py"

    # Script batch para executar a limpeza
    batch_content = f"""@echo off
cd /d "{project_root}"
python "{manage_py}" cleanup_expired_users --days 180
echo Limpeza executada em %date% %time% >> cleanup.log
"""

    batch_file = project_root / "scripts" / "run_cleanup.bat"
    batch_file.write_text(batch_content, encoding="utf-8")

    print(f"Script batch criado: {batch_file}")
    return batch_file


def create_task_scheduler_xml():
    """Cria o arquivo XML para o Task Scheduler"""

    project_root = Path(__file__).parent.parent
    batch_file = project_root / "scripts" / "run_cleanup.bat"

    # XML para o Task Scheduler
    xml_content = f"""<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Description>Limpeza automática de usuários expirados do sistema de agendamentos</Description>
    <Author>Sistema de Agendamentos</Author>
  </RegistrationInfo>
  <Triggers>
    <CalendarTrigger>
      <StartBoundary>2024-01-01T02:00:00</StartBoundary>
      <Enabled>true</Enabled>
      <ScheduleByDay>
        <DaysInterval>1</DaysInterval>
      </ScheduleByDay>
    </CalendarTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <UserId>S-1-5-18</UserId>
      <RunLevel>HighestAvailable</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>true</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <StopOnIdleEnd>true</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>false</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT1H</ExecutionTimeLimit>
    <Priority>7</Priority>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>{batch_file}</Command>
    </Exec>
  </Actions>
</Task>"""

    xml_file = project_root / "scripts" / "cleanup_task.xml"
    xml_file.write_text(xml_content, encoding="utf-8")

    print(f"Arquivo XML criado: {xml_file}")
    return xml_file


def register_task():
    """Registra a tarefa no Task Scheduler"""

    project_root = Path(__file__).parent.parent
    xml_file = project_root / "scripts" / "cleanup_task.xml"

    try:
        # Comando para registrar a tarefa
        cmd = [
            "schtasks",
            "/create",
            "/tn",
            "SistemaAgendamentos_Cleanup",
            "/xml",
            str(xml_file),
            "/f",  # Força a criação mesmo se já existir
        ]

        result = subprocess.run(cmd, capture_output=True, text=True)

        if result.returncode == 0:
            print("✅ Tarefa registrada com sucesso no Task Scheduler!")
            print("A limpeza será executada diariamente às 2:00 AM")
        else:
            print("❌ Erro ao registrar tarefa:")
            print(result.stderr)

    except Exception as e:
        print(f"❌ Erro ao executar comando: {e}")


def test_cleanup():
    """Testa o comando de limpeza em modo dry-run"""

    project_root = Path(__file__).parent.parent
    manage_py = project_root / "manage.py"

    try:
        cmd = [
            "python",
            str(manage_py),
            "cleanup_expired_users",
            "--dry-run",
            "--days",
            "180",
        ]

        print("🧪 Testando comando de limpeza...")
        result = subprocess.run(cmd, cwd=project_root, capture_output=True, text=True)

        if result.returncode == 0:
            print("✅ Comando de limpeza funcionando corretamente!")
            print("Saída:")
            print(result.stdout)
        else:
            print("❌ Erro no comando de limpeza:")
            print(result.stderr)

    except Exception as e:
        print(f"❌ Erro ao testar comando: {e}")


def main():
    """Função principal"""

    print("🔧 Configurando agendamento automático de limpeza...")
    print()

    # 1. Criar script batch
    print("1️⃣ Criando script batch...")
    batch_file = create_cleanup_script()

    # 2. Criar arquivo XML
    print("2️⃣ Criando arquivo XML do Task Scheduler...")
    xml_file = create_task_scheduler_xml()

    # 3. Testar comando
    print("3️⃣ Testando comando de limpeza...")
    test_cleanup()

    # 4. Registrar tarefa
    print("4️⃣ Registrando tarefa no Task Scheduler...")
    register_task()

    print()
    print("✅ Configuração concluída!")
    print()
    print("📋 Resumo:")
    print(f"  - Script batch: {batch_file}")
    print(f"  - Arquivo XML: {xml_file}")
    print("  - Tarefa: SistemaAgendamentos_Cleanup")
    print("  - Frequência: Diariamente às 2:00 AM")
    print("  - Período: 180 dias de inatividade")
    print()
    print("🔍 Para verificar a tarefa:")
    print("  schtasks /query /tn SistemaAgendamentos_Cleanup")
    print()
    print("🗑️ Para executar limpeza manual:")
    print("  python manage.py cleanup_expired_users --dry-run")


if __name__ == "__main__":
    main()
