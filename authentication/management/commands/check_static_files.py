from django.core.management.base import BaseCommand
from django.conf import settings
from django.contrib.staticfiles.finders import get_finders
import os


class Command(BaseCommand):
    help = "Verifica e lista todos os arquivos estáticos encontrados"

    def handle(self, *args, **options):
        self.stdout.write("🔍 VERIFICANDO ARQUIVOS ESTÁTICOS")
        self.stdout.write("=" * 50)

        # Verificar configurações
        self.stdout.write(f"STATIC_URL: {settings.STATIC_URL}")
        self.stdout.write(f"STATIC_ROOT: {settings.STATIC_ROOT}")
        self.stdout.write(f"STATICFILES_DIRS: {settings.STATICFILES_DIRS}")
        self.stdout.write(f"DEBUG: {settings.DEBUG}")
        self.stdout.write("")

        # Verificar se STATIC_ROOT existe
        if os.path.exists(settings.STATIC_ROOT):
            self.stdout.write(f"✅ STATIC_ROOT existe: {settings.STATIC_ROOT}")
        else:
            self.stdout.write(f"❌ STATIC_ROOT não existe: {settings.STATIC_ROOT}")

        # Verificar diretórios de arquivos estáticos
        for static_dir in settings.STATICFILES_DIRS:
            if os.path.exists(static_dir):
                self.stdout.write(f"✅ STATICFILES_DIRS existe: {static_dir}")
            else:
                self.stdout.write(f"❌ STATICFILES_DIRS não existe: {static_dir}")

        self.stdout.write("")

        # Listar arquivos encontrados pelos finders
        self.stdout.write("📁 ARQUIVOS ENCONTRADOS PELOS FINDERS:")
        self.stdout.write("-" * 40)

        for finder in get_finders():
            self.stdout.write(f"Finder: {finder.__class__.__name__}")
            for path, storage in finder.list([]):
                self.stdout.write(f"  - {path}")
            self.stdout.write("")

        # Verificar arquivos coletados
        if os.path.exists(settings.STATIC_ROOT):
            self.stdout.write("📁 ARQUIVOS COLETADOS:")
            self.stdout.write("-" * 20)

            for root, dirs, files in os.walk(settings.STATIC_ROOT):
                level = root.replace(settings.STATIC_ROOT, "").count(os.sep)
                indent = " " * 2 * level
                self.stdout.write(f"{indent}{os.path.basename(root)}/")
                subindent = " " * 2 * (level + 1)
                for file in files:
                    self.stdout.write(f"{subindent}{file}")

        # Verificar arquivos CSS específicos
        self.stdout.write("")
        self.stdout.write("🎨 VERIFICANDO ARQUIVOS CSS:")
        self.stdout.write("-" * 30)

        css_files = [
            "css/style.css",
            "css/bootstrap.min.css",
            "css/error-messages.css",
            "css/auth.css",
            "css/dashboard.css",
        ]

        for css_file in css_files:
            css_path = os.path.join(settings.STATIC_ROOT, css_file)
            if os.path.exists(css_path):
                size = os.path.getsize(css_path)
                self.stdout.write(f"✅ {css_file} ({size} bytes)")
            else:
                self.stdout.write(f"❌ {css_file} não encontrado")

        # Verificar arquivos JS específicos
        self.stdout.write("")
        self.stdout.write("⚡ VERIFICANDO ARQUIVOS JS:")
        self.stdout.write("-" * 30)

        js_files = [
            "js/bootstrap.bundle.min.js",
            "js/script.js",
            "js/dashboard.js",
            "js/agendamento_detail.js",
        ]

        for js_file in js_files:
            js_path = os.path.join(settings.STATIC_ROOT, js_file)
            if os.path.exists(js_path):
                size = os.path.getsize(js_path)
                self.stdout.write(f"✅ {js_file} ({size} bytes)")
            else:
                self.stdout.write(f"❌ {js_file} não encontrado")

        self.stdout.write("")
        self.stdout.write("🎉 VERIFICAÇÃO CONCLUÍDA!")



