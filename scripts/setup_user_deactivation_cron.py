#!/usr/bin/env python3
"""
Script para configurar cron job de desativação automática de usuários
Sistema de Agendamento - 4Minds

Este script cria um cron job que executa diariamente o comando de desativação
de usuários que completaram 14 dias de cadastro.

Uso:
    python scripts/setup_user_deactivation_cron.py
"""

import os
import sys
import subprocess
from pathlib import Path

# Adicionar o diretório raiz do projeto ao Python path
PROJECT_ROOT = Path(__file__).parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

# Configurações
CRON_COMMAND = f"cd {PROJECT_ROOT} && python manage.py deactivate_expired_users"
CRON_SCHEDULE = "0 2 * * *"  # Todo dia às 2:00 AM
CRON_LOG = f"{PROJECT_ROOT}/logs/user_deactivation.log"


def create_log_directory():
    """Cria diretório de logs se não existir"""
    log_dir = PROJECT_ROOT / "logs"
    log_dir.mkdir(exist_ok=True)
    return log_dir


def check_cron_installed():
    """Verifica se o cron está instalado no sistema"""
    try:
        subprocess.run(["crontab", "-l"], capture_output=True, check=True)
        return True
    except (subprocess.CalledProcessError, FileNotFoundError):
        return False


def add_cron_job():
    """Adiciona o cron job para desativação de usuários"""
    # Criar diretório de logs
    create_log_directory()

    # Comando completo com redirecionamento de logs
    full_command = f"{CRON_SCHEDULE} {CRON_COMMAND} >> {CRON_LOG} 2>&1"

    try:
        # Obter crontab atual
        result = subprocess.run(["crontab", "-l"], capture_output=True, text=True)
        current_crontab = result.stdout if result.returncode == 0 else ""

        # Verificar se o job já existe
        if "deactivate_expired_users" in current_crontab:
            print("⚠️  Cron job já existe!")
            return True

        # Adicionar novo job
        new_crontab = (
            current_crontab
            + f"\n# Desativação automática de usuários (4Minds)\n{full_command}\n"
        )

        # Aplicar novo crontab
        process = subprocess.Popen(["crontab", "-"], stdin=subprocess.PIPE, text=True)
        process.communicate(input=new_crontab)

        if process.returncode == 0:
            print("✅ Cron job adicionado com sucesso!")
            print(f"📅 Agendado para executar: {CRON_SCHEDULE}")
            print(f"📝 Logs em: {CRON_LOG}")
            return True
        else:
            print("❌ Erro ao adicionar cron job")
            return False

    except Exception as e:
        print(f"❌ Erro: {e}")
        return False


def remove_cron_job():
    """Remove o cron job de desativação de usuários"""
    try:
        # Obter crontab atual
        result = subprocess.run(["crontab", "-l"], capture_output=True, text=True)
        if result.returncode != 0:
            print("⚠️  Nenhum crontab encontrado")
            return True

        current_crontab = result.stdout
        lines = current_crontab.split("\n")

        # Filtrar linhas que não são do nosso job
        new_lines = []
        skip_next = False

        for line in lines:
            if "deactivate_expired_users" in line:
                skip_next = True
                continue
            elif skip_next and line.startswith("#"):
                skip_next = False
                continue
            elif not skip_next:
                new_lines.append(line)

        new_crontab = "\n".join(new_lines)

        # Aplicar novo crontab
        process = subprocess.Popen(["crontab", "-"], stdin=subprocess.PIPE, text=True)
        process.communicate(input=new_crontab)

        if process.returncode == 0:
            print("✅ Cron job removido com sucesso!")
            return True
        else:
            print("❌ Erro ao remover cron job")
            return False

    except Exception as e:
        print(f"❌ Erro: {e}")
        return False


def show_cron_status():
    """Mostra status dos cron jobs"""
    try:
        result = subprocess.run(["crontab", "-l"], capture_output=True, text=True)
        if result.returncode != 0:
            print("⚠️  Nenhum crontab encontrado")
            return

        crontab_content = result.stdout
        if "deactivate_expired_users" in crontab_content:
            print("✅ Cron job de desativação está ativo")
            lines = crontab_content.split("\n")
            for line in lines:
                if "deactivate_expired_users" in line:
                    print(f"📅 Agendamento: {line}")
        else:
            print("❌ Cron job de desativação não encontrado")

    except Exception as e:
        print(f"❌ Erro ao verificar status: {e}")


def main():
    """Função principal"""
    print("🔧 Configurador de Cron Job - Desativação de Usuários")
    print("=" * 60)

    if not check_cron_installed():
        print("❌ Cron não está instalado ou não está disponível")
        print("💡 Instale o cron no seu sistema:")
        print("   Ubuntu/Debian: sudo apt-get install cron")
        print("   CentOS/RHEL: sudo yum install cronie")
        print("   macOS: Cron está incluído por padrão")
        return

    print("Escolha uma opção:")
    print("1. Adicionar cron job")
    print("2. Remover cron job")
    print("3. Verificar status")
    print("4. Sair")

    choice = input("\nDigite sua escolha (1-4): ").strip()

    if choice == "1":
        add_cron_job()
    elif choice == "2":
        remove_cron_job()
    elif choice == "3":
        show_cron_status()
    elif choice == "4":
        print("👋 Até logo!")
    else:
        print("❌ Opção inválida")


if __name__ == "__main__":
    main()
