# 🔧 RESOLVER WORKFLOW "Deploy to EC2" NÃO APARECER

## ❌ **Problema Identificado:**
O workflow "Deploy to EC2" não aparece em https://github.com/fourmindsorg/s_agendamento/actions

---

## 🎯 **SOLUÇÕES:**

### **SOLUÇÃO 1: Workflow Simples (RECOMENDADO)**

#### **1.1 Workflow Criado**
Criei um workflow mais simples: `.github/workflows/deploy-simple.yml`

#### **1.2 Características**
- ✅ **Trigger manual**: `workflow_dispatch`
- ✅ **Trigger automático**: Push para `main`
- ✅ **Deploy direto**: Sem testes (mais rápido)
- ✅ **Health check**: Verifica se aplicação está funcionando

#### **1.3 Como Executar**
1. **Acesse**: https://github.com/fourmindsorg/s_agendamento/actions
2. **Procure por**: "Deploy to EC2" (deve aparecer agora)
3. **Clique em**: "Run workflow"
4. **Selecione**: branch "main"
5. **Clique em**: "Run workflow"

### **SOLUÇÃO 2: Verificar GitHub Secrets**

#### **2.1 Acessar Secrets**
1. **Acesse**: https://github.com/fourmindsorg/s_agendamento/settings/secrets/actions
2. **Verifique se existem**:
   - `EC2_HOST`: `3.80.178.120`
   - `EC2_USERNAME`: `ubuntu`
   - `EC2_PORT`: `22`
   - `EC2_SSH_KEY`: Chave privada SSH

#### **2.2 Se não existirem, adicione**:
- Clique em **"New repository secret"**
- Adicione cada um dos secrets acima

### **SOLUÇÃO 3: Executar Deploy Manual Primeiro**

#### **3.1 Acessar Console EC2**
1. **Acesse**: https://console.aws.amazon.com/ec2/
2. **Vá para**: Instances → `i-029805f836fb2f238`
3. **Clique em**: Connect → EC2 Instance Connect

#### **3.2 Executar Deploy**
```bash
curl -s https://raw.githubusercontent.com/fourmindsorg/s_agendamento/main/configurar_tudo_completo.sh | bash
```

### **SOLUÇÃO 4: Forçar Execução do Workflow**

#### **4.1 Fazer Push para Trigger**
```bash
# No seu computador local
git add .
git commit -m "trigger: Force workflow execution"
git push origin main
```

#### **4.2 Ou usar Trigger Manual**
1. **Acesse**: https://github.com/fourmindsorg/s_agendamento/actions
2. **Clique em**: "Deploy to EC2"
3. **Clique em**: "Run workflow"

---

## 🔍 **VERIFICAÇÃO:**

### **1. Workflows Disponíveis**
- ✅ **deploy.yml**: Workflow completo com testes
- ✅ **deploy-simple.yml**: Workflow simples (novo)
- ✅ **Outros workflows**: ci.yml, terraform.yml, etc.

### **2. URLs para Verificar**
- **Actions**: https://github.com/fourmindsorg/s_agendamento/actions
- **Secrets**: https://github.com/fourmindsorg/s_agendamento/settings/secrets/actions
- **Workflow**: https://github.com/fourmindsorg/s_agendamento/.github/workflows/deploy-simple.yml

### **3. Status Esperado**
- ✅ Workflow aparece na lista
- ✅ Pode ser executado manualmente
- ✅ Executa sem erros de SSH
- ✅ Deploy funciona corretamente

---

## 🚨 **TROUBLESHOOTING:**

### **Problema: Workflow ainda não aparece**
- Aguarde alguns minutos (GitHub pode demorar)
- Verifique se o arquivo foi commitado corretamente
- Confirme se está na branch `main`

### **Problema: Erro "missing server host"**
- Configure os GitHub Secrets
- Verifique se `EC2_HOST` está definido

### **Problema: SSH authentication failed**
- Execute o script de geração de chaves
- Configure `EC2_SSH_KEY` com a chave privada

### **Problema: Deploy falha**
- Execute deploy manual primeiro
- Verifique se a EC2 está rodando
- Confirme se os serviços estão ativos

---

## 🎯 **EXECUÇÃO IMEDIATA:**

### **Opção 1: Usar Workflow Simples**
1. **Acesse**: https://github.com/fourmindsorg/s_agendamento/actions
2. **Procure por**: "Deploy to EC2"
3. **Execute**: Workflow manualmente

### **Opção 2: Deploy Manual**
1. **Acesse**: Console EC2
2. **Execute**: `curl -s https://raw.githubusercontent.com/fourmindsorg/s_agendamento/main/configurar_tudo_completo.sh | bash`

### **Opção 3: Configurar Secrets Primeiro**
1. **Acesse**: https://github.com/fourmindsorg/s_agendamento/settings/secrets/actions
2. **Configure**: EC2_HOST, EC2_USERNAME, EC2_PORT, EC2_SSH_KEY
3. **Execute**: Workflow

---

## ✅ **RESUMO:**

1. ✅ **Workflow simples criado**: `deploy-simple.yml`
2. ⏳ **Aguardando**: Configuração de GitHub Secrets
3. ⏳ **Aguardando**: Execução do workflow
4. ⏳ **Aguardando**: Deploy manual (se necessário)

**Execute o workflow simples ou configure os secrets primeiro!** 🚀
