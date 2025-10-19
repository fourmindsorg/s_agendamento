# 🔧 SOLUÇÃO PARA ERRO 502 E CONFIGURAÇÃO DNS

## ❌ **Problemas Identificados:**
1. **Erro 502 Bad Gateway**: Nginx está rodando mas Gunicorn (Django) não está funcionando
2. **DNS não configurado**: fourmindstech.com.br não aponta para 3.80.178.120

## 🎯 **SOLUÇÃO 1: Corrigir Erro 502**

### **Execute na EC2 via Console AWS:**

#### **1. Conectar na EC2**
1. Acesse: https://console.aws.amazon.com/ec2/
2. Vá para **Instances**
3. Selecione a instância `i-029805f836fb2f238`
4. Clique em **Connect** → **EC2 Instance Connect**

#### **2. Executar Script de Correção**
```bash
# Baixar e executar script de correção
curl -s https://raw.githubusercontent.com/fourmindsorg/s_agendamento/main/corrigir_502.sh | bash
```

#### **3. Ou executar comandos individuais**
```bash
# Verificar status atual
sudo systemctl status gunicorn
sudo systemctl status nginx

# Parar serviços
sudo systemctl stop gunicorn
sudo systemctl stop nginx

# Navegar para o projeto
cd /home/ubuntu/s_agendamento

# Ativar ambiente virtual
source .venv/bin/activate

# Executar migrações
python manage.py migrate

# Coletar arquivos estáticos
python manage.py collectstatic --noinput

# Iniciar Gunicorn manualmente para testar
gunicorn --bind 0.0.0.0:8000 core.wsgi:application &

# Testar aplicação
curl -I http://localhost:8000/
```

---

## 🌐 **SOLUÇÃO 2: Configurar DNS**

### **Registros DNS Necessários:**
```
Tipo: A
Nome: @
Valor: 3.80.178.120
TTL: 300

Tipo: CNAME
Nome: www
Valor: fourmindstech.com.br
TTL: 300
```

### **Como Configurar DNS:**

#### **1. Acessar Painel DNS**
- Entre no painel do seu provedor de domínio
- Vá para a seção "DNS" ou "Zona DNS"

#### **2. Adicionar Registros**
- **Registro A**: `@ → 3.80.178.120`
- **Registro CNAME**: `www → fourmindstech.com.br`

#### **3. Aguardar Propagação**
- Aguarde 5-15 minutos para propagação
- Teste: `ping fourmindstech.com.br`

---

## 🔍 **VERIFICAÇÃO E TESTES**

### **1. Testar IP Direto**
```bash
# Testar se aplicação está funcionando no IP
curl -I http://3.80.178.120/
```

**Resultado esperado:**
```
HTTP/1.1 200 OK
Server: nginx/1.18.0 (Ubuntu)
```

### **2. Testar Domínio (após configurar DNS)**
```bash
# Testar domínio
curl -I http://fourmindstech.com.br/
```

### **3. Verificar Logs**
```bash
# Logs do Gunicorn
sudo journalctl -u gunicorn -f

# Logs do Nginx
sudo journalctl -u nginx -f
```

---

## 🚨 **TROUBLESHOOTING**

### **Problema: Ainda erro 502**
```bash
# Verificar se Gunicorn está rodando
ps aux | grep gunicorn

# Verificar socket
ls -la /home/ubuntu/s_agendamento/gunicorn.sock

# Reiniciar Gunicorn
sudo systemctl restart gunicorn
```

### **Problema: DNS não resolve**
- Aguarde mais tempo (até 24h)
- Verifique se os registros DNS estão corretos
- Use `nslookup fourmindstech.com.br` para verificar

### **Problema: Aplicação não carrega**
```bash
# Verificar se Django está funcionando
cd /home/ubuntu/s_agendamento
source .venv/bin/activate
python manage.py runserver 0.0.0.0:8000
```

---

## ✅ **CHECKLIST DE SOLUÇÃO**

### **Para Erro 502:**
- [ ] Conectado na EC2 via Console AWS
- [ ] Executado script de correção
- [ ] Gunicorn rodando e ativo
- [ ] Nginx configurado corretamente
- [ ] Aplicação respondendo em http://3.80.178.120

### **Para DNS:**
- [ ] Registro A configurado (@ → 3.80.178.120)
- [ ] Registro CNAME configurado (www → fourmindstech.com.br)
- [ ] Aguardado propagação DNS (5-15 min)
- [ ] Testado resolução: `nslookup fourmindstech.com.br`
- [ ] Aplicação acessível via http://fourmindstech.com.br

---

## 🎯 **URLs FINAIS**

Após correção completa:
- **IP**: http://3.80.178.120 ✅
- **Domínio**: http://fourmindstech.com.br (após DNS)
- **Admin**: http://3.80.178.120/admin
- **Usuário**: admin | **Senha**: admin123

---

## 🚀 **PRÓXIMOS PASSOS**

1. **Execute o script de correção** na EC2
2. **Configure o DNS** no seu provedor
3. **Teste as URLs** após cada etapa
4. **Verifique logs** se houver problemas

**Siga estas instruções e a aplicação estará funcionando!** 🎉
