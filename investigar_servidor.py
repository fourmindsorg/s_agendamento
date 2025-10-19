#!/usr/bin/env python3
"""
Script para investigar a estrutura do servidor
"""
import subprocess
import sys


def executar_comando_ssh(comando):
    """Executa comando SSH e retorna resultado"""
    try:
        cmd = f'ssh -i s_agendametnos_key_pairs_AWS.pem ubuntu@3.80.178.120 "{comando}"'
        result = subprocess.run(
            cmd, shell=True, capture_output=True, text=True, timeout=30
        )
        return result.returncode == 0, result.stdout, result.stderr
    except Exception as e:
        return False, "", str(e)


def main():
    print("🔍 INVESTIGANDO ESTRUTURA DO SERVIDOR")
    print("=" * 50)

    # Comandos para investigar
    comandos = [
        "ls -la /",
        "ls -la /opt/",
        "ls -la /home/",
        "ls -la /var/www/",
        "find / -name '*sistema*' -type d 2>/dev/null | head -10",
        "find / -name '*agendamento*' -type d 2>/dev/null | head -10",
        "ps aux | grep -E '(django|gunicorn|nginx)' | head -5",
        "systemctl list-units --type=service | grep -E '(django|gunicorn|nginx)'",
        "which python3",
        "which git",
    ]

    for i, comando in enumerate(comandos, 1):
        print(f"\n{i}. Executando: {comando}")
        print("-" * 40)

        sucesso, stdout, stderr = executar_comando_ssh(comando)

        if sucesso:
            if stdout.strip():
                print("✅ Sucesso:")
                print(stdout.strip())
            else:
                print("✅ Comando executado (sem saída)")
        else:
            print("❌ Erro:")
            if stderr.strip():
                print(stderr.strip())
            else:
                print("Comando falhou sem mensagem de erro")

    print("\n" + "=" * 50)
    print("🔧 PRÓXIMOS PASSOS:")
    print("1. Verificar onde está o código do sistema")
    print("2. Verificar se os serviços estão configurados")
    print("3. Corrigir o workflow com o caminho correto")


if __name__ == "__main__":
    main()
