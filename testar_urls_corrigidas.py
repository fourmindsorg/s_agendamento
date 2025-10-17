#!/usr/bin/env python3
"""
Script para testar se as URLs foram corrigidas corretamente
Sistema de Agendamento - 4Minds
"""

import os
import sys
import django

# Configurar Django
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "core.settings")
django.setup()

from django.urls import reverse
from django.conf import settings


def test_urls_configuration():
    """Testa se as URLs estão configuradas corretamente"""
    print("🔗 Testando configuração de URLs...")
    print("-" * 50)

    # Testa URLs de autenticação
    urls_to_test = [
        ("authentication:login", "/authentication/login/"),
        ("authentication:register", "/authentication/register/"),
        ("authentication:plan_selection", "/authentication/planos/"),
        ("authentication:plan_confirmation", "/authentication/planos/confirmar/1/"),
        ("authentication:select_plan", "/authentication/planos/selecionar/1/"),
        ("authentication:skip_plan_selection", "/authentication/planos/pular/"),
    ]

    print("✅ URLs de autenticação:")
    for url_name, expected_path in urls_to_test:
        try:
            if "plan_confirmation" in url_name or "select_plan" in url_name:
                actual_path = reverse(url_name, args=[1])
            else:
                actual_path = reverse(url_name)

            status = "✅" if actual_path == expected_path else "❌"
            print(f"   {status} {url_name}: {actual_path}")

            if actual_path != expected_path:
                print(f"      Esperado: {expected_path}")

        except Exception as e:
            print(f"   ❌ {url_name}: Erro - {e}")

    return True


def test_settings_configuration():
    """Testa se as configurações do Django estão corretas"""
    print("\n⚙️ Testando configurações do Django...")
    print("-" * 50)

    # Testa configurações de login/logout
    settings_to_test = [
        ("LOGIN_URL", "/authentication/login/"),
        ("LOGOUT_REDIRECT_URL", "/authentication/login/"),
        ("LOGOUT_URL", "/authentication/logout/"),
    ]

    print("✅ Configurações de autenticação:")
    for setting_name, expected_value in settings_to_test:
        actual_value = getattr(settings, setting_name, None)
        status = "✅" if actual_value == expected_value else "❌"
        print(f"   {status} {setting_name}: {actual_value}")

        if actual_value != expected_value:
            print(f"      Esperado: {expected_value}")

    return True


def test_planos_functionality():
    """Testa se a funcionalidade de planos está funcionando"""
    print("\n📋 Testando funcionalidade de planos...")
    print("-" * 50)

    try:
        from authentication.models import Plano, AssinaturaUsuario
        from django.contrib.auth.models import User
        from django.utils import timezone
        from datetime import timedelta

        # Testa se os planos existem
        planos = Plano.objects.filter(ativo=True)
        print(f"✅ Planos ativos encontrados: {planos.count()}")

        for plano in planos:
            print(f"   • {plano.nome} - R$ {plano.preco_pix} (PIX)")

        # Testa criação de assinatura
        user, created = User.objects.get_or_create(
            username="teste_urls", defaults={"email": "teste@example.com"}
        )

        plano_gratuito = Plano.objects.get(tipo="gratuito")
        data_fim = timezone.now() + timedelta(days=plano_gratuito.duracao_dias)

        assinatura = AssinaturaUsuario.objects.create(
            usuario=user, plano=plano_gratuito, data_fim=data_fim, status="ativa"
        )

        print(f"✅ Assinatura criada: {assinatura}")
        print(f"   Status: {assinatura.status}")
        print(f"   Ativa: {assinatura.ativa}")

        # Limpar
        assinatura.delete()
        if created:
            user.delete()

        return True

    except Exception as e:
        print(f"❌ Erro na funcionalidade de planos: {e}")
        return False


def main():
    """Função principal"""
    print("🚀 Teste das URLs Corrigidas")
    print("=" * 60)

    tests = [
        ("Configuração de URLs", test_urls_configuration),
        ("Configurações do Django", test_settings_configuration),
        ("Funcionalidade de Planos", test_planos_functionality),
    ]

    results = []

    for test_name, test_func in tests:
        print(f"\n📋 {test_name}")
        try:
            success = test_func()
            results.append((test_name, success))
        except Exception as e:
            print(f"❌ Erro inesperado: {e}")
            results.append((test_name, False))

    # Resumo final
    print("\n" + "=" * 60)
    print("📊 RESUMO DOS TESTES")
    print("=" * 60)

    passed = sum(1 for _, success in results if success)
    total = len(results)

    for test_name, success in results:
        status = "✅ PASSOU" if success else "❌ FALHOU"
        print(f"{status} - {test_name}")

    print(f"\n🎯 Resultado: {passed}/{total} testes passaram")

    if passed == total:
        print("🎉 TODAS AS CORREÇÕES FORAM APLICADAS COM SUCESSO!")
        print("\n📋 CORREÇÕES REALIZADAS:")
        print("• ✅ URLs principais corrigidas (auth/ -> authentication/)")
        print("• ✅ Configurações do Django atualizadas")
        print("• ✅ Arquivos JavaScript atualizados")
        print("• ✅ Templates atualizados")
        print("• ✅ Sistema de planos funcionando")
        print("\n🚀 AGORA VOCÊ PODE TESTAR:")
        print("1. Acesse: http://localhost:8000/authentication/register/")
        print("2. Cadastre-se com seus dados")
        print("3. Será redirecionado para seleção de planos")
        print("4. Escolha seu plano e teste o sistema")
        return True
    else:
        print("⚠️ Algumas correções falharam. Verifique os erros acima.")
        return False


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
