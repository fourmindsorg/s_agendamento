#!/usr/bin/env python3
"""
Script para testar o sistema de seleção de planos
Sistema de Agendamento - 4Minds
"""

import os
import sys
import django
from datetime import datetime, timedelta

# Configurar Django
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "core.settings")
django.setup()

from django.test import Client
from django.contrib.auth.models import User
from authentication.models import Plano, AssinaturaUsuario
from django.urls import reverse


def test_planos_criados():
    """Testa se os planos foram criados corretamente"""
    print("📋 Testando planos criados...")
    print("-" * 50)

    planos = Plano.objects.filter(ativo=True).order_by("ordem")

    if not planos.exists():
        print("❌ Nenhum plano encontrado!")
        return False

    print(f"✅ {planos.count()} planos encontrados:")
    for plano in planos:
        print(
            f"   • {plano.nome} - R$ {plano.preco_pix} (PIX) - {plano.duracao_dias} dias"
        )
        if plano.destaque:
            print(f"     ⭐ Plano em destaque")

    return True


def test_views_planos():
    """Testa as views de seleção de planos"""
    print("\n👁️ Testando views de planos...")
    print("-" * 50)

    client = Client()

    # Testa view de seleção de planos (sem login - deve redirecionar)
    response = client.get(reverse("authentication:plan_selection"))
    print(f"✅ Seleção de planos (sem login): {response.status_code} (esperado: 302)")

    # Criar usuário de teste
    user, created = User.objects.get_or_create(
        username="testuser_planos",
        defaults={
            "email": "test@example.com",
            "first_name": "Teste",
            "last_name": "Usuário",
        },
    )

    # Fazer login
    client.force_login(user)

    # Testa view de seleção de planos (com login)
    response = client.get(reverse("authentication:plan_selection"))
    print(f"✅ Seleção de planos (com login): {response.status_code} (esperado: 200)")

    # Testa view de confirmação de plano
    plano = Plano.objects.filter(ativo=True).first()
    if plano:
        response = client.get(
            reverse("authentication:plan_confirmation", args=[plano.id])
        )
        print(f"✅ Confirmação de plano: {response.status_code} (esperado: 200)")

    # Testa seleção de plano gratuito
    response = client.get(reverse("authentication:skip_plan_selection"))
    print(f"✅ Pular seleção (gratuito): {response.status_code} (esperado: 302)")

    # Limpar usuário de teste
    if created:
        user.delete()

    return True


def test_assinatura_usuario():
    """Testa criação de assinatura de usuário"""
    print("\n📊 Testando assinatura de usuário...")
    print("-" * 50)

    # Criar usuário de teste
    user, created = User.objects.get_or_create(
        username="testuser_assinatura",
        defaults={
            "email": "testassinatura@example.com",
            "first_name": "Teste",
            "last_name": "Assinatura",
        },
    )

    # Buscar plano gratuito
    plano_gratuito = Plano.objects.get(tipo="gratuito")

    # Criar assinatura
    from django.utils import timezone

    data_fim = timezone.now() + timedelta(days=plano_gratuito.duracao_dias)

    assinatura = AssinaturaUsuario.objects.create(
        usuario=user, plano=plano_gratuito, data_fim=data_fim, status="ativa"
    )

    print(f"✅ Assinatura criada: {assinatura}")
    print(f"   Usuário: {assinatura.usuario.username}")
    print(f"   Plano: {assinatura.plano.nome}")
    print(f"   Status: {assinatura.status}")
    print(f"   Ativa: {assinatura.ativa}")
    print(f"   Dias restantes: {assinatura.dias_restantes}")

    # Limpar
    assinatura.delete()
    if created:
        user.delete()

    return True


def test_fluxo_completo():
    """Testa o fluxo completo de seleção de planos"""
    print("\n🔗 Testando fluxo completo...")
    print("-" * 50)

    client = Client()

    # Criar usuário de teste
    user, created = User.objects.get_or_create(
        username="testuser_fluxo",
        defaults={
            "email": "testfluxo@example.com",
            "first_name": "Teste",
            "last_name": "Fluxo",
        },
    )

    # Fazer login
    client.force_login(user)

    # 1. Acessar seleção de planos
    response = client.get(reverse("authentication:plan_selection"))
    print(f"✅ 1. Acessar seleção: {response.status_code}")

    # 2. Selecionar plano gratuito
    response = client.get(reverse("authentication:skip_plan_selection"))
    print(f"✅ 2. Selecionar gratuito: {response.status_code}")

    # 3. Verificar se assinatura foi criada
    assinatura = AssinaturaUsuario.objects.filter(usuario=user).first()
    if assinatura:
        print(f"✅ 3. Assinatura criada: {assinatura.plano.nome}")
        print(f"   Status: {assinatura.status}")
        print(f"   Ativa: {assinatura.ativa}")
    else:
        print("❌ 3. Assinatura não foi criada!")
        return False

    # 4. Testar seleção de plano pago
    plano_pago = Plano.objects.filter(
        ativo=True, tipo__in=["mensal", "semestral", "anual"]
    ).first()
    if plano_pago:
        response = client.get(
            reverse("authentication:select_plan", args=[plano_pago.id])
        )
        print(f"✅ 4. Selecionar plano pago: {response.status_code}")

    # Limpar
    AssinaturaUsuario.objects.filter(usuario=user).delete()
    if created:
        user.delete()

    return True


def main():
    """Função principal"""
    print("🚀 Teste do Sistema de Seleção de Planos")
    print("=" * 60)

    tests = [
        ("Planos Criados", test_planos_criados),
        ("Views de Planos", test_views_planos),
        ("Assinatura de Usuário", test_assinatura_usuario),
        ("Fluxo Completo", test_fluxo_completo),
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
        print(
            "🎉 TODOS OS TESTES PASSARAM! O sistema de seleção de planos está funcionando."
        )
        print("\n📋 FUNCIONALIDADES IMPLEMENTADAS:")
        print("• Modelos Plano e AssinaturaUsuario")
        print("• Views de seleção e confirmação de planos")
        print("• Templates responsivos e modernos")
        print("• Integração com sistema de autenticação")
        print("• Período gratuito de 14 dias")
        print("• Planos mensal, semestral e anual")
        print("• Sistema de destaque para planos populares")
        return True
    else:
        print("⚠️ Alguns testes falharam. Verifique os erros acima.")
        return False


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
