#!/usr/bin/env python3
"""
Script para coletar informações da infraestrutura AWS
e atualizar configurações do sistema automaticamente
"""

import json
import subprocess
import sys
import os
from pathlib import Path


class InfrastructureInfoCollector:
    def __init__(self):
        self.terraform_dir = Path(__file__).parent
        self.project_root = self.terraform_dir.parent
        self.info = {}

    def run_terraform_command(self, command):
        """Executa comando do Terraform e retorna resultado"""
        try:
            result = subprocess.run(
                command,
                cwd=self.terraform_dir,
                capture_output=True,
                text=True,
                check=True,
            )
            return result.stdout.strip()
        except subprocess.CalledProcessError as e:
            print(f"Erro ao executar comando Terraform: {e}")
            return None

    def collect_terraform_outputs(self):
        """Coleta outputs do Terraform"""
        print("📊 Coletando outputs do Terraform...")

        # Verificar se o Terraform está inicializado
        if not (self.terraform_dir / ".terraform").exists():
            print("Inicializando Terraform...")
            self.run_terraform_command(["terraform", "init"])

        # Coletar outputs em JSON
        outputs_json = self.run_terraform_command(["terraform", "output", "-json"])
        if not outputs_json:
            print("❌ Erro: Não foi possível coletar outputs do Terraform")
            return False

        try:
            outputs = json.loads(outputs_json)
            self.info.update(outputs)
            print("✅ Outputs do Terraform coletados com sucesso")
            return True
        except json.JSONDecodeError as e:
            print(f"❌ Erro ao decodificar JSON: {e}")
            return False

    def collect_aws_info(self):
        """Coleta informações adicionais da AWS"""
        print("🔍 Coletando informações adicionais da AWS...")

        try:
            # Verificar se AWS CLI está disponível
            subprocess.run(["aws", "--version"], check=True, capture_output=True)

            # Coletar informações da instância
            instance_id = self.info.get("instance_id", {}).get("value", "")
            if instance_id:
                # Status da instância
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
                state = self.run_terraform_command(cmd)
                if state:
                    self.info["instance_state"] = {"value": state}

                # Informações de rede
                cmd = [
                    "aws",
                    "ec2",
                    "describe-instances",
                    "--instance-ids",
                    instance_id,
                    "--query",
                    "Reservations[0].Instances[0].PublicIpAddress",
                    "--output",
                    "text",
                ]
                public_ip = self.run_terraform_command(cmd)
                if public_ip:
                    self.info["instance_public_ip_aws"] = {"value": public_ip}

            print("✅ Informações da AWS coletadas com sucesso")
            return True

        except (subprocess.CalledProcessError, FileNotFoundError):
            print("⚠️ AWS CLI não disponível, pulando coleta de informações adicionais")
            return True

    def update_env_file(self):
        """Atualiza arquivo .env com as informações coletadas"""
        print("⚙️ Atualizando arquivo .env...")

        instance_ip = self.info.get("instance_public_ip", {}).get("value", "")
        instance_dns = self.info.get("instance_public_dns", {}).get("value", "")
        rds_endpoint = self.info.get("rds_endpoint", {}).get("value", "")
        static_bucket = self.info.get("static_bucket", {}).get("value", "")
        media_bucket = self.info.get("media_bucket", {}).get("value", "")

        env_content = f"""# Configurações de Produção - Sistema de Agendamento 4Minds
# Gerado automaticamente em {self.get_timestamp()}

# Django
DEBUG=False
SECRET_KEY=django-insecure-4minds-agendamento-2025-super-secret-key
ALLOWED_HOSTS={instance_ip},{instance_dns},fourmindstech.com.br,www.fourmindstech.com.br,api.fourmindstech.com.br,admin.fourmindstech.com.br

# Banco de Dados
DB_NAME=agendamento_db
DB_USER=agendamento_user
DB_PASSWORD=4MindsAgendamento2025!SecureDB#Pass
DB_HOST={rds_endpoint}
DB_PORT=5432

# AWS S3
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_STORAGE_BUCKET_NAME_STATIC={static_bucket}
AWS_STORAGE_BUCKET_NAME_MEDIA={media_bucket}
AWS_S3_REGION_NAME=us-east-1

# Email (configurar conforme necessário)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=
SMTP_PASSWORD=
DEFAULT_FROM_EMAIL=Sistema de Agendamentos <noreply@fourmindstech.com.br>

# HTTPS
HTTPS_REDIRECT=False

# Asaas (desabilitado - serviço pago)
ASAAS_API_KEY=
ASAAS_ENV=sandbox
ASAAS_WEBHOOK_TOKEN=
"""

        env_file = self.project_root / ".env"
        with open(env_file, "w", encoding="utf-8") as f:
            f.write(env_content)

        print(f"✅ Arquivo .env atualizado: {env_file}")
        return True

    def update_settings_production(self):
        """Atualiza settings de produção"""
        print("⚙️ Atualizando settings de produção...")

        settings_content = """import os
from pathlib import Path
from .settings import *

# Carregar variáveis de ambiente do arquivo .env
try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = os.environ.get(
    "SECRET_KEY", "django-insecure-4minds-agendamento-2025-super-secret-key"
)

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = os.environ.get("DEBUG", "False").lower() == "true"

# Hosts permitidos para produção
ALLOWED_HOSTS = [
    "localhost",
    "127.0.0.1",
    "0.0.0.0",
]

# Adicionar hosts da variável de ambiente
env_hosts = os.environ.get("ALLOWED_HOSTS", "")
if env_hosts:
    ALLOWED_HOSTS.extend(
        [host.strip() for host in env_hosts.split(",") if host.strip()]
    )

# Database - PostgreSQL para produção
DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": os.environ.get("DB_NAME", "agendamento_db"),
        "USER": os.environ.get("DB_USER", "agendamento_user"),
        "PASSWORD": os.environ.get("DB_PASSWORD", ""),
        "HOST": os.environ.get("DB_HOST", "localhost"),
        "PORT": os.environ.get("DB_PORT", "5432"),
    }
}

# Static files (CSS, JavaScript, Images)
STATIC_URL = "/static/"
STATIC_ROOT = os.path.join(BASE_DIR, "staticfiles")

# Verificar se o diretório static existe antes de adicionar
static_dir = os.path.join(BASE_DIR, "static")
if os.path.exists(static_dir):
    STATICFILES_DIRS = [static_dir]
else:
    STATICFILES_DIRS = []

# Media files
MEDIA_URL = "/media/"
MEDIA_ROOT = os.path.join(BASE_DIR, "media")

# Security settings para produção
SECURE_BROWSER_XSS_FILTER = True
SECURE_CONTENT_TYPE_NOSNIFF = True
X_FRAME_OPTIONS = "DENY"
SECURE_HSTS_SECONDS = 31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True

# HTTPS settings
SECURE_SSL_REDIRECT = os.environ.get("HTTPS_REDIRECT", "False").lower() == "true"
SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")

# Session settings
SESSION_COOKIE_SECURE = os.environ.get("HTTPS_REDIRECT", "False").lower() == "true"
CSRF_COOKIE_SECURE = os.environ.get("HTTPS_REDIRECT", "False").lower() == "true"

# CSRF Trusted Origins - Necessário para forms POST funcionarem
CSRF_TRUSTED_ORIGINS = [
    "https://fourmindstech.com.br",
    "https://www.fourmindstech.com.br",
    "http://fourmindstech.com.br",  # Temporário durante transição HTTP->HTTPS
]

# Email settings
EMAIL_BACKEND = "django.core.mail.backends.smtp.EmailBackend"
EMAIL_HOST = os.environ.get("SMTP_HOST", "smtp.gmail.com")
EMAIL_PORT = int(os.environ.get("SMTP_PORT", "587"))
EMAIL_USE_TLS = True
EMAIL_HOST_USER = os.environ.get("SMTP_USER", "")
EMAIL_HOST_PASSWORD = os.environ.get("SMTP_PASSWORD", "")
DEFAULT_FROM_EMAIL = os.environ.get(
    "DEFAULT_FROM_EMAIL", "Sistema de Agendamentos <noreply@fourmindstech.com.br>"
)

# Logging
LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "handlers": {
        "console": {
            "class": "logging.StreamHandler",
        },
    },
    "root": {
        "handlers": ["console"],
        "level": "INFO",
    },
    "loggers": {
        "django": {
            "handlers": ["console"],
            "level": "INFO",
            "propagate": False,
        },
    },
}

# Cache (usar memória para instância única)
CACHES = {
    "default": {
        "BACKEND": "django.core.cache.backends.locmem.LocMemCache",
        "LOCATION": "unique-snowflake",
    }
}

# WhiteNoise para arquivos estáticos (se disponível)
try:
    import whitenoise
    MIDDLEWARE.insert(1, "whitenoise.middleware.WhiteNoiseMiddleware")
    STATICFILES_STORAGE = "whitenoise.storage.StaticFilesStorage"
except ImportError:
    STATICFILES_STORAGE = "django.contrib.staticfiles.storage.StaticFilesStorage"

# Configuração adicional para servir arquivos estáticos
STATICFILES_FINDERS = [
    "django.contrib.staticfiles.finders.FileSystemFinder",
    "django.contrib.staticfiles.finders.AppDirectoriesFinder",
]

# Asaas (desabilitado - serviço pago)
ASAAS_API_KEY = os.environ.get("ASAAS_API_KEY", "")
ASAAS_ENV = os.environ.get("ASAAS_ENV", "sandbox")
ASAAS_WEBHOOK_TOKEN = os.environ.get("ASAAS_WEBHOOK_TOKEN", "")
"""

        settings_file = self.project_root / "core" / "settings_production.py"
        with open(settings_file, "w", encoding="utf-8") as f:
            f.write(settings_content)

        print(f"✅ Settings de produção atualizado: {settings_file}")
        return True

    def save_infrastructure_info(self):
        """Salva informações da infraestrutura em arquivo JSON"""
        print("💾 Salvando informações da infraestrutura...")

        info_file = self.terraform_dir / "infrastructure_info.json"
        with open(info_file, "w", encoding="utf-8") as f:
            json.dump(self.info, f, indent=2, ensure_ascii=False)

        print(f"✅ Informações salvas em: {info_file}")
        return True

    def print_summary(self):
        """Imprime resumo das informações coletadas"""
        print("\n" + "=" * 60)
        print("📊 RESUMO DA INFRAESTRUTURA")
        print("=" * 60)

        instance_id = self.info.get("instance_id", {}).get("value", "N/A")
        instance_ip = self.info.get("instance_public_ip", {}).get("value", "N/A")
        instance_dns = self.info.get("instance_public_dns", {}).get("value", "N/A")
        rds_endpoint = self.info.get("rds_endpoint", {}).get("value", "N/A")
        static_bucket = self.info.get("static_bucket", {}).get("value", "N/A")
        media_bucket = self.info.get("media_bucket", {}).get("value", "N/A")
        vpc_id = self.info.get("vpc_id", {}).get("value", "N/A")

        print(f"🖥️  Instance ID: {instance_id}")
        print(f"🌐 IP Público: {instance_ip}")
        print(f"🔗 DNS Público: {instance_dns}")
        print(f"🗄️  RDS Endpoint: {rds_endpoint}")
        print(f"📦 Static Bucket: {static_bucket}")
        print(f"📁 Media Bucket: {media_bucket}")
        print(f"🔒 VPC ID: {vpc_id}")

        if instance_ip != "N/A":
            print(f"\n🌐 URLs de Acesso:")
            print(f"   - Website: http://{instance_ip}")
            print(f"   - Admin: http://{instance_ip}/admin/")
            print(f"   - API: http://{instance_ip}/api/")

        print("\n👤 Credenciais de Acesso:")
        print("   - Usuário: admin")
        print("   - Senha: admin123")

        print("\n✅ Sistema pronto para deploy!")
        print("=" * 60)

    def get_timestamp(self):
        """Retorna timestamp atual"""
        from datetime import datetime

        return datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    def run(self):
        """Executa o processo completo de coleta de informações"""
        print("🚀 Iniciando coleta de informações da infraestrutura...")

        # Coletar outputs do Terraform
        if not self.collect_terraform_outputs():
            return False

        # Coletar informações adicionais da AWS
        self.collect_aws_info()

        # Atualizar arquivos de configuração
        self.update_env_file()
        self.update_settings_production()

        # Salvar informações
        self.save_infrastructure_info()

        # Imprimir resumo
        self.print_summary()

        return True


def main():
    collector = InfrastructureInfoCollector()
    success = collector.run()

    if success:
        print("\n✅ Coleta de informações concluída com sucesso!")
        sys.exit(0)
    else:
        print("\n❌ Erro na coleta de informações!")
        sys.exit(1)


if __name__ == "__main__":
    main()
