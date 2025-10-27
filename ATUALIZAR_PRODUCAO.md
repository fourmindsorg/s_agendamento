# 🚀 Atualizar Sistema em Produção

## ⚠️ Situação Atual
- **Desenvolvimento**: Atualizado com todas as mudanças recentes
- **Produção**: Desatualizado (código antigo no servidor)

## ✅ Solução: Deploy Manual

Como o servidor não tem Git configurado, vamos fazer deploy manual.

### Opção 1: Via AWS Console (Mais Fácil)

#### Passo 1: Preparar Arquivos Localmente

No seu computador (onde está o código atualizado):

```bash
# Criar backup do código atual
cd c:\PROJETOS\TRABALHOS\STARTUP\4Minds\Sistemas\s_agendamento

# Criar arquivo ZIP com o código
# No Windows PowerShell:
Compress-Archive -Path agendamentos,authentication,core,financeiro,info,templates,static,*.py,*.txt,manage.py -DestinationPath deploy.zip

# Ou usar WinRAR/7-Zip para criar ZIP
```

#### Passo 2: Enviar Código para o Servidor

**Opção A: Via AWS Console**
1. Acesse: https://console.aws.amazon.com/ec2/
2. Selecione a instância: i-0077873407e4114b1
3. Clique "Connect" → "EC2 Instance Connect"
4. Faça upload do arquivo ZIP via interface web

**Opção B: Via SCP (Se tiver SSH configurado)**

```bash
# No Git Bash ou PowerShell
scp deploy.zip ubuntu@52.91.139.151:/home/ubuntu/
```

#### Passo 3: Atualizar no Servidor

Execute no servidor (via AWS Console):

```bash
# 1. Fazer backup do código atual
sudo cp -r /opt/s-agendamento /opt/s-agendamento.backup

# 2. Extrair novo código
cd /home/ubuntu
unzip deploy.zip -d /tmp/s-agendamento-new

# 3. Copiar arquivos novos
sudo cp -r /tmp/s-agendamento-new/* /opt/s-agendamento/

# 4. Garantir permissões
sudo chown -R django:www-data /opt/s-agendamento
sudo chmod -R 755 /opt/s-agendamento

# 5. Ativar venv e atualizar dependências
cd /opt/s-agendamento
source venv/bin/activate
pip install -r requirements.txt --upgrade

# 6. Rodar migrações
python manage.py migrate

# 7. Coletar arquivos estáticos
python manage.py collectstatic --noinput

# 8. Reiniciar serviços
sudo supervisorctl restart s-agendamento
sudo systemctl reload nginx

# 9. Verificar status
sudo supervisorctl status
```

---

### Opção 2: Deploy Direto via Git Pull (Se configurar Git)

No servidor:

```bash
cd /opt/s-agendamento

# Se não tem Git configurado, configurar:
sudo apt-get update
sudo apt-get install git -y
sudo git clone https://github.com/fourmindsorg/s_agendamento.git /tmp/s_agendamento

# OU fazer backup e recriar:
sudo mv /opt/s-agendamento /opt/s-agendamento-old
sudo git clone https://github.com/fourmindsorg/s_agendamento.git /opt/s-agendamento

# Depois configurar e deployar:
cd /opt/s-agendamento
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python manage.py migrate
python manage.py collectstatic --noinput
sudo supervisorctl restart s-agendamento
```

---

### Opção 3: Usar GitHub Actions (Recomendado para Futuro)

1. **Fazer commit das mudanças localmente:**
```bash
git add .
git commit -m "Update: atualizar produção com código atual"
git push origin main
```

2. **GitHub Actions vai executar mas vai mostrar "deploy manual necessário"**

3. **Seguir instruções que aparecem no GitHub Actions**

---

## 🎯 Solução Rápida AGORA

Execute no servidor (AWS Console):

```bash
cd /opt/s-agendamento
sudo supervisorctl stop s-agendamento

# Fazer backup
sudo cp -r . /opt/s-agendamento-backup-$(date +%Y%m%d)

# Remover código antigo (CUIDADO! Mantém venv e staticfiles)
sudo rm -rf agendamentos authentication core financeiro info templates static
sudo rm -f *.py manage.py requirements.txt

# Vamos fazer upload manual dos arquivos novos
# (Você vai copiar arquivo por arquivo ou usar SCP)
```

---

## 📋 Checklist Completo

- [ ] Fazer backup do código atual
- [ ] Enviar novos arquivos para servidor
- [ ] Atualizar dependências Python
- [ ] Rodar migrações do banco
- [ ] Coletar arquivos estáticos
- [ ] Reiniciar Gunicorn
- [ ] Recarregar Nginx
- [ ] Testar site
- [ ] Verificar logs

---

## ⚠️ Cuidados

1. **Backup sempre primeiro!**
2. **Manter venv ativo durante updates**
3. **Rodar migrações ANTES de reiniciar**
4. **Verificar logs se houver erro**

## 📝 Logs Úteis

```bash
# Ver logs do Gunicorn
sudo tail -f /opt/s-agendamento/logs/gunicorn.log

# Ver logs do Nginx
sudo tail -f /var/log/nginx/error.log

# Ver status
sudo supervisorctl status
```

