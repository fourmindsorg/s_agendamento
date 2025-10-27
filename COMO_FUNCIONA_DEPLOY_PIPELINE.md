# 🔄 Como Funciona o Pipeline de Deploy

## 📊 Fluxo Completo de Deploy

O pipeline GitHub Actions para o "Deploy to Production" funciona assim:

```
Push para main
    ↓
┌─────────────────────────────────────┐
│ 1️⃣ EXECUTAR TESTES                  │
│    - Django checks                   │
│    - Unit tests                      │
│    - Verificar código                │
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│ 2️⃣ CONFIGURAR AWS                   │
│    - AWS credentials                 │
│    - Verificar instância EC2         │
│    - Iniciar se estiver parada       │
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│ 3️⃣ VERIFICAR SSM                    │
│    - Tentar conectar via SSM Agent  │
│    - Aguardar até 3 minutos          │
│    - Se online → SSM = true          │
│    - Se offline → SSM = false        │
└─────────────────────────────────────┘
    ↓
    ├─→ SSM ONLINE ──┐
    │                │
    │    ┌───────────────────────┐
    │    │ Deploy via SSM       │
    │    │ - AWS RunShellScript  │
    │    │ - Monitorar status    │
    │    │ - Aguardar conclusão │
    │    └───────────────────────┘
    │
    └─→ SSM OFFLINE ──┐
                      │
         ┌────────────────────────┐
         │ 1. Obter IP público   │
         │ 2. Configurar SSH     │
         │ 3. Testar conexão     │
         │ 4. Deploy via SSH     │
         └────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│ 4️⃣ HEALTH CHECK                     │
│    - Testar HTTP                    │
│    - Testar HTTPS                   │
│    - Testar endpoints               │
└─────────────────────────────────────┘
```

## 🔍 Detalhamento do Processo

### **Opção A: Deploy via SSM (Preferencial)**

Quando **SSM Agent está online**:

```yaml
# .github/workflows/deploy.yml (linhas ~172-238)

- name: Deploy to EC2 via SSM
  if: env.SSM_ONLINE == 'true'
  run: |
    aws ssm send-command \
      --instance-ids "i-0077873407e4114b1" \
      --document-name "AWS-RunShellScript" \
      --parameters 'commands=[
        "cd /opt/s-agendamento",
        "git fetch origin",
        "git reset --hard origin/main",
        "source venv/bin/activate",
        "pip install -r requirements.txt --upgrade",
        "python manage.py migrate",
        "python manage.py collectstatic --noinput",
        "sudo supervisorctl restart s-agendamento",
        "sudo systemctl reload nginx"
      ]' \
      --timeout-seconds 600
```

**Vantagens:**
- ✅ Não precisa de chave SSH
- ✅ Mais seguro (autenticação via IAM)
- ✅ Não requer acesso à porta 22
- ✅ Logs disponíveis no AWS Console

**Desvantagens:**
- ❌ Requer SSM Agent instalado e rodando
- ❌ Pode levar tempo para ficar online após boot

### **Opção B: Deploy via SSH (Fallback)**

Quando **SSM Agent NÃO está online**:

```yaml
# .github/workflows/deploy.yml (linhas ~240-306)

- name: Get EC2 IP
  if: env.SSM_ONLINE != 'true'
  run: |
    # Obter IP público da instância
    PUBLIC_IP=$(aws ec2 describe-instances \
      --instance-ids "i-0077873407e4114b1" \
      --query "Reservations[0].Instances[0].PublicIpAddress" \
      --output text)

- name: Setup SSH
  if: env.SSM_ONLINE != 'true'
  run: |
    mkdir -p ~/.ssh
    echo "${{ secrets.EC2_SSH_KEY }}" > ~/.ssh/id_rsa
    chmod 600 ~/.ssh/id_rsa
    ssh-keyscan -H $EC2_IP >> ~/.ssh/known_hosts

- name: Deploy to EC2 via SSH
  if: env.SSM_ONLINE != 'true'
  run: |
    ssh -i ~/.ssh/id_rsa ec2-user@$EC2_IP << 'EOF'
      cd /opt/s-agendamento
      git fetch origin
      git reset --hard origin/main
      source venv/bin/activate
      pip install -r requirements.txt --upgrade
      python manage.py migrate
      python manage.py collectstatic --noinput
      sudo supervisorctl restart s-agendamento
      sudo systemctl reload nginx
    EOF
```

