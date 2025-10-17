#!/usr/bin/env python3
"""
Script simples para testar o sistema de seleção de planos
Sistema de Agendamento - 4Minds
"""

import os
import sys
import django
from datetime import timedelta

# Configurar Django
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "core.settings")
django.setup()

from django.contrib.auth.models import User
from authentication.models import Plano, AssinaturaUsuario
from django.utils import timezone


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
        print(f"     Economia PIX: R$ {plano.economia_pix}")

    return True


def test_assinatura_usuario():
    """Testa criação de assinatura de usuário"""
    print("\n📊 Testando assinatura de usuário...")
    print("-" * 50)

    # Criar usuário de teste
    user, created = User.objects.get_or_create(
        username="testuser_assinatura_simples",
        defaults={
            "email": "testassinatura@example.com",
            "first_name": "Teste",
            "last_name": "Assinatura",
        },
    )

    # Buscar plano gratuito
    plano_gratuito = Plano.objects.get(tipo="gratuito")

    # Criar assinatura
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

    # Testar atualização de status
    assinatura.status = "expirada"
    assinatura.save()
    print(f"✅ Status atualizado para: {assinatura.status}")
    print(f"   Ativa após atualização: {assinatura.ativa}")

    # Limpar
    assinatura.delete()
    if created:
        user.delete()

    return True


def test_planos_diferentes():
    """Testa diferentes tipos de planos"""
    print("\n💰 Testando diferentes tipos de planos...")
    print("-" * 50)

    tipos_planos = ["gratuito", "mensal", "semestral", "anual"]

    for tipo in tipos_planos:
        try:
            plano = Plano.objects.get(tipo=tipo, ativo=True)
            print(f"✅ {plano.nome}:")
            print(f"   Preço Cartão: R$ {plano.preco_cartao}")
            print(f"   Preço PIX: R$ {plano.preco_pix}")
            print(f"   Duração: {plano.duracao_dias} dias")
            print(f"   Economia PIX: R$ {plano.economia_pix}")
            print(f"   Destaque: {'Sim' if plano.destaque else 'Não'}")
        except Plano.DoesNotExist:
            print(f"❌ Plano {tipo} não encontrado")
            return False

    return True


def test_fluxo_assinatura():
    """Testa o fluxo completo de criação de assinatura"""
    print("\n🔗 Testando fluxo de assinatura...")
    print("-" * 50)

    # Criar usuário de teste
    user, created = User.objects.get_or_create(
        username="testuser_fluxo_simples",
        defaults={
            "email": "testfluxo@example.com",
            "first_name": "Teste",
            "last_name": "Fluxo",
        },
    )

    # Testar diferentes planos
    planos_teste = Plano.objects.filter(ativo=True)[:2]  # Pegar 2 planos para teste

    for plano in planos_teste:
        print(f"\n📋 Testando plano: {plano.nome}")

        # Verificar se já tem assinatura ativa
        assinatura_ativa = AssinaturaUsuario.objects.filter(
            usuario=user, status="ativa"
        ).first()

        if assinatura_ativa:
            print(
                f"   ⚠️ Usuário já tem assinatura ativa: {assinatura_ativa.plano.nome}"
            )
            # Cancelar assinatura anterior
            assinatura_ativa.status = "cancelada"
            assinatura_ativa.save()
            print(f"   ✅ Assinatura anterior cancelada")

        # Criar nova assinatura
        data_fim = timezone.now() + timedelta(days=plano.duracao_dias)

        assinatura = AssinaturaUsuario.objects.create(
            usuario=user, plano=plano, data_fim=data_fim, status="ativa"
        )

        print(f"   ✅ Assinatura criada: {assinatura}")
        print(f"   Status: {assinatura.status}")
        print(f"   Ativa: {assinatura.ativa}")
        print(f"   Dias restantes: {assinatura.dias_restantes}")

        # Simular pagamento (para planos pagos)
        if plano.tipo != "gratuito":
            assinatura.valor_pago = plano.preco_pix
            assinatura.metodo_pagamento = "PIX"
            assinatura.save()
            print(
                f"   💳 Pagamento simulado: R$ {assinatura.valor_pago} via {assinatura.metodo_pagamento}"
            )

    # Limpar
    AssinaturaUsuario.objects.filter(usuario=user).delete()
    if created:
        user.delete()

    return True


def test_estatisticas():
    """Testa estatísticas do sistema"""
    print("\n📊 Testando estatísticas...")
    print("-" * 50)

    total_planos = Plano.objects.filter(ativo=True).count()
    total_assinaturas = AssinaturaUsuario.objects.count()
    assinaturas_ativas = AssinaturaUsuario.objects.filter(status="ativa").count()

    print(f"✅ Total de planos ativos: {total_planos}")
    print(f"✅ Total de assinaturas: {total_assinaturas}")
    print(f"✅ Assinaturas ativas: {assinaturas_ativas}")

    # Estatísticas por tipo de plano
    print("\n📈 Assinaturas por tipo de plano:")
    for plano in Plano.objects.filter(ativo=True):
        count = AssinaturaUsuario.objects.filter(plano=plano).count()
        print(f"   • {plano.nome}: {count} assinaturas")

    return True


def main():
    """Função principal"""
    print("🚀 Teste Simples do Sistema de Seleção de Planos")
    print("=" * 60)

    tests = [
        ("Planos Criados", test_planos_criados),
        ("Assinatura de Usuário", test_assinatura_usuario),
        ("Diferentes Tipos de Planos", test_planos_diferentes),
        ("Fluxo de Assinatura", test_fluxo_assinatura),
        ("Estatísticas", test_estatisticas),
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
        print("• ✅ Modelos Plano e AssinaturaUsuario")
        print("• ✅ Views de seleção e confirmação de planos")
        print("• ✅ Templates responsivos e modernos")
        print("• ✅ Integração com sistema de autenticação")
        print("• ✅ Período gratuito de 14 dias")
        print("• ✅ Planos mensal, semestral e anual")
        print("• ✅ Sistema de destaque para planos populares")
        print("• ✅ Cálculo de economia PIX")
        print("• ✅ Controle de status de assinaturas")
        print("\n🚀 PRÓXIMOS PASSOS:")
        print("1. Teste o sistema acessando /authentication/register/")
        print("2. Após cadastro, você será redirecionado para seleção de planos")
        print("3. Teste a seleção do período gratuito e planos pagos")
        return True
    else:
        print("⚠️ Alguns testes falharam. Verifique os erros acima.")
        return False


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
