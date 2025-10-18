#!/usr/bin/env python3
"""
Script para abrir a tela de seleção de planos
Sistema de Agendamento - 4Minds
"""

import os
import sys
import django
import webbrowser

# Configurar Django
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "core.settings")
django.setup()

from django.contrib.auth.models import User


def abrir_tela_planos():
    """Abre a tela de seleção de planos no navegador"""
    print("🚀 Abrindo tela de seleção de planos...")

    # URL da tela de planos
    url = "http://localhost:8000/authentication/planos/"

    print(f"📱 URL: {url}")
    print("🌐 Abrindo no navegador...")

    try:
        webbrowser.open(url)
        print("✅ Tela aberta com sucesso!")
    except Exception as e:
        print(f"❌ Erro ao abrir navegador: {e}")
        print(f"💡 Acesse manualmente: {url}")


def verificar_planos_disponiveis():
    """Verifica se os planos estão configurados"""
    print("\n📋 Verificando planos disponíveis...")

    try:
        from authentication.models import Plano

        planos = Plano.objects.filter(ativo=True).order_by("ordem")

        if not planos.exists():
            print("❌ Nenhum plano encontrado!")
            print("💡 Execute: python manage.py populate_plans")
            return False

        print(f"✅ {planos.count()} planos encontrados:")
        for plano in planos:
            print(
                f"   • {plano.nome} - R$ {plano.preco_pix} (PIX) - {plano.duracao_dias} dias"
            )
            if plano.destaque:
                print(f"     ⭐ Plano em destaque")

        return True

    except Exception as e:
        print(f"❌ Erro ao verificar planos: {e}")
        return False


def criar_usuario_teste():
    """Cria um usuário de teste para testar o fluxo"""
    print("\n👤 Criando usuário de teste...")

    try:
        # Verificar se já existe
        user, created = User.objects.get_or_create(
            username="teste_planos",
            defaults={
                "email": "teste@planos.com",
                "first_name": "Teste",
                "last_name": "Planos",
            },
        )

        if created:
            user.set_password("senha123")
            user.save()
            print("✅ Usuário de teste criado:")
            print(f"   Username: teste_planos")
            print(f"   Senha: senha123")
            print(f"   Email: teste@planos.com")
        else:
            print("ℹ️ Usuário de teste já existe")

        return user

    except Exception as e:
        print(f"❌ Erro ao criar usuário: {e}")
        return None


def mostrar_instrucoes():
    """Mostra instruções de uso"""
    print("\n" + "=" * 60)
    print("📖 INSTRUÇÕES DE USO")
    print("=" * 60)

    print("\n🎯 OPÇÕES PARA ACESSAR A TELA DE PLANOS:")
    print("\n1️⃣ URL DIRETA:")
    print("   http://localhost:8000/authentication/planos/")

    print("\n2️⃣ VIA CADASTRO:")
    print("   http://localhost:8000/authentication/register/")
    print("   (Redireciona automaticamente para planos)")

    print("\n3️⃣ VIA LOGIN (se já tem usuário):")
    print("   http://localhost:8000/authentication/login/")
    print("   (Depois acesse /authentication/planos/)")

    print("\n🔧 COMANDOS ÚTEIS:")
    print("   • python manage.py populate_plans  # Criar planos")
    print("   • python manage.py runserver      # Iniciar servidor")
    print("   • python abrir_tela_planos.py     # Este script")

    print("\n📱 FUNCIONALIDADES DA TELA:")
    print("   • Período gratuito (14 dias)")
    print("   • Plano mensal (R$ 45 PIX)")
    print("   • Plano semestral (R$ 250 PIX) ⭐")
    print("   • Plano anual (R$ 500 PIX)")
    print("   • Seleção de pagamento (PIX/Cartão)")


def main():
    """Função principal"""
    print("🎯 Abrir Tela de Seleção de Planos")
    print("=" * 50)

    # Verificar se o servidor está rodando
    print("🔍 Verificando servidor...")
    try:
        import requests

        response = requests.get("http://localhost:8000/", timeout=5)
        if response.status_code == 200:
            print("✅ Servidor está rodando")
        else:
            print("⚠️ Servidor pode não estar rodando corretamente")
    except:
        print("❌ Servidor não está rodando!")
        print("💡 Execute: python manage.py runserver")
        return

    # Verificar planos
    if not verificar_planos_disponiveis():
        return

    # Criar usuário de teste
    user = criar_usuario_teste()

    # Mostrar instruções
    mostrar_instrucoes()

    # Abrir tela
    abrir_tela_planos()

    print("\n🎉 Pronto! A tela de planos deve estar aberta no seu navegador.")


if __name__ == "__main__":
    main()
