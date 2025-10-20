# 🔧 ATUALIZAR DNS FOURMINDSTECH.COM.BR

## ❌ **Problema Identificado:**
```
nslookup fourmindstech.com.br
Nome: fourmindstech.com.br
Address: 13.221.138.11  ← IP ANTIGO
```

**Deveria ser**: `3.80.178.120` ← IP NOVO

## 🎯 **SOLUÇÃO:**

### **ATUALIZAR REGISTRO DNS:**

#### **1. Acessar Painel DNS**
- **Acesse** o painel do seu provedor de domínio
- **Vá para** a seção "DNS" ou "Zona DNS"

#### **2. Atualizar Registro A**
```
Tipo: A
Nome: @ (ou fourmindstech.com.br)
Valor: 3.80.178.120  ← NOVO IP
TTL: 300 (5 minutos)
```

#### **3. Verificar Registro CNAME**
```
Tipo: CNAME
Nome: www
Valor: fourmindstech.com.br
TTL: 300 (5 minutos)
```

### **OPÇÕES DE PROVEDOR DNS:**

#### **Opção 1: Cloudflare (Recomendado)**
1. **Acesse**: https://dash.cloudflare.com/
2. **Selecione** o domínio fourmindstech.com.br
3. **Vá para** DNS → Records
4. **Edite** o registro A:
   - Name: `@`
   - IPv4 address: `3.80.178.120`
   - TTL: `Auto` ou `300`
5. **Salve** as alterações

#### **Opção 2: AWS Route 53**
```bash
# Listar hosted zones
aws route53 list-hosted-zones

# Atualizar registro A
aws route53 change-resource-record-sets --hosted-zone-id ZONE_ID --change-batch file://update-dns.json
```

#### **Opção 3: Outros Provedores**
- **GoDaddy**: DNS Management → A Records
- **Namecheap**: Advanced DNS → A Record
- **Registro.br**: Zona DNS → Registro A

---

## 🔍 **VERIFICAÇÃO:**

### **1. Testar Resolução DNS**
```bash
# Aguardar propagação (5-15 minutos)
nslookup fourmindstech.com.br
ping fourmindstech.com.br
```

### **2. Resultado Esperado**
```
nslookup fourmindstech.com.br
Nome: fourmindstech.com.br
Address: 3.80.178.120  ← IP CORRETO
```

### **3. Testar URLs**
```bash
# Testar após propagação
curl -I http://fourmindstech.com.br/
curl -I http://www.fourmindstech.com.br/
```

### **4. Verificar Propagação Global**
Use ferramentas online:
- https://www.whatsmydns.net/
- https://dnschecker.org/
- https://dns.google/query?name=fourmindstech.com.br&type=A

---

## ⚡ **CORREÇÃO RÁPIDA:**

### **Se você tem acesso ao painel DNS:**

1. **Entre** no painel do seu provedor de domínio
2. **Localize** o registro A para `@` ou `fourmindstech.com.br`
3. **Altere** o valor de `13.221.138.11` para `3.80.178.120`
4. **Salve** as alterações
5. **Aguarde** 5-15 minutos para propagação

### **Comando para verificar:**
```bash
# Verificar se o DNS foi atualizado
nslookup fourmindstech.com.br
ping fourmindstech.com.br

# Testar aplicação
curl -I http://fourmindstech.com.br/
```

---

## 🚨 **TROUBLESHOOTING:**

### **Problema: DNS não atualiza**
- Aguarde mais tempo (até 24h para propagação completa)
- Verifique se o TTL está baixo (300 segundos)
- Use diferentes servidores DNS para testar

### **Problema: Ainda aponta para IP antigo**
- Verifique se há cache DNS local
- Limpe cache DNS: `ipconfig /flushdns` (Windows)
- Use DNS público: `8.8.8.8` ou `1.1.1.1`

### **Problema: Domínio não resolve**
- Verifique se o registro A está correto
- Confirme se o domínio está ativo
- Verifique se não há conflitos de registros

---

## 🎯 **RESULTADO FINAL:**

Após atualizar o DNS:
- ✅ **DNS**: fourmindstech.com.br → 3.80.178.120
- ✅ **Aplicação**: http://fourmindstech.com.br → AgenTech
- ✅ **WWW**: http://www.fourmindstech.com.br → AgenTech

---

## 📋 **RESUMO:**

1. **Acesse** o painel DNS do seu provedor
2. **Atualize** o registro A de `13.221.138.11` para `3.80.178.120`
3. **Aguarde** propagação (5-15 minutos)
4. **Teste** o domínio http://fourmindstech.com.br

**Execute a atualização DNS e sua aplicação estará acessível via domínio!** 🚀