**Vantagens:**
- ✅ Funciona mesmo sem SSM
- ✅ Mais rápido (geralmente)
- ✅ Direto no servidor

**Desvantagens:**
- ❌ Requer chave SSH configurada como secret
- ❌ Requer porta 22 aberta no Security Group
- ❌ Menos seguro que SSM

## 🎯 Como o Sistema Decide?

O workflow verifica SSM assim:

```bash
# Linhas ~120-168 do deploy.yml

# Aguardar SSM Agent ficar online (até 3 minutos)
MAX_WAIT=180
WAITED=0
SSM_STATUS="Unknown"

while [ $WAITED -lt $MAX_WAIT ]; do
  SSM_STATUS=$(aws ssm describe-instance-information \
    --filters "Key=InstanceIds,Values=$INSTANCE_ID" \
    --query "InstanceInformationList[0].PingStatus" \
    --output text)
  
  if [ "$SSM_STATUS" = "Online" ]; then
    echo "SSM_ONLINE=true" >> $GITHUB_ENV
    break
  fi
  
  sleep 5
  WAITED=$((WAITED + 5))
done

if [ "$SSM_STATUS" != "Online" ]; then
  echo "SSM_ONLINE=false" >> $GITHUB_ENV
fi
```

## 📋 Comandos Executados no Servidor

**Ambos os métodos executam os mesmos comandos:**

```bash
cd /opt/s-agendamento                    # Ir para o diretório
git fetch origin                          # Buscar código
git reset --hard origin/main              # Atualizar código
source venv/bin/activate                  # Ativar venv
pip install -r requirements.txt --upgrade # Instalar dependências
python manage.py migrate                  # Aplicar migrações
python manage.py collectstatic --noinput  # Coletar estáticos
sudo supervisorctl restart s-agendamento # Reiniciar Gunicorn
sudo systemctl reload nginx              # Recarregar Nginx
```

## 🔐 Segurança

### **SSM (Systems Manager)**
- Autenticação via IAM
- Sem chaves SSH no GitHub
- Sem necessidade de portas abertas
- Logs no AWS CloudWatch

### **SSH (Secure Shell)**
- Requer chave SSH no secret
- Porta 22 deve estar aberta
- Autenticação via chave privada
- Logs no GitHub Actions

## 📊 Monitoramento

Após o deploy, o workflow executa health checks:

```bash
# Testar HTTP
curl -f -s --max-time 10 http://fourmindstech.com.br/

# Testar HTTPS
curl -f -s --max-time 10 https://fourmindstech.com.br/

# Testar endpoint específico
curl -f -s --max-time 10 https://fourmindstech.com.br/authentication/planos/
```

## ✅ Resultado Final

Ambos os métodos produzem o mesmo resultado:
- ✅ Código atualizado do GitHub
- ✅ Dependências instaladas
- ✅ Migrações aplicadas
- ✅ Arquivos estáticos coletados
- ✅ Serviços reiniciados
- ✅ Aplicação funcionando

## 🚀 Próximos Passos

Para fazer deploy:
1. **Commit suas mudanças:**
   ```bash
   git add .
   git commit -m "Your changes"
   git push origin main
   ```

2. **O pipeline executa automaticamente:**
   - Tenta SSM primeiro
   - Usa SSH se SSM não estiver disponível
   - Deploy automático!

3. **Monitor o resultado:**
   - Acesse: https://github.com/fourmindsorg/s_agendamento/actions
   - Veja os logs em tempo real
   - Verifique o status do deploy

## 💡 Dicas

**Para melhor performance:**
- Configure SSM Agent se possível
- Mantenha o secret EC2_SSH_KEY atualizado
- Monitore os logs do GitHub Actions

**Se o deploy falhar:**
- Verifique os logs do GitHub Actions
- Confirme que a instância EC2 está rodando
- Verifique se o secret está configurado corretamente

