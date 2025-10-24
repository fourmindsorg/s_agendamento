#!/usr/bin/env python3
"""
Script para detecção automática e adoção de recursos AWS existentes
Sistema de Agendamento 4Minds
"""

import boto3
import json
import sys
import os
from typing import Dict, List, Optional


class AWSResourceDetector:
    def __init__(self, region: str = "us-east-1"):
        self.region = region
        self.ec2 = boto3.client("ec2", region_name=region)
        self.rds = boto3.client("rds", region_name=region)
        self.s3 = boto3.client("s3", region_name=region)
        self.route53 = boto3.client("route53", region_name=region)

    def detect_vpc(self, project_name: str) -> Optional[str]:
        """Detecta VPC existente para o projeto"""
        try:
            response = self.ec2.describe_vpcs(
                Filters=[
                    {"Name": "tag:Name", "Values": [f"{project_name}-vpc"]},
                    {"Name": "state", "Values": ["available"]},
                ]
            )

            if response["Vpcs"]:
                return response["Vpcs"][0]["VpcId"]
        except Exception as e:
            print(f"Erro ao detectar VPC: {e}")
        return None

    def detect_subnets(
        self, vpc_id: str, project_name: str
    ) -> Dict[str, Optional[str]]:
        """Detecta subnets existentes para o projeto"""
        try:
            response = self.ec2.describe_subnets(
                Filters=[
                    {"Name": "vpc-id", "Values": [vpc_id]},
                    {"Name": "state", "Values": ["available"]},
                ]
            )

            public_subnet = None
            private_subnet = None

            for subnet in response["Subnets"]:
                tags = {tag["Key"]: tag["Value"] for tag in subnet.get("Tags", [])}
                name = tags.get("Name", "")

                if "public" in name.lower() and project_name in name:
                    public_subnet = subnet["SubnetId"]
                elif "private" in name.lower() and project_name in name:
                    private_subnet = subnet["SubnetId"]

            return {"public": public_subnet, "private": private_subnet}
        except Exception as e:
            print(f"Erro ao detectar subnets: {e}")
            return {"public": None, "private": None}

    def detect_security_groups(
        self, vpc_id: str, project_name: str
    ) -> Dict[str, Optional[str]]:
        """Detecta Security Groups existentes para o projeto"""
        try:
            response = self.ec2.describe_security_groups(
                Filters=[
                    {"Name": "vpc-id", "Values": [vpc_id]},
                    {
                        "Name": "group-name",
                        "Values": [f"{project_name}-ec2-*", f"{project_name}-rds-*"],
                    },
                ]
            )

            ec2_sg = None
            rds_sg = None

            for sg in response["SecurityGroups"]:
                if "ec2" in sg["GroupName"]:
                    ec2_sg = sg["GroupId"]
                elif "rds" in sg["GroupName"]:
                    rds_sg = sg["GroupId"]

            return {"ec2": ec2_sg, "rds": rds_sg}
        except Exception as e:
            print(f"Erro ao detectar Security Groups: {e}")
            return {"ec2": None, "rds": None}

    def detect_instances(self, project_name: str) -> Optional[str]:
        """Detecta instância EC2 existente para o projeto"""
        try:
            response = self.ec2.describe_instances(
                Filters=[
                    {
                        "Name": "tag:Name",
                        "Values": [
                            f"{project_name}-server",
                            f"{project_name}-web-server",
                        ],
                    },
                    {"Name": "instance-state-name", "Values": ["running", "pending"]},
                ]
            )

            for reservation in response["Reservations"]:
                for instance in reservation["Instances"]:
                    return instance["InstanceId"]
        except Exception as e:
            print(f"Erro ao detectar instância EC2: {e}")
        return None

    def detect_rds(self, project_name: str) -> Optional[str]:
        """Detecta instância RDS existente para o projeto"""
        try:
            response = self.rds.describe_db_instances()

            for db in response["DBInstances"]:
                if project_name in db["DBInstanceIdentifier"]:
                    return db["DBInstanceIdentifier"]
        except Exception as e:
            print(f"Erro ao detectar RDS: {e}")
        return None

    def detect_s3_buckets(self, project_name: str) -> Dict[str, Optional[str]]:
        """Detecta buckets S3 existentes para o projeto"""
        try:
            response = self.s3.list_buckets()

            static_bucket = None
            media_bucket = None

            for bucket in response["Buckets"]:
                name = bucket["Name"]
                if project_name in name:
                    if "static" in name:
                        static_bucket = name
                    elif "media" in name:
                        media_bucket = name

            return {"static": static_bucket, "media": media_bucket}
        except Exception as e:
            print(f"Erro ao detectar buckets S3: {e}")
            return {"static": None, "media": None}

    def detect_internet_gateway(self, vpc_id: str, project_name: str) -> Optional[str]:
        """Detecta Internet Gateway existente para o projeto"""
        try:
            response = self.ec2.describe_internet_gateways(
                Filters=[
                    {"Name": "attachment.vpc-id", "Values": [vpc_id]},
                    {"Name": "tag:Name", "Values": [f"{project_name}-igw"]},
                ]
            )

            if response["InternetGateways"]:
                return response["InternetGateways"][0]["InternetGatewayId"]
        except Exception as e:
            print(f"Erro ao detectar Internet Gateway: {e}")
        return None

    def detect_elastic_ip(self, project_name: str) -> Optional[str]:
        """Detecta Elastic IP existente para o projeto"""
        try:
            response = self.ec2.describe_addresses(
                Filters=[{"Name": "tag:Name", "Values": [f"{project_name}-eip"]}]
            )

            if response["Addresses"]:
                return response["Addresses"][0]["AllocationId"]
        except Exception as e:
            print(f"Erro ao detectar Elastic IP: {e}")
        return None


