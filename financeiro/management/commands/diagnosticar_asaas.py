"""
Comando de diagnóstico para verificar configuração do Asaas
Execute: python manage.py diagnosticar_asaas
"""

from django.core.management.base import BaseCommand
from django.conf import settings
from pathlib import Path
import os
import sys


class Command(BaseCommand):
    help = "Diagnostica a configuração do Asaas e identifica problemas"

    def handle(self, *args, **options):
        self.stdout.write("\n" + "=" * 70)
        self.stdout.write(self.style.SUCCESS("DIAGNOSTICO DE CONFIGURACAO ASAAS"))
        self.stdout.write("=" * 70 + "\n")

        # 1. Verificar arquivo .env
        self.stdout.write("\n1. VERIFICANDO ARQUIVO .env")
        self.stdout.write("-" * 70)
        # Calcular BASE_DIR corretamente: financeiro/management/commands/diagnosticar_asaas.py
        # Voltar 4 níveis para chegar ao diretório raiz do projeto
        BASE_DIR = Path(__file__).resolve().parent.parent.parent.parent
        env_path = BASE_DIR / '.env'
        
        self.stdout.write(f"   BASE_DIR: {BASE_DIR}")
        self.stdout.write(f"   Caminho .env: {env_path}")
        self.stdout.write(f"   Existe: {'SIM' if env_path.exists() else 'NAO'}")
        
        if env_path.exists():
            try:
                stat_info = env_path.stat()
                self.stdout.write(f"   Tamanho: {stat_info.st_size} bytes")
                self.stdout.write(f"   Permissões: {oct(stat_info.st_mode)[-3:]}")
                
                # Tentar ler o arquivo
                try:
                    with open(env_path, 'r', encoding='utf-8') as f:
                        content = f.read()
                        has_key = 'ASAAS_API_KEY' in content
                        self.stdout.write(f"   Contem ASAAS_API_KEY: {'SIM' if has_key else 'NAO'}")
                        
                        if has_key:
                            # Mostrar apenas os primeiros caracteres
                            for line in content.split('\n'):
                                if line.strip().startswith('ASAAS_API_KEY='):
                                    key_preview = line.split('=')[1][:20] + '...' if len(line.split('=')[1]) > 20 else line.split('=')[1]
                                    self.stdout.write(f"   Preview: ASAAS_API_KEY={key_preview}")
                                    break
                except PermissionError:
                    self.stdout.write(self.style.ERROR("   [ERRO] Sem permissao para ler o arquivo .env"))
                    self.stdout.write(self.style.WARNING("   [DICA] Execute: sudo chown ubuntu:ubuntu /opt/s-agendamento/.env"))
                    self.stdout.write(self.style.WARNING("   [DICA] OU ajuste as permissoes: sudo chmod 644 /opt/s-agendamento/.env"))
            except Exception as e:
                self.stdout.write(self.style.ERROR(f"   [ERRO] Erro ao ler arquivo: {e}"))
        else:
            self.stdout.write(self.style.ERROR("   [ERRO] Arquivo .env nao encontrado!"))
            self.stdout.write(self.style.WARNING("   [DICA] Crie o arquivo .env baseado no .env.example"))

        # 2. Verificar variáveis de ambiente
        self.stdout.write("\n2. VERIFICANDO VARIAVEIS DE AMBIENTE")
        self.stdout.write("-" * 70)
        
        asaas_api_key_env = os.environ.get("ASAAS_API_KEY")
        asaas_env_env = os.environ.get("ASAAS_ENV")
        
        self.stdout.write(f"   ASAAS_API_KEY (os.environ): {'SIM' if asaas_api_key_env else 'NAO'}")
        self.stdout.write(f"   ASAAS_ENV (os.environ): {asaas_env_env or 'NAO DEFINIDO'}")
        
        # 3. Verificar settings
        self.stdout.write("\n3. VERIFICANDO SETTINGS")
        self.stdout.write("-" * 70)
        
        asaas_api_key_settings = getattr(settings, "ASAAS_API_KEY", None)
        asaas_env_settings = getattr(settings, "ASAAS_ENV", None)
        asaas_enabled = getattr(settings, "ASAAS_ENABLED", False)
        debug_value = getattr(settings, "DEBUG", True)
        settings_module = os.environ.get("DJANGO_SETTINGS_MODULE", "")
        
        self.stdout.write(f"   DJANGO_SETTINGS_MODULE: {settings_module}")
        self.stdout.write(f"   DEBUG: {debug_value}")
        self.stdout.write(f"   ASAAS_API_KEY (settings): {'SIM' if asaas_api_key_settings else 'NAO'}")
        self.stdout.write(f"   ASAAS_ENV (settings): {asaas_env_settings or 'NAO DEFINIDO'}")
        self.stdout.write(f"   ASAAS_ENABLED: {asaas_enabled}")
        
        # 4. Testar inicialização do AsaasClient
        self.stdout.write("\n4. TESTANDO INICIALIZACAO DO AsaasClient")
        self.stdout.write("-" * 70)
        
        try:
            from financeiro.services.asaas import AsaasClient
            import socket
            
            hostname = socket.gethostname()
            self.stdout.write(f"   Hostname: {hostname}")
            
            try:
                client = AsaasClient()
                self.stdout.write(self.style.SUCCESS("   [OK] AsaasClient inicializado com sucesso"))
                self.stdout.write(f"   Ambiente detectado: {client.env}")
                self.stdout.write(f"   Base URL: {client.base}")
                self.stdout.write(f"   API Key configurada: {'SIM' if client.api_key else 'NAO'}")
                
                if client.api_key:
                    # Mostrar apenas primeiros caracteres
                    key_preview = client.api_key[:20] + '...' if len(client.api_key) > 20 else client.api_key
                    self.stdout.write(f"   Preview da chave: {key_preview}")
                else:
                    self.stdout.write(self.style.ERROR("   [ERRO] API Key nao esta configurada!"))
                    
            except RuntimeError as e:
                self.stdout.write(self.style.ERROR(f"   [ERRO] Erro ao inicializar: {e}"))
            except Exception as e:
                self.stdout.write(self.style.ERROR(f"   [ERRO] Erro inesperado: {e}"))
                
        except ImportError as e:
            self.stdout.write(self.style.ERROR(f"   [ERRO] Erro ao importar AsaasClient: {e}"))

        # 5. Recomendações
        self.stdout.write("\n5. RECOMENDACOES")
        self.stdout.write("-" * 70)
        
        if not env_path.exists():
            self.stdout.write(self.style.WARNING("   - Crie o arquivo .env no diretorio do projeto"))
            self.stdout.write(self.style.WARNING("   - Copie de .env.example e configure as variaveis"))
        
        if not asaas_api_key_settings:
            self.stdout.write(self.style.ERROR("   - ASAAS_API_KEY nao esta configurada!"))
            self.stdout.write(self.style.WARNING("   - Adicione ASAAS_API_KEY no arquivo .env"))
            self.stdout.write(self.style.WARNING("   - Formato: ASAAS_API_KEY=$aact_SUA_CHAVE_AQUI"))
            self.stdout.write(self.style.WARNING("   - Reinicie o Gunicorn apos configurar: sudo systemctl restart gunicorn"))
        
        if debug_value:
            self.stdout.write(self.style.WARNING("   - DEBUG esta True em producao! Configure DEBUG=False"))
        
        if settings_module and "production" not in settings_module.lower():
            self.stdout.write(self.style.WARNING(f"   - DJANGO_SETTINGS_MODULE esta como '{settings_module}'"))
            self.stdout.write(self.style.WARNING("   - Em producao, deve ser 'core.settings_production'"))
        
        # 6. Verificar Gunicorn/Systemd
        self.stdout.write("\n6. VERIFICANDO CONFIGURACAO DO SERVICO")
        self.stdout.write("-" * 70)
        
        try:
            import subprocess
            # Verificar se está rodando via systemd
            result = subprocess.run(['systemctl', 'is-active', 's-agendamento'], 
                                  capture_output=True, text=True, timeout=2)
            if result.returncode == 0:
                self.stdout.write("   Serviço: systemd (s-agendamento)")
                self.stdout.write(self.style.WARNING("   [DICA] Verifique se o arquivo .env esta acessivel pelo usuario do servico"))
                self.stdout.write(self.style.WARNING("   [DICA] O systemd pode nao estar carregando o .env automaticamente"))
        except:
            pass
        
        self.stdout.write("\n" + "=" * 70)
        self.stdout.write(self.style.SUCCESS("[OK] Diagnostico concluido"))
        self.stdout.write("=" * 70 + "\n")

