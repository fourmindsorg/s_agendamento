#!/usr/bin/env python3
"""
Script de teste para o sistema de desativação de usuários
Sistema de Agendamento - 4Minds

Este script demonstra o funcionamento completo do sistema de desativação.

Uso:
    python scripts/test_user_deactivation.py
"""

import os
import sys
import subprocess
from pathlib import Path

# Adicionar o diretório raiz do projeto ao Python path
PROJECT_ROOT = Path(__file__).parent.parent
sys.path.insert(0, str(PROJECT_ROOT))


def run_command(command, description):
    """Executa comando e mostra resultado"""
    print(f"\n🔧 {description}")
    print("=" * 60)

    try:
        result = subprocess.run(
            command, cwd=PROJECT_ROOT, capture_output=True, text=True, timeout=30
        )

        if result.returncode == 0:
            print("✅ Comando executado com sucesso!")
            if result.stdout.strip():
                print("\n📋 Saída:")
                print(result.stdout)
        else:
            print("❌ Erro no comando:")
            print(result.stderr)

    except subprocess.TimeoutExpired:
        print("⏰ Comando demorou muito para executar")
    except Exception as e:
        print(f"❌ Erro: {e}")


def main():
    """Função principal de teste"""
    print("🧪 Teste do Sistema de Desativação de Usuários")
    print("=" * 60)

    # Lista de comandos para testar
    test_commands = [
        {
            "command": ["python", "manage.py", "check_user_status"],
            "description": "Verificar status atual dos usuários",
        },
        {
            "command": ["python", "manage.py", "check_user_status", "--expiring-soon"],
            "description": "Verificar usuários próximos do vencimento",
        },
        {
            "command": ["python", "manage.py", "deactivate_expired_users", "--dry-run"],
            "description": "Simular desativação de usuários expirados",
        },
        {
            "command": ["python", "manage.py", "deactivate_expired_users", "--help"],
            "description": "Mostrar ajuda do comando de desativação",
        },
        {
            "command": ["python", "manage.py", "check_user_status", "--help"],
            "description": "Mostrar ajuda do comando de verificação",
        },
        {
            "command": ["python", "manage.py", "reactivate_user", "--help"],
            "description": "Mostrar ajuda do comando de reativação",
        },
    ]

    # Executar todos os testes
    for i, test in enumerate(test_commands, 1):
        print(f"\n📝 Teste {i}/{len(test_commands)}")
        run_command(test["command"], test["description"])

    print("\n🎉 Testes concluídos!")
    print("\n📚 Próximos passos:")
    print("1. Configure o agendamento automático:")
    print("   - Linux/macOS: python scripts/setup_user_deactivation_cron.py")
    print("   - Windows: python scripts/setup_windows_task.py")
    print("2. Monitore regularmente com: python manage.py check_user_status")
    print(
        "3. Execute desativação quando necessário: python manage.py deactivate_expired_users"
    )


if __name__ == "__main__":
    main()
