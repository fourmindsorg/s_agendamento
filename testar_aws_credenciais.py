#!/usr/bin/env python3
"""
Script para testar credenciais AWS e conectividade
"""
import boto3
import subprocess
import sys
import os

def testar_aws_credenciais():
    """Testa se as credenciais AWS estão funcionando"""
    try:
        # Configurar credenciais via variáveis de ambiente
        aws_access_key_id = os.environ.get("AWS_ACCESS_KEY_ID")
        aws_secret_access_key = os.environ.get("AWS_SECRET_ACCESS_KEY")
        
        if not aws_access_key_id or not aws_secret_access_key:
            print("❌ Credenciais AWS não encontradas nas variáveis de ambiente")
            print("📝 Configure AWS_ACCESS_KEY_ID e AWS_SECRET_ACCESS_KEY")
            return False
        
        # Criar cliente EC2
        ec2 = boto3.client(
            'ec2',
            aws_access_key_id=aws_access_key_id,
            aws_secret_access_key=aws_secret_access_key,
            region_name='us-east-1'
        )
        
        # Testar listagem de instâncias
        response = ec2.describe_instances()
        
        print("✅ Credenciais AWS funcionando!")
        print(f"📊 Encontradas {len(response['Reservations'])} reservas de instâncias")
        
        # Procurar pela instância do projeto
        for reservation in response['Reservations']:
            for instance in reservation['Instances']:
                if instance['State']['Name'] == 'running':
                    public_ip = instance.get('PublicIpAddress', 'N/A')
                    instance_id = instance['InstanceId']
                    print(f"🖥️  Instância: {instance_id}")
                    print(f"🌐 IP Público: {public_ip}")
                    
                    # Testar conectividade SSH
                    if public_ip != 'N/A':
                        testar_ssh(public_ip)
        
        return True
        
    except Exception as e:
        print(f"❌ Erro com credenciais AWS: {e}")
        return False

def testar_ssh(ip):
    """Testa conectividade SSH"""
    try:
        print(f"\n🔑 Testando SSH para {ip}...")
        
        # Testar conectividade básica
        result = subprocess.run(
            f"ssh -o ConnectTimeout=10 -o BatchMode=yes ubuntu@{ip} 'echo SSH OK'",
            shell=True,
            capture_output=True,
            text=True,
            timeout=15
        )
        
        if result.returncode == 0:
            print("✅ SSH funcionando!")
            return True
        else:
            print(f"❌ SSH falhou: {result.stderr}")
            return False
            
    except Exception as e:
        print(f"❌ Erro SSH: {e}")
        return False

def testar_github_secrets():
    """Testa se os secrets do GitHub estão configurados"""
    print("\n🔐 Verificando secrets do GitHub...")
    print("📝 Secrets necessários:")
    print("- AWS_ACCESS_KEY_ID")
    print("- AWS_SECRET_ACCESS_KEY") 
    print("- EC2_SSH_KEY")
    print("- DB_PASSWORD")
    print("- DB_HOST")
    
    print("\n✅ Para verificar se estão configurados:")
    print("1. Acesse: https://github.com/fourmindsorg/s_agendamento/settings/secrets/actions")
    print("2. Verifique se todos os secrets estão presentes")
    print("3. Se algum estiver faltando, adicione-o")

def main():
    print("🚀 Testando Configuração AWS e Deploy")
    print("=" * 50)
    
    # Testar credenciais AWS
    aws_ok = testar_aws_credenciais()
    
    # Testar GitHub secrets
    testar_github_secrets()
    
    print("\n📋 Resumo:")
    print("=" * 50)
    
    if aws_ok:
        print("✅ Credenciais AWS funcionando")
        print("🔧 Verifique os secrets do GitHub Actions")
        print("🔄 Execute o workflow manualmente se necessário")
    else:
        print("❌ Problema com credenciais AWS")
        print("🔧 Verifique as chaves de acesso")

if __name__ == "__main__":
    main()
