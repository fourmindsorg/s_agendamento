#!/usr/bin/env python3
"""
Script principal para deploy completo do Sistema de Agendamento 4Minds
Este script orquestra todo o processo:
1. Coleta informações da infraestrutura
2. Atualiza configurações
3. Realiza deploy do Django
"""

import sys
import subprocess
from pathlib import Path


class DeployOrchestrator:
    def __init__(self):
        self.terraform_dir = Path(__file__).parent
        self.scripts = {
            "collect_info": self.terraform_dir / "collect_infrastructure_info.py",
            "deploy_django": self.terraform_dir / "deploy_django.py",
        }

    def run_script(self, script_name, description):
        """Executa um script Python"""
        script_path = self.scripts.get(script_name)
        if not script_path or not script_path.exists():
            print(f"❌ Script não encontrado: {script_name}")
            return False

        print(f"\n{'='*60}")
        print(f"🚀 {description}")
        print(f"{'='*60}")

        try:
            result = subprocess.run([sys.executable, str(script_path)], check=True)
            print(f"✅ {description} - Concluído com sucesso!")
            return True
        except subprocess.CalledProcessError as e:
            print(f"❌ Erro em {description}: {e}")
            return False

    def check_prerequisites(self):
        """Verifica pré-requisitos"""
        print("🔍 Verificando pré-requisitos...")

        # Verificar se estamos no diretório correto
        if not (self.terraform_dir / "main.tf").exists():
            print("❌ Execute este script no diretório infrastructure/")
            return False

        # Verificar se o Terraform está disponível
        try:
            subprocess.run(["terraform", "version"], check=True, capture_output=True)
            print("✅ Terraform disponível")
        except (subprocess.CalledProcessError, FileNotFoundError):
            print("❌ Terraform não encontrado. Instale o Terraform primeiro.")
            return False

        # Verificar se o AWS CLI está disponível
        try:
            subprocess.run(["aws", "--version"], check=True, capture_output=True)
            print("✅ AWS CLI disponível")
        except (subprocess.CalledProcessError, FileNotFoundError):
            print(
                "⚠️ AWS CLI não encontrado. Algumas funcionalidades podem não funcionar."
            )

        # Verificar se o SSH está disponível
        try:
            subprocess.run(["ssh", "-V"], check=True, capture_output=True)
            print("✅ SSH disponível")
        except (subprocess.CalledProcessError, FileNotFoundError):
            print("❌ SSH não encontrado. Necessário para deploy.")
            return False

        print("✅ Pré-requisitos verificados!")
        return True

    def run_terraform_apply(self):
        """Executa terraform apply se necessário"""
        print("\n🔧 Verificando se a infraestrutura precisa ser criada...")

        try:
            # Verificar se há recursos no estado
            result = subprocess.run(
                ["terraform", "state", "list"],
                cwd=self.terraform_dir,
                capture_output=True,
                text=True,
            )

            if result.returncode == 0 and result.stdout.strip():
                print("✅ Infraestrutura já existe")
                return True
            else:
                print("🏗️ Criando infraestrutura...")
                subprocess.run(
                    ["terraform", "apply", "-auto-approve"],
                    cwd=self.terraform_dir,
                    check=True,
                )
                print("✅ Infraestrutura criada com sucesso!")
                return True

        except subprocess.CalledProcessError as e:
            print(f"❌ Erro ao verificar/criar infraestrutura: {e}")
            return False

    def run(self):
        """Executa o processo completo de deploy"""
        print("🚀 Iniciando deploy completo do Sistema de Agendamento 4Minds")
        print("=" * 80)

        # Verificar pré-requisitos
        if not self.check_prerequisites():
            return False

        # Criar/aplicar infraestrutura
        if not self.run_terraform_apply():
            return False

        # Coletar informações da infraestrutura
        if not self.run_script(
            "collect_info", "Coletando informações da infraestrutura"
        ):
            return False

        # Realizar deploy do Django
        if not self.run_script("deploy_django", "Realizando deploy do Django"):
            return False

        # Sucesso!
        print("\n" + "=" * 80)
        print("🎉 DEPLOY COMPLETO REALIZADO COM SUCESSO!")
        print("=" * 80)
        print("✅ Infraestrutura AWS criada")
        print("✅ Configurações atualizadas")
        print("✅ Django deployado e funcionando")
        print("\n🌐 Seu sistema está online e pronto para uso!")
        print("=" * 80)

        return True


def main():
    orchestrator = DeployOrchestrator()
    success = orchestrator.run()

    if success:
        print("\n✅ Deploy completo concluído com sucesso!")
        sys.exit(0)
    else:
        print("\n❌ Erro no deploy completo!")
        sys.exit(1)


if __name__ == "__main__":
    main()
