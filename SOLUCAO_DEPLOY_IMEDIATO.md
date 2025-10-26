# 🚀 Solução Rápida para Deploy

## ⚠️ Problema Atual

A instância EC2 está **parada** ou não está acessível via SSM.

## ✅ Solução Imediata

### Opção 1: Iniciar Instância e Deploy Automático (Recomendado)

Execute este comando para iniciar a instância:

```bash
aws ec2 start-instances --instance-ids i-0077873407e4114b1
```

Depois, aguarde 1-2 minutos e faça um novo commit:

```bash
git add .
git commit -m "Trigger deploy"
git push origin main
```

O GitHub Actions agora irá:
1. ✅ Detectar que a instância está parada
2. ✅ Iniciar a instância automaticamente
3. ✅ Aguardar SSM ficar online
4. ✅ Fazer o deploy automaticamente

### Opção 2: Deploy Manual Imediato (via SSH)

Se você tem chave SSH configurada:

```bash
# 1. Iniciar instância
aws ec2 start-instances --instance-ids i-0077873407e4114b1

# 2. Aguardar iniciar (1-2 minutos)
aws ec2 wait instance-running --instance-ids i-0077873407e4114b1

# 3. Obter IP público
IP=$(aws ec2 describe-instances \
  --instance-ids i-0077873407e4114b1 \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

echo "IP: $IP"

# 4. Conectar e fazer deploy
ssh ubuntu@$IP "cd /opt/s-agendamento && sudo bash infrastructure/deploy_completo.sh"
```

### Opção 3: Deploy Manual via SSM (Melhor Opção)

```bash
# 1. Iniciar instância
aws ec2 start-instances --instance-ids i-0077873407e4114b1

# 2. Aguardar iniciar
aws ec2 wait instance-running --instance-ids i-0077873407e4114b1

# 3. Aguardar SSM (30-60s)
sleep 60

# 4. Conectar via SSM e fazer deploy
aws ssm start-session --target i-0077873407e4114b1

# Dentro da sessão SSM:
cd /opt/s-agendamento
sudo bash infrastructure/deploy_completo.sh
```

## 🔍 Verificar Estado Atual

Para ver o estado da instância:

```bash
aws ec2 describe-instances \
  --instance-ids i-0077873407e4114b1 \
  --query 'Reservations[0].Instances[0].[State.Name,PublicIpAddress,LaunchTime]' \
  --output table
```

Possíveis estados:
- **running**: ✅ Tudo OK, pode fazer deploy
- **stopped**: 🔴 Instância parada, precisa iniciar
- **stopping**: ⏳ Parando, aguarde antes de iniciar
- **pending**: ⏳ Iniciando, aguarde
- **terminated**: ❌ Instância foi deletada

## 💰 Por que a instância para?

Instâncias EC2 podem ser paradas por:
1. **Horas de inatividade** (economize custos)
2. **Limite de credito AWS** (Free Tier)
3. **Parada manual** para economizar

## 🎯 Arquivos Atualizados

- ✅ `.github/workflows/deploy.yml` - Agora tenta iniciar a instância automaticamente
- ✅ `.github/workflows/deploy-manual.yml` - Instruções de deploy manual
- ✅ Todos os testes corrigidos

## 📝 Próximos Passos

Depois de iniciar a instância:

1. Faça um push para trigger automático:
   ```bash
   git push origin main
   ```

2. Ou faça deploy manual usando uma das opções acima

3. Teste o site:
   - HTTP: http://52.91.139.151
   - HTTPS: https://fourmindstech.com.br

## ⚙️ Configurar Deploy Automático Permanente

Para evitar que a instância pare, configure no GitHub:

1. **Settings** → **Secrets and variables** → **Actions**
2. Adicione `AWS_ACCESS_KEY_ID` e `AWS_SECRET_ACCESS_KEY`
3. O workflow agora iniciará a instância automaticamente quando necessário

