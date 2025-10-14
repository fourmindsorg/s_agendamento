# 🌐 CONFIGURAR DNS - fourmindstech.com.br

## 📋 INFORMAÇÕES NECESSÁRIAS

**IP da EC2:** `13.221.138.11`  
**Domínio:** `fourmindstech.com.br`  
**Provedor:** Registro.br (provavelmente)

---

## 🚀 PASSO A PASSO

### PASSO 1: Acessar Painel do Registro.br

1. Acesse: https://registro.br/
2. Faça login com suas credenciais
3. Vá em **"Meus Domínios"**
4. Clique em **fourmindstech.com.br**

---

### PASSO 2: Configurar DNS

#### Opção A: Se Usar DNS do Registro.br

1. Clique em **"DNS"** ou **"Configurar DNS"**
2. Escolha **"Usar servidores DNS do Registro.br"**
3. Clique em **"Editar Zona"**

#### Opção B: Se Usar Outro Provedor (Cloudflare, etc)

Acesse o painel do provedor de DNS que você usa.

---

### PASSO 3: Adicionar Registros DNS

**Adicione 2 registros tipo A:**

#### Registro 1: Domínio Principal (@)
```
Tipo: A
Nome: @ (ou deixe em branco, ou fourmindstech.com.br)
Valor: 13.221.138.11
TTL: 300 (5 minutos)
```

#### Registro 2: Subdomínio WWW
```
Tipo: A
Nome: www
Valor: 13.221.138.11
TTL: 300 (5 minutos)
```

**Clique em Salvar/Adicionar**

---

### PASSO 4: Aguardar Propagação DNS

**Tempo:** 5-30 minutos (geralmente ~10 minutos)

**Verificar no seu Windows:**

```bash
# Testar DNS
nslookup fourmindstech.com.br

# Deve retornar:
# Name:    fourmindstech.com.br
# Address: 13.221.138.11
```

**Ou use ferramentas online:**
- https://www.whatsmydns.net/
- Digite: `fourmindstech.com.br`
- Tipo: `A`
- Deve mostrar: `13.221.138.11` em vários locais

---

### PASSO 5: Testar Domínio

**No seu Windows:**

```bash
# Testar health check
curl http://fourmindstech.com.br/health/

# Esperado: {"status":"ok",...}
```

**No navegador:**
```
http://fourmindstech.com.br/admin/
```

**Se abrir = DNS FUNCIONANDO!** ✅

---

## 🔒 PASSO 6: Configurar SSL (HTTPS)

Após DNS funcionar, no servidor:

```bash
# Instalar certificado SSL gratuito (Let's Encrypt)
sudo certbot --nginx \
  -d fourmindstech.com.br \
  -d www.fourmindstech.com.br \
  --email fourmindsorg@gmail.com \
  --agree-tos \
  --non-interactive \
  --redirect
```

**Tempo:** ~2-3 minutos

**Resultado esperado:**
```
Successfully received certificate.
Certificate is saved at: /etc/letsencrypt/live/fourmindstech.com.br/fullchain.pem
...
Redirecting all traffic on port 80 to ssl in /etc/nginx/sites-enabled/agendamento-4minds
```

---

### PASSO 7: Atualizar .env.production para HTTPS

```bash
# Voltar para django
sudo su - django

# Ir para app
cd ~/app

# Editar .env
nano .env.production
```

**Altere estas linhas:**
```bash
HTTPS_REDIRECT=True
SECURE_SSL_REDIRECT=True
SECURE_PROXY_SSL_HEADER=True
SESSION_COOKIE_SECURE=True
CSRF_COOKIE_SECURE=True
```

**Salvar:** Ctrl+X → Y → Enter

```bash
# Sair
exit

# Reiniciar
sudo supervisorctl restart gunicorn
```

---

### PASSO 8: Testar HTTPS

**No navegador:**
```
https://fourmindstech.com.br/
https://fourmindstech.com.br/admin/
```

**Deve mostrar:**
- ✅ Cadeado verde (SSL válido)
- ✅ HTTPS ativo
- ✅ Redirecionamento automático de HTTP → HTTPS

---

## ✅ VALIDAÇÃO FINAL

### Checklist:

- [ ] DNS tipo A criado para @
- [ ] DNS tipo A criado para www
- [ ] DNS propagado (nslookup funciona)
- [ ] HTTP funciona (fourmindstech.com.br)
- [ ] SSL instalado (certbot)
- [ ] HTTPS funciona (https://fourmindstech.com.br)
- [ ] Cadeado verde no navegador
- [ ] Admin acessível via HTTPS
- [ ] Login funciona

---

## 🎯 RESULTADO FINAL

Quando tudo estiver pronto:

✅ **https://fourmindstech.com.br/** - Site em produção  
✅ **https://fourmindstech.com.br/admin/** - Admin Django  
✅ SSL válido (Let's Encrypt)  
✅ Custo: $0/mês (Free Tier)  
✅ **SISTEMA EM PRODUÇÃO!** 🎉

---

## 📞 SUPORTE

Problemas com DNS?
- Registro.br: https://registro.br/suporte
- Verificar propagação: https://www.whatsmydns.net/

---

**Criado:** Outubro 2025  
**Status:** Pronto para uso