def generate_terraform_vars(resources: Dict) -> str:
    """Gera arquivo terraform.tfvars com recursos detectados"""
    tfvars_content = f"""# ========================================
# CONFIGURAÇÃO GERADA AUTOMATICAMENTE
# Sistema de Agendamento 4Minds
# ========================================

# Configurações básicas
aws_region     = "us-east-1"
project_name   = "s-agendamento"
environment    = "production"
domain_name    = "fourmindstech.com.br"

# Configurações de rede
vpc_cidr = "10.0.0.0/16"

# Configurações de instância
instance_type = "t2.micro"

# Configurações de banco de dados
db_instance_class    = "db.t4g.micro"
db_allocated_storage = 20
db_name              = "agendamento_db"
db_username          = "agendamento_user"
db_password          = "4MindsAgendamento2025!SecureDB#Pass"

# Configurações de segurança
secret_key = "django-insecure-4minds-agendamento-2025-super-secret-key-for-production-use-only-change-this-immediately"
allowed_hosts = ["fourmindstech.com.br", "www.fourmindstech.com.br", "api.fourmindstech.com.br", "admin.fourmindstech.com.br"]
allowed_ssh_cidrs = ["0.0.0.0/0"]

# Configurações de notificação
notification_email = "admin@fourmindstech.com.br"

# Configurações de DNS
hosted_zone_id = "Z1D633PJN98FT9"
create_hosted_zone = false

# Configurações de monitoramento
enable_detailed_monitoring = false
log_retention_days = 7

# Configurações de backup
backup_retention_period = 7
backup_window = "03:00-04:00"
maintenance_window = "sun:04:00-sun:05:00"

# ========================================
# RECURSOS EXISTENTES DETECTADOS
# ========================================

adopt_existing_resources = true

# Recursos detectados automaticamente
"""

    for key, value in resources.items():
        if value:
            tfvars_content += f'{key} = "{value}"\n'
        else:
            tfvars_content += f"# {key} = null  # Não encontrado\n"

    return tfvars_content


def main():
    """Função principal"""
    print("🔍 Detectando recursos AWS existentes...")

    detector = AWSResourceDetector()
    project_name = "s-agendamento"

    # Detectar recursos
    vpc_id = detector.detect_vpc(project_name)

    resources = {"existing_vpc_id": vpc_id}

    if vpc_id:
        print(f"✅ VPC detectada: {vpc_id}")

        # Detectar subnets
        subnets = detector.detect_subnets(vpc_id, project_name)
        resources.update(
            {
                "existing_public_subnet_id": subnets["public"],
                "existing_private_subnet_id": subnets["private"],
            }
        )

        # Detectar Security Groups
        security_groups = detector.detect_security_groups(vpc_id, project_name)
        resources.update(
            {
                "existing_ec2_sg_id": security_groups["ec2"],
                "existing_rds_sg_id": security_groups["rds"],
            }
        )

        # Detectar Internet Gateway
        igw_id = detector.detect_internet_gateway(vpc_id, project_name)
        resources["existing_igw_id"] = igw_id

        if subnets["public"]:
            print(f"✅ Subnet pública detectada: {subnets['public']}")
        if subnets["private"]:
            print(f"✅ Subnet privada detectada: {subnets['private']}")
        if security_groups["ec2"]:
            print(f"✅ Security Group EC2 detectado: {security_groups['ec2']}")
        if security_groups["rds"]:
            print(f"✅ Security Group RDS detectado: {security_groups['rds']}")
        if igw_id:
            print(f"✅ Internet Gateway detectado: {igw_id}")
    else:
        print("ℹ️  Nenhuma VPC existente detectada")

    # Detectar outros recursos
    instance_id = detector.detect_instances(project_name)
    resources["existing_instance_id"] = instance_id
    if instance_id:
        print(f"✅ Instância EC2 detectada: {instance_id}")

    db_instance_id = detector.detect_rds(project_name)
    resources["existing_db_instance_id"] = db_instance_id
    if db_instance_id:
        print(f"✅ RDS detectado: {db_instance_id}")

    buckets = detector.detect_s3_buckets(project_name)
    resources.update(
        {
            "existing_static_bucket_name": buckets["static"],
            "existing_media_bucket_name": buckets["media"],
        }
    )
    if buckets["static"]:
        print(f"✅ Bucket S3 estático detectado: {buckets['static']}")
    if buckets["media"]:
        print(f"✅ Bucket S3 mídia detectado: {buckets['media']}")

    eip_id = detector.detect_elastic_ip(project_name)
    resources["existing_eip_id"] = eip_id
    if eip_id:
        print(f"✅ Elastic IP detectado: {eip_id}")

    # Gerar arquivo terraform.tfvars
    tfvars_content = generate_terraform_vars(resources)

    with open("terraform.tfvars.auto", "w") as f:
        f.write(tfvars_content)

    print(f"\n✅ Arquivo terraform.tfvars.auto gerado com recursos detectados")
    print(f"📝 Resumo dos recursos detectados:")

    for key, value in resources.items():
        status = "✅" if value else "❌"
        print(f"   {status} {key}: {value or 'Não encontrado'}")

    print(f"\n🚀 Para usar os recursos detectados, execute:")
    print(f"   terraform plan -var-file='terraform.tfvars.auto'")
    print(f"   terraform apply -var-file='terraform.tfvars.auto'")


if __name__ == "__main__":
    main()

