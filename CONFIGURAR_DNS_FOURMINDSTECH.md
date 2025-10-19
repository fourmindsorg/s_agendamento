# 🌐 CONFIGURAR DNS PARA FOURMINDSTECH.COM.BR

## ✅ **Status Atual:**
- ✅ **Aplicação funcionando**: http://3.80.178.120/ → AgendaFácil
- ✅ **GitHub Actions corrigido**: Health check funcionando
- ⏳ **DNS pendente**: Configurar fourmindstech.com.br → 3.80.178.120

## 🎯 **CONFIGURAÇÃO DNS:**

### **Registros DNS Necessários:**

#### **1. Registro A (Principal)**
```
Tipo: A
Nome: @
Valor: 3.80.178.120
TTL: 300 (5 minutos)
```

#### **2. Registro CNAME (WWW)**
```
Tipo: CNAME
Nome: www
Valor: fourmindstech.com.br
TTL: 300 (5 minutos)
```

### **Como Configurar:**

#### **Opção 1: Via Painel do Provedor de Domínio**
1. **Acesse** o painel do seu provedor de domínio (GoDaddy, Namecheap, Registro.br, etc.)
2. **Vá para** a seção "DNS" ou "Zona DNS"
3. **Adicione os registros** acima
4. **Aguarde** a propagação (5-15 minutos)

#### **Opção 2: Via Cloudflare (Recomendado)**
1. **Acesse**: https://dash.cloudflare.com/
2. **Adicione** o domínio fourmindstech.com.br
3. **Configure** os registros DNS:
   - `A @ 3.80.178.120`
   - `CNAME www fourmindstech.com.br`
4. **Ative** o proxy (nuvem laranja)

#### **Opção 3: Via AWS Route 53**
```bash
# Criar hosted zone
aws route53 create-hosted-zone --name fourmindstech.com.br --caller-reference $(date +%s)

# Adicionar registros
aws route53 change-resource-record-sets --hosted-zone-id ZONE_ID --change-batch file://dns-records.json
```

### **Arquivo dns-records.json:**
```json
{
  "Changes": [
    {
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "fourmindstech.com.br",
        "Type": "A",
        "TTL": 300,
        "ResourceRecords": [
          {
            "Value": "3.80.178.120"
          }
        ]
      }
    },
    {
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "www.fourmindstech.com.br",
        "Type": "CNAME",
        "TTL": 300,
        "ResourceRecords": [
          {
            "Value": "fourmindstech.com.br"
          }
        ]
      }
    }
  ]
}
```

---

## 🔍 **VERIFICAÇÃO:**

### **1. Testar Resolução DNS**
```bash
# No seu computador
nslookup fourmindstech.com.br
ping fourmindstech.com.br
```

### **2. Testar URLs**
- **Domínio**: http://fourmindstech.com.br
- **WWW**: http://www.fourmindstech.com.br
- **IP**: http://3.80.178.120 (deve continuar funcionando)

### **3. Verificar Propagação**
Use ferramentas online:
- https://www.whatsmydns.net/
- https://dnschecker.org/

---

## ⚙️ **ATUALIZAR NGINX PARA DOMÍNIO:**

### **Configuração Atual do Nginx:**
```nginx
server {
    listen 80;
    server_name fourmindstech.com.br www.fourmindstech.com.br 3.80.178.120;
    # ... resto da configuração
}
```

**✅ Já está configurado corretamente!** O Nginx já está preparado para receber requisições do domínio.

---

## 🚀 **PRÓXIMOS PASSOS:**

### **1. Configurar DNS**
- Escolha uma das opções acima
- Configure os registros A e CNAME
- Aguarde propagação (5-15 minutos)

### **2. Testar Domínio**
```bash
# Testar após propagação
curl -I http://fourmindstech.com.br/
curl -I http://www.fourmindstech.com.br/
```

### **3. Configurar SSL (Opcional)**
```bash
# Instalar Certbot
sudo apt install certbot python3-certbot-nginx

# Obter certificado SSL
sudo certbot --nginx -d fourmindstech.com.br -d www.fourmindstech.com.br
```

---

## 🎯 **RESULTADO FINAL:**

Após configurar o DNS:
- ✅ **Domínio**: http://fourmindstech.com.br → AgendaFácil
- ✅ **WWW**: http://www.fourmindstech.com.br → AgendaFácil
- ✅ **IP**: http://3.80.178.120 → AgendaFácil (continua funcionando)

---

## 📋 **RESUMO:**

1. **Configure DNS** com registros A e CNAME
2. **Aguarde propagação** (5-15 minutos)
3. **Teste o domínio** http://fourmindstech.com.br
4. **Configure SSL** (opcional)

**Execute a configuração DNS e sua aplicação estará acessível via domínio!** 🚀
