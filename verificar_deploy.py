#!/usr/bin/env python3
"""
Script para verificar e forçar deploy do sistema
"""
import requests
import time
import json


def verificar_workflow_status():
    """Verifica o status do último workflow de deploy"""
    try:
        # URL da API do GitHub para workflows
        url = "https://api.github.com/repos/fourmindsorg/s_agendamento/actions/workflows/deploy.yml/runs"

        headers = {
            "Accept": "application/vnd.github.v3+json",
            "User-Agent": "Deploy-Checker",
        }

        response = requests.get(url, headers=headers, timeout=10)

        if response.status_code == 200:
            data = response.json()
            if data.get("workflow_runs"):
                latest_run = data["workflow_runs"][0]
                status = latest_run["status"]
                conclusion = latest_run["conclusion"]

                print(f"🔄 Status do Deploy: {status}")
                print(f"📊 Conclusão: {conclusion}")
                print(f"⏰ Criado em: {latest_run['created_at']}")
                print(f"🔗 URL: {latest_run['html_url']}")

                if status == "completed" and conclusion == "success":
                    print("✅ Deploy executado com sucesso!")
                    return True
                elif status == "completed" and conclusion == "failure":
                    print("❌ Deploy falhou!")
                    return False
                elif status == "in_progress":
                    print("⏳ Deploy em andamento...")
                    return None
                else:
                    print(f"⚠️ Status desconhecido: {status} - {conclusion}")
                    return None
            else:
                print("❌ Nenhum workflow encontrado")
                return False
        else:
            print(f"❌ Erro ao verificar status: {response.status_code}")
            return False

    except Exception as e:
        print(f"❌ Erro: {e}")
        return False


def testar_site():
    """Testa se o site está respondendo"""
    try:
        url = "https://fourmindstech.com.br"
        response = requests.get(url, timeout=10)

        if response.status_code == 200:
            print("✅ Site respondendo corretamente!")
            return True
        else:
            print(f"⚠️ Site retornou status: {response.status_code}")
            return False

    except Exception as e:
        print(f"❌ Erro ao testar site: {e}")
        return False


def main():
    print("🚀 Verificando Status do Deploy...")
    print("=" * 50)

    # Verificar status do workflow
    workflow_ok = verificar_workflow_status()

    print("\n🌐 Testando Site...")
    print("=" * 50)

    # Testar site
    site_ok = testar_site()

    print("\n📋 Resumo:")
    print("=" * 50)

    if workflow_ok and site_ok:
        print("✅ TUDO FUNCIONANDO!")
        print("🌐 Site: https://fourmindstech.com.br")
        print("🔐 Admin: https://fourmindstech.com.br/admin/")
    elif workflow_ok and not site_ok:
        print("⚠️ Deploy OK, mas site com problemas")
        print("🔍 Verifique os logs do servidor")
    elif not workflow_ok:
        print("❌ Deploy não executou ou falhou")
        print("🔧 Verifique os secrets do GitHub")
        print("📖 Consulte: CONFIGURAR_SECRETS_DETALHADO.md")
    else:
        print("⏳ Deploy em andamento...")
        print("🔄 Aguarde alguns minutos e execute novamente")


if __name__ == "__main__":
    main()
