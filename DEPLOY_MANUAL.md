# 🚀 Deploy Manual do Sistema

O deploy automático via SSM não está disponível. Execute o deploy manualmente.

## 📋 Informações do Servidor

- **IP:** 52.91.139.151  
- **Instância:** i-0077873407e4114b1  
- **Usuário:** ubuntu  
- **Branch:** main  

## ✅ Opções de Deploy

### Opção 1: Via SSH (Recomendado)

```bash
# Conectar ao servidor
ssh -i sua_chave.pem ubuntu@52.91.139.151

# Executar deploy
cd /opt/s-agendamento
sudo bash infrastructure/deploy_completo.sh
```

### Opção 2: Via AWS Session Manager

```bash
# Conectar via Session Manager
aws ssm start-session --target i-0077873407e4114b1

# Executar deploy
cd /opt/s-agendamento
sudo bash infrastructure/deploy_completo.sh
```

### Opção 3: Executar Passo a Passo

```bash
# No servidor (ubuntu@ip-10-0-1-9 ou similar)

# 1. Atualizar código
cd /opt/s-agendamento
git fetch origin
git reset --hard origin/main

# 2. Ativar venv e instalar dependências
source venv/bin/activate
pip install -r requirements.txt --upgrade

# 3. Aplicar migrações
python manage.py migrate
python manage.py collectstatic --noinput

# 4. Reiniciar serviços
sudo supervisorctl restart s-agendamento
sudo systemctl reload nginx

# 5. Verificar status
sudo supervisorctl status
curl -I http://localhost
curl -I http://52.91.139.151
```

## 🧪 Teste Após Deploy

```bash
# Teste local
curl -I http://localhost

# Teste IP público
curl -I http://52.91.139.151

# Teste domínio
curl -I https://fourmindstech.com.br
```

## 📊 Verificação

Após o deploy, verifique:

✅ Código atualizado (commit mais recente)  
✅ Dependências instaladas  
✅ Migrações aplicadas  
✅ Arquivos estáticos coletados  
✅ Gunicorn rodando  
✅ Nginx configurado  
✅ Acesso HTTP funcionando  
✅ Acesso HTTPS funcionando  

## 🔧 Logs e Troubleshooting

```bash
# Ver logs do Gunicorn
sudo tail -f /opt/s-agendamento/logs/gunicorn.log

# Ver status do supervisor
sudo supervisorctl status

# Ver logs do Nginx
sudo tail -f /var/log/nginx/error.log

# Reiniciar se necessário
sudo supervisorctl restart s-agendamento
sudo systemctl restart nginx
```

## 📝 Notas

- O script `deploy_completo.sh` aplica todas as correções:
  - CSRF_TRUSTED_ORIGINS
  - Configuração do Nginx
  - Configuração do Supervisor
  - Reinicialização dos serviços

- Se ocorrer erro 502: Verifique se o Gunicorn está rodando
- Se ocorrer erro 500: Verifique logs do Gunicorn
- Se ocorrer erro de permissão: Execute com `sudo`

## 🎯 Status Atual

- ✅ Todos os commits estão no repositório
- ✅ Script de deploy pronto
- ⚠️ Deploy precisa ser executado manualmente

