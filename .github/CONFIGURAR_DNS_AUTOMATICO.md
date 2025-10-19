# 🌐 Configuração Automática de DNS via GitHub Actions

## 📋 Workflows Criados

Adicionei **4 workflows** para automatizar a configuração DNS:

### 1. **configure-dns-route53.yml** - AWS Route53
Configura DNS automaticamente no AWS Route53

**Registros criados**:
- ✅ Tipo: A | Nome: @ | Valor: 34.228.191.215
- ✅ Tipo: A | Nome: www | Valor: 34.228.191.215

### 2. **configure-dns-cloudflare.yml** - Cloudflare
Configura DNS automaticamente no Cloudflare

**Registros criados**:
- ✅ Tipo: A | Nome: @ | Valor: 34.228.191.215
- ✅ Tipo: A | Nome: www | Valor: 34.228.191.215

### 3. **install-ssl.yml** - Instalar SSL
Instala certificado SSL automaticamente após DNS propagar

### 4. **complete-setup.yml** - Setup Completo
Workflow completo que faz tudo: DNS + SSL

---

## 🚀 Como Usar

### Opção 1: AWS Route53 (Se seu domínio está no Route53)

1. **Configure o Secret no GitHub**:
   - Vá para: https://github.com/fourmindsorg/s_agendamento/settings/secrets/actions
   - Adicione (se ainda não tem):
     - `AWS_ACCESS_KEY_ID`
     - `AWS_SECRET_ACCESS_KEY`

2. **Execute o Workflow**:
   - Vá para: https://github.com/fourmindsorg/s_agendamento/actions
   - Clique em "Configure DNS - AWS Route53"
   - Clique em "Run workflow"
   - Digite o domínio: `fourmindstech.com.br`
   - Clique em "Run workflow"

3. **Aguarde**: O workflow irá criar automaticamente:
   ```
   Tipo: A | Nome: @ | Valor: 34.228.191.215
   Tipo: A | Nome: www | Valor: 34.228.191.215
   ```

4. **Instale o SSL**: Após 5-10 minutos, execute o workflow "Install SSL Certificate"

---

### Opção 2: Cloudflare (Se seu domínio está no Cloudflare)

1. **Obtenha o API Token do Cloudflare**:
   - Acesse: https://dash.cloudflare.com/profile/api-tokens
   - Clique em "Create Token"
   - Use o template "Edit zone DNS"
   - Selecione a zona (seu domínio)
   - Copie o token

2. **Configure o Secret no GitHub**:
   - Vá para: https://github.com/fourmindsorg/s_agendamento/settings/secrets/actions
   - Clique em "New repository secret"
   - Nome: `CLOUDFLARE_API_TOKEN`
   - Valor: Cole o token copiado
   - Clique em "Add secret"

3. **Execute o Workflow**:
   - Vá para: https://github.com/fourmindsorg/s_agendamento/actions
   - Clique em "Configure DNS - Cloudflare"
   - Clique em "Run workflow"
   - Digite o domínio: `fourmindstech.com.br`
   - Clique em "Run workflow"

4. **Aguarde**: O workflow irá criar/atualizar automaticamente:
   ```
   Tipo: A | Nome: @ | Valor: 34.228.191.215
   Tipo: A | Nome: www | Valor: 34.228.191.215
   ```

5. **Instale o SSL**: Após 1-5 minutos (Cloudflare é mais rápido), execute "Install SSL Certificate"

---

### Opção 3: Outro Provedor (Configuração Manual)

Se seu DNS está em outro provedor (GoDaddy, Hostinger, Registro.br, etc):

1. **Execute o Workflow de Setup Completo**:
   - Vá para: https://github.com/fourmindsorg/s_agendamento/actions
   - Clique em "Complete Setup (DNS + SSL)"
   - Clique em "Run workflow"
   - DNS Provider: Selecione `manual`
   - Digite o domínio: `fourmindstech.com.br`
   - Digite o email: `fourmindsorg@gmail.com`
   - Clique em "Run workflow"

2. **Siga as Instruções**: O workflow mostrará as instruções para configurar manualmente

3. **Configure no seu Provedor**:
   ```
   Tipo: A | Nome: @ | Valor: 34.228.191.215
   Tipo: A | Nome: www | Valor: 34.228.191.215
   ```

4. **O Workflow Aguarda**: Ele monitorará automaticamente a propagação DNS

5. **SSL Automático**: Quando o DNS propagar, o SSL será instalado automaticamente

---

## 📊 Secrets Necessários

### Para AWS Route53:
```
AWS_ACCESS_KEY_ID       = sua chave AWS
AWS_SECRET_ACCESS_KEY   = sua chave secreta AWS
EC2_SSH_KEY            = conteúdo do id_rsa_terraform
```

### Para Cloudflare:
```
CLOUDFLARE_API_TOKEN   = token da API Cloudflare
EC2_SSH_KEY           = conteúdo do id_rsa_terraform
```

