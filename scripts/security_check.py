#!/usr/bin/env python3
"""
Script de Verificação de Segurança
Verifica se há credenciais sensíveis expostas no código
"""

import os
import re
import sys
from pathlib import Path

# Padrões de credenciais sensíveis
SENSITIVE_PATTERNS = [
    # Chaves API Asaas
    r"aact_[a-zA-Z0-9]{50,}",
    r"sk_live_[a-zA-Z0-9]{20,}",
    r"sk_test_[a-zA-Z0-9]{20,}",
    # Senhas de banco
    r'password\s*=\s*["\'][^"\']{8,}["\']',
    r'DB_PASSWORD\s*=\s*["\'][^"\']{8,}["\']',
    # Tokens de webhook
    r'webhook_token\s*=\s*["\'][a-zA-Z0-9\-]{20,}["\']',
    # Chaves secretas Django
    r'SECRET_KEY\s*=\s*["\'][a-zA-Z0-9]{50,}["\']',
]

# Arquivos e diretórios a ignorar
IGNORE_PATTERNS = [
    ".git/",
    "__pycache__/",
    ".pytest_cache/",
    "node_modules/",
    ".env",
    "terraform.tfvars",
    ".tfstate",
    "SECURITY.md",
    "security_check.py",
]


def should_ignore_file(file_path):
    """Verifica se o arquivo deve ser ignorado"""
    file_str = str(file_path)
    return any(pattern in file_str for pattern in IGNORE_PATTERNS)


def check_file(file_path):
    """Verifica um arquivo em busca de credenciais sensíveis"""
    issues = []

    try:
        with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
            content = f.read()

        for i, line in enumerate(content.split("\n"), 1):
            for pattern in SENSITIVE_PATTERNS:
                if re.search(pattern, line, re.IGNORECASE):
                    issues.append(
                        {
                            "file": str(file_path),
                            "line": i,
                            "content": line.strip(),
                            "pattern": pattern,
                        }
                    )
    except Exception as e:
        print(f"Erro ao ler arquivo {file_path}: {e}")

    return issues


def main():
    """Função principal"""
    print("🔍 Verificando segurança do projeto...")
    print("=" * 50)

    project_root = Path(".")
    all_issues = []

    # Percorre todos os arquivos do projeto
    for file_path in project_root.rglob("*"):
        if file_path.is_file() and not should_ignore_file(file_path):
            issues = check_file(file_path)
            all_issues.extend(issues)

    # Relatório
    if all_issues:
        print(f"❌ ENCONTRADAS {len(all_issues)} POSSÍVEIS VULNERABILIDADES:")
        print()

        for issue in all_issues:
            print(f"📁 Arquivo: {issue['file']}")
            print(f"📍 Linha: {issue['line']}")
            print(f"🔍 Padrão: {issue['pattern']}")
            print(f"📝 Conteúdo: {issue['content']}")
            print("-" * 30)

        print("\n⚠️  AÇÕES RECOMENDADAS:")
        print("1. Remova ou substitua as credenciais expostas")
        print("2. Use variáveis de ambiente para credenciais sensíveis")
        print("3. Verifique se os arquivos estão no .gitignore")
        print("4. Considere rotacionar as chaves expostas")

        return 1
    else:
        print("✅ Nenhuma credencial sensível encontrada!")
        print("✅ Projeto parece seguro para commit.")
        return 0


if __name__ == "__main__":
    sys.exit(main())
