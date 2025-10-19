# 🌐 Configuração do Domínio Personalizado

## 📋 Configuração DNS

Para que o domínio `fourmindstech.com.br` funcione corretamente, você precisa configurar os registros DNS:

### 1. Registro A
```
Tipo: A
Nome: @
Valor: 3.80.178.120
TTL: 300
```

### 2. Registro CNAME (www)
```
Tipo: CNAME
Nome: www
Valor: fourmindstech.com.br
TTL: 300
```

### 3. Verificação
```bash
# Testar resolução DNS
nslookup fourmindstech.com.br
nslookup www.fourmindstech.com.br

# Testar conectividade
ping fourmindstech.com.br
```

## 🔧 Configuração no Nginx

O Nginx já está configurado para aceitar o domínio personalizado:

```nginx
server {
    listen 80;
    server_name fourmindstech.com.br www.fourmindstech.com.br 3.80.178.120;
    
    location / {
        include proxy_params;
        proxy_pass http://unix:/home/ubuntu/s_agendamento/gunicorn.sock;
    }
}
```

## 🔒 Configuração SSL (Opcional)

Para HTTPS, você pode usar Let's Encrypt:

```bash
# Instalar Certbot
sudo apt update
sudo apt install certbot python3-certbot-nginx

# Obter certificado SSL
sudo certbot --nginx -d fourmindstech.com.br -d www.fourmindstech.com.br

# Renovação automática
sudo crontab -e
# Adicionar: 0 12 * * * /usr/bin/certbot renew --quiet
```

## 🎯 URLs Finais

- **Aplicação**: http://fourmindstech.com.br
- **Admin**: http://fourmindstech.com.br/admin
- **Usuário**: admin
- **Senha**: admin123

## ✅ Checklist de Configuração

- [ ] Registrar domínio (se ainda não tiver)
- [ ] Configurar registros DNS
- [ ] Aguardar propagação DNS (até 24h)
- [ ] Testar acesso ao domínio
- [ ] Configurar SSL (opcional)
- [ ] Testar todas as funcionalidades

## 🚨 Solução de Problemas

### Domínio não resolve
- Verificar configuração DNS
- Aguardar propagação (até 24h)
- Testar com `nslookup` e `ping`

### Erro 502 Bad Gateway
- Verificar se Gunicorn está rodando
- Verificar logs: `sudo journalctl -u gunicorn -f`

### Erro de permissão
- Verificar permissões: `sudo chown -R ubuntu:www-data /home/ubuntu/s_agendamento`