### Para Qualquer Provedor (SSL):
```
EC2_SSH_KEY = conteúdo do id_rsa_terraform
```

---

## 🔄 Ordem de Execução Recomendada

### Para Route53 ou Cloudflare:

```
1. Configure DNS - Route53/Cloudflare
   ↓
2. Aguarde 5-30 minutos (Route53) ou 1-5 minutos (Cloudflare)
   ↓
3. Install SSL Certificate
   ↓
4. ✅ Pronto!
```

### Para Outros Provedores:

```
1. Complete Setup (DNS + SSL) com dns_provider=manual
   ↓
2. Configure manualmente no seu provedor
   ↓
3. Workflow aguarda propagação automaticamente
   ↓
4. SSL instalado automaticamente
   ↓
5. ✅ Pronto!
```

---

## ✅ Verificar se Funcionou

### Via GitHub Actions:
- Veja os logs dos workflows em: https://github.com/fourmindsorg/s_agendamento/actions
- ✅ Verde = Sucesso
- ❌ Vermelho = Erro (verifique os logs)

### Via Linha de Comando:
```bash
# Windows
nslookup fourmindstech.com.br
nslookup www.fourmindstech.com.br

# Linux/Mac
dig fourmindstech.com.br
dig www.fourmindstech.com.br
```

### Via Navegador:
Após SSL instalado, acesse:
- https://fourmindstech.com.br
- https://www.fourmindstech.com.br

---

## 🎯 O Que Cada Workflow Faz

### configure-dns-route53.yml
```yaml
✅ Busca a Hosted Zone no Route53
✅ Cria/atualiza registro A para @ → 34.228.191.215
✅ Cria/atualiza registro A para www → 34.228.191.215
✅ Verifica se os registros foram criados
✅ Mostra resumo da configuração
```

### configure-dns-cloudflare.yml
```yaml
✅ Busca a Zone no Cloudflare
✅ Cria/atualiza registro A para @ → 34.228.191.215
✅ Cria/atualiza registro A para www → 34.228.191.215
✅ Desabilita proxy (proxied: false) para usar seu IP
✅ Verifica se os registros foram criados
✅ Mostra resumo da configuração
```

### install-ssl.yml
```yaml
✅ Verifica se DNS está propagado
✅ Conecta no servidor via SSH
✅ Executa certbot --nginx
✅ Instala certificado para @ e www
✅ Configura redirecionamento HTTP → HTTPS
✅ Testa conexão HTTPS
✅ Mostra resumo com URLs
```

### complete-setup.yml
```yaml
✅ Mostra instruções para DNS manual
✅ OU chama workflow de Route53
✅ OU chama workflow de Cloudflare
✅ Monitora propagação DNS (30 minutos)
✅ Instala SSL automaticamente
✅ Mostra resumo final
```

---

## 🆘 Troubleshooting

### Erro: "Zone não encontrada"
**Solução**: Certifique-se de que o domínio está adicionado ao Route53/Cloudflare

### Erro: "DNS não propagou"
**Solução**: Aguarde mais tempo e execute novamente

### Erro: "Certificado SSL falhou"
**Solução**: 
1. Verifique se DNS está propagado: `nslookup fourmindstech.com.br`
2. Aguarde 5 minutos e tente novamente
3. Verifique se as portas 80 e 443 estão abertas

### Erro: "Permission denied (publickey)"
**Solução**: Verifique se o secret `EC2_SSH_KEY` está configurado corretamente

---

## 📝 Exemplo de Configuração Completa

### Passo a Passo com Route53:

```bash
1. Acesse GitHub Actions:
   https://github.com/fourmindsorg/s_agendamento/actions

2. Execute "Configure DNS - AWS Route53"
   - Domain: fourmindstech.com.br
   - Run workflow
   
3. Aguarde ~10 minutos

4. Execute "Install SSL Certificate"
   - Domain: fourmindstech.com.br
   - Email: fourmindsorg@gmail.com
   - Run workflow

5. ✅ Acesse: https://fourmindstech.com.br
```

---

## 🎉 Resultado Final

Após executar os workflows com sucesso:

```
✅ DNS configurado:
   - fourmindstech.com.br → 34.228.191.215
   - www.fourmindstech.com.br → 34.228.191.215

✅ SSL instalado:
   - Certificado válido por 90 dias
   - Renovação automática configurada
   - HTTP → HTTPS redirecionamento ativo

✅ Site acessível via:
   - https://fourmindstech.com.br
   - https://www.fourmindstech.com.br
   - https://fourmindstech.com.br/admin
```

---

## 📞 Suporte

Se precisar de ajuda:
- **GitHub Issues**: https://github.com/fourmindsorg/s_agendamento/issues
- **Email**: fourmindsorg@gmail.com

---

**Desenvolvido por**: 4Minds Team  
**Data**: 12/10/2025



















