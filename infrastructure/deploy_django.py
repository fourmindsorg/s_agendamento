#!/usr/bin/env python3
"""
Script para deploy da aplicação Django na instância EC2
"""

import json
import subprocess
import sys
import os
import time
from pathlib import Path


class DjangoDeployer:
    def __init__(self):
        self.terraform_dir = Path(__file__).parent
        self.project_root = self.terraform_dir.parent
        self.info = {}
        self.key_path = "s-agendamento-key.pem"

    def load_infrastructure_info(self):
        """Carrega informações da infraestrutura"""
        info_file = self.terraform_dir / "infrastructure_info.json"
        if not info_file.exists():
            print("❌ Arquivo de informações da infraestrutura não encontrado")
            print("Execute primeiro: python collect_infrastructure_info.py")
            return False

        with open(info_file, "r", encoding="utf-8") as f:
            self.info = json.load(f)

        return True

    def check_ssh_key(self):
        """Verifica se a chave SSH existe"""
        key_file = self.terraform_dir / self.key_path
        if not key_file.exists():
            print(f"❌ Chave SSH não encontrada: {key_file}")
            print("Coloque a chave SSH no diretório infrastructure/")
            return False

        # Definir permissões corretas
        os.chmod(key_file, 0o600)
        return True

    def check_instance_status(self):
        """Verifica status da instância"""
        instance_id = self.info.get("instance_id", {}).get("value", "")
        if not instance_id:
            print("❌ Instance ID não encontrado")
            return False

        print(f"🔍 Verificando status da instância: {instance_id}")

        try:
            cmd = [
                "aws",
                "ec2",
                "describe-instances",
                "--instance-ids",
                instance_id,
                "--query",
                "Reservations[0].Instances[0].State.Name",
                "--output",
                "text",
            ]
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            state = result.stdout.strip()

            if state == "running":
                print("✅ Instância está rodando")
                return True
            else:
                print(f"❌ Instância não está rodando. Estado: {state}")
                return False

        except subprocess.CalledProcessError as e:
            print(f"❌ Erro ao verificar status da instância: {e}")
            return False

    def wait_for_instance(self):
        """Aguarda a instância estar pronta"""
        instance_id = self.info.get("instance_id", {}).get("value", "")
        print(f"⏳ Aguardando instância estar pronta: {instance_id}")

        try:
            cmd = [
                "aws",
                "ec2",
                "wait",
                "instance-running",
                "--instance-ids",
                instance_id,
            ]
            subprocess.run(cmd, check=True)
            print("✅ Instância está pronta")
            return True
        except subprocess.CalledProcessError as e:
            print(f"❌ Erro ao aguardar instância: {e}")
            return False

    def prepare_deploy_package(self):
        """Prepara pacote de deploy"""
        print("📦 Preparando pacote de deploy...")

        deploy_dir = self.terraform_dir / "deploy_package"
        if deploy_dir.exists():
            import shutil

            shutil.rmtree(deploy_dir)
        deploy_dir.mkdir()

        # Copiar arquivos necessários
        files_to_copy = [
            "agendamentos",
            "authentication",
            "core",
            "financeiro",
            "info",
            "templates",
            "manage.py",
            "requirements.txt",
            ".env",
        ]

        for item in files_to_copy:
            src = self.project_root / item
            dst = deploy_dir / item

            if src.is_dir():
                import shutil

                shutil.copytree(src, dst)
            elif src.exists():
                import shutil

                shutil.copy2(src, dst)

        # Copiar static se existir
        static_src = self.project_root / "static"
        if static_src.exists():
            import shutil

            shutil.copytree(static_src, deploy_dir / "static")

        print("✅ Pacote de deploy preparado")
        return True

    def create_init_script(self):
        """Cria script de inicialização"""
        print("📝 Criando script de inicialização...")

        init_script = """#!/bin/bash

# Script de inicialização do Django na EC2
set -e

echo "🚀 Iniciando deploy do Django..."

# Atualizar sistema
echo "📦 Atualizando sistema..."
sudo apt-get update -y
sudo apt-get upgrade -y

# Instalar dependências do sistema
echo "🔧 Instalando dependências..."
sudo apt-get install -y python3 python3-pip python3-venv postgresql-client nginx supervisor curl

# Criar usuário para a aplicação
echo "👤 Configurando usuário..."
sudo useradd -m -s /bin/bash django 2>/dev/null || true
sudo usermod -aG sudo django

# Criar diretório da aplicação
echo "📁 Criando diretórios..."
sudo mkdir -p /opt/s-agendamento
sudo chown django:django /opt/s-agendamento

# Copiar arquivos da aplicação
echo "📋 Copiando arquivos..."
sudo cp -r /tmp/s-agendamento/* /opt/s-agendamento/
sudo chown -R django:django /opt/s-agendamento

# Instalar dependências Python
echo "🐍 Instalando dependências Python..."
cd /opt/s-agendamento
sudo -u django python3 -m venv venv
sudo -u django /opt/s-agendamento/venv/bin/pip install --upgrade pip
sudo -u django /opt/s-agendamento/venv/bin/pip install -r requirements.txt

# Executar migrações
echo "🗄️ Executando migrações..."
sudo -u django /opt/s-agendamento/venv/bin/python manage.py migrate

# Coletar arquivos estáticos
echo "📦 Coletando arquivos estáticos..."
sudo -u django /opt/s-agendamento/venv/bin/python manage.py collectstatic --noinput

# Criar superusuário (se não existir)
echo "👤 Configurando superusuário..."
sudo -u django /opt/s-agendamento/venv/bin/python manage.py shell -c "
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser('admin', 'admin@fourmindstech.com.br', 'admin123')
    print('Superusuário criado: admin/admin123')
else:
    print('Superusuário já existe')
"

# Configurar Nginx
echo "🌐 Configurando Nginx..."
sudo tee /etc/nginx/sites-available/s-agendamento << 'NGINX_EOF'
server {
    listen 80;
    server_name _;

    location /static/ {
        alias /opt/s-agendamento/staticfiles/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    location /media/ {
        alias /opt/s-agendamento/media/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
NGINX_EOF

# Ativar site do Nginx
sudo ln -sf /etc/nginx/sites-available/s-agendamento /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx
sudo systemctl enable nginx

# Configurar Supervisor
echo "🔧 Configurando Supervisor..."
sudo tee /etc/supervisor/conf.d/s-agendamento.conf << 'SUPERVISOR_EOF'
[program:s-agendamento]
command=/opt/s-agendamento/venv/bin/gunicorn --bind 127.0.0.1:8000 core.wsgi:application
directory=/opt/s-agendamento
user=django
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/var/log/supervisor/s-agendamento.log
stderr_logfile=/var/log/supervisor/s-agendamento-error.log
environment=PATH="/opt/s-agendamento/venv/bin"
SUPERVISOR_EOF

# Reiniciar Supervisor
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start s-agendamento

# Aguardar aplicação iniciar
echo "⏳ Aguardando aplicação iniciar..."
sleep 10

# Verificar se está funcionando
if curl -f http://localhost:8000 > /dev/null 2>&1; then
    echo "✅ Django deployado com sucesso!"
    echo "🌐 Acesse: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
    echo "👤 Admin: admin/admin123"
else
    echo "❌ Erro: Aplicação não está respondendo"
    echo "Verifique os logs: sudo supervisorctl tail -f s-agendamento"
    exit 1
fi
"""

        init_file = self.terraform_dir / "deploy_package" / "init_django.sh"
        with open(init_file, "w", encoding="utf-8") as f:
            f.write(init_script)

        # Tornar executável
        os.chmod(init_file, 0o755)

        print("✅ Script de inicialização criado")
        return True

    def copy_files_to_instance(self):
        """Copia arquivos para a instância"""
        instance_ip = self.info.get("instance_public_ip", {}).get("value", "")
        if not instance_ip:
            print("❌ IP da instância não encontrado")
            return False

        print(f"📤 Copiando arquivos para a instância: {instance_ip}")

        try:
            cmd = [
                "scp",
                "-i",
                self.key_path,
                "-r",
                "deploy_package/*",
                f"ubuntu@{instance_ip}:/tmp/s-agendamento/",
            ]
            subprocess.run(cmd, cwd=self.terraform_dir, check=True)
            print("✅ Arquivos copiados com sucesso")
            return True
        except subprocess.CalledProcessError as e:
            print(f"❌ Erro ao copiar arquivos: {e}")
            return False

    def execute_init_script(self):
        """Executa script de inicialização na instância"""
        instance_ip = self.info.get("instance_public_ip", {}).get("value", "")
        if not instance_ip:
            print("❌ IP da instância não encontrado")
            return False

        print(f"🚀 Executando script de inicialização na instância: {instance_ip}")

        try:
            cmd = [
                "ssh",
                "-i",
                self.key_path,
                f"ubuntu@{instance_ip}",
                "sudo bash /tmp/s-agendamento/init_django.sh",
            ]
            subprocess.run(cmd, cwd=self.terraform_dir, check=True)
            print("✅ Script de inicialização executado com sucesso")
            return True
        except subprocess.CalledProcessError as e:
            print(f"❌ Erro ao executar script de inicialização: {e}")
            return False

    def test_deployment(self):
        """Testa se o deployment foi bem-sucedido"""
        instance_ip = self.info.get("instance_public_ip", {}).get("value", "")
        if not instance_ip:
            print("❌ IP da instância não encontrado")
            return False

        print(f"🧪 Testando deployment: http://{instance_ip}")

        try:
            import requests

            response = requests.get(f"http://{instance_ip}", timeout=30)
            if response.status_code == 200:
                print("✅ Deployment testado com sucesso!")
                return True
            else:
                print(f"❌ Erro no teste: Status {response.status_code}")
                return False
        except ImportError:
            print("⚠️ requests não disponível, pulando teste")
            return True
        except Exception as e:
            print(f"❌ Erro no teste: {e}")
            return False

    def print_deployment_info(self):
        """Imprime informações do deployment"""
        instance_ip = self.info.get("instance_public_ip", {}).get("value", "")
        instance_dns = self.info.get("instance_public_dns", {}).get("value", "")

        print("\n" + "=" * 60)
        print("🎉 DEPLOYMENT CONCLUÍDO COM SUCESSO!")
        print("=" * 60)

        print(f"🌐 URLs de Acesso:")
        print(f"   - Website: http://{instance_ip}")
        print(f"   - Admin: http://{instance_ip}/admin/")
        print(f"   - API: http://{instance_ip}/api/")

        if instance_dns:
            print(f"   - DNS: http://{instance_dns}")

        print(f"\n👤 Credenciais de Acesso:")
        print(f"   - Usuário: admin")
        print(f"   - Senha: admin123")

        print(f"\n🔧 Comandos Úteis:")
        print(f"   - SSH: ssh -i {self.key_path} ubuntu@{instance_ip}")
        print(f"   - Logs: sudo supervisorctl tail -f s-agendamento")
        print(f"   - Restart: sudo supervisorctl restart s-agendamento")
        print(f"   - Status: sudo supervisorctl status s-agendamento")

        print("\n✅ Sistema de Agendamento 4Minds está online!")
        print("=" * 60)

    def cleanup(self):
        """Limpa arquivos temporários"""
        print("🧹 Limpando arquivos temporários...")

        deploy_dir = self.terraform_dir / "deploy_package"
        if deploy_dir.exists():
            import shutil

            shutil.rmtree(deploy_dir)

        print("✅ Limpeza concluída")

    def run(self):
        """Executa o processo completo de deploy"""
        print("🚀 Iniciando deploy do Django...")

        # Carregar informações da infraestrutura
        if not self.load_infrastructure_info():
            return False

        # Verificar chave SSH
        if not self.check_ssh_key():
            return False

        # Verificar status da instância
        if not self.check_instance_status():
            return False

        # Aguardar instância estar pronta
        if not self.wait_for_instance():
            return False

        # Preparar pacote de deploy
        if not self.prepare_deploy_package():
            return False

        # Criar script de inicialização
        if not self.create_init_script():
            return False

        # Copiar arquivos para a instância
        if not self.copy_files_to_instance():
            return False

        # Executar script de inicialização
        if not self.execute_init_script():
            return False

        # Testar deployment
        self.test_deployment()

        # Imprimir informações
        self.print_deployment_info()

        # Limpar arquivos temporários
        self.cleanup()

        return True


def main():
    deployer = DjangoDeployer()
    success = deployer.run()

    if success:
        print("\n✅ Deploy concluído com sucesso!")
        sys.exit(0)
    else:
        print("\n❌ Erro no deploy!")
        sys.exit(1)


if __name__ == "__main__":
    main()
