# 🚀 Aplicar Correção no Servidor

## ✅ Correção Commitada e Enviada

A correção do erro `TypeError: context must be a dict rather than HttpResponseRedirect` foi commitada e enviada para o repositório.

---

## 📋 Passo 1: Fazer Pull no Servidor

Conecte ao servidor e atualize o código:

```bash
# Conectar ao servidor
ssh -i sua-chave.pem ubuntu@52.20.60.108

# Ir para o diretório do projeto
cd ~/s_agendamento
# OU
cd /opt/s-agendamento

# Ativar ambiente virtual
source .venv/bin/activate

# Atualizar código
git pull origin main
```

---

## 📋 Passo 2: Verificar Mudanças

```bash
# Ver último commit
git log --oneline -1

# Ver mudanças no arquivo
git show HEAD:authentication/views.py | grep -A 5 "def dispatch"
```

---

## 📋 Passo 3: Reiniciar Gunicorn

```bash
# Reiniciar serviço gunicorn
sudo systemctl restart gunicorn

# Verificar status
sudo systemctl status gunicorn

# Verificar se socket foi criado
ls -la /opt/s-agendamento/s-agendamento.sock

# Ver logs
sudo journalctl -u gunicorn -n 20
```

---

## 📋 Passo 4: Recarregar Nginx (se necessário)

```bash
# Recarregar nginx
sudo systemctl reload nginx

# Verificar status
sudo systemctl status nginx
```

---

## ✅ Verificar se Funcionou

Após reiniciar, teste:

1. Acesse: https://fourmindstech.com.br/authentication/pagamento/pix/8/
2. Verifique se a página carrega sem erro
3. Verifique se o QR Code aparece (se houver dados válidos)

---

## 🚨 Se Ainda Houver Erro

### Verificar logs do Django:

```bash
tail -f /opt/s-agendamento/logs/django.log
```

### Verificar logs do gunicorn:

```bash
sudo journalctl -u gunicorn -f
```

### Verificar logs do nginx:

```bash
sudo tail -f /var/log/nginx/error.log
```

---

## 📝 Checklist

- [ ] Código atualizado (`git pull`)
- [ ] Gunicorn reiniciado
- [ ] Socket criado corretamente
- [ ] Nginx recarregado
- [ ] Site testado e funcionando
- [ ] Sem erros nos logs

---

**Dica:** Aguarde alguns segundos após reiniciar o gunicorn antes de testar!

