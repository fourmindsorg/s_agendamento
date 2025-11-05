# ✅ Testar Serviço Gunicorn

## ✅ Status Atual

O arquivo systemd foi validado com sucesso! O aviso sobre `snapd.service` é do sistema e não afeta seu serviço.

## 🔍 Verificar Status

Execute no servidor:

```bash
# 1. Verificar status do serviço
sudo systemctl status s-agendamento.service

# 2. Se não estiver rodando, iniciar
sudo systemctl start s-agendamento.service

# 3. Habilitar para iniciar automaticamente
sudo systemctl enable s-agendamento.service

# 4. Verificar logs
sudo journalctl -u s-agendamento -n 50

# 5. Verificar logs do Asaas especificamente
sudo journalctl -u s-agendamento -n 100 | grep -i -E "(production|asaas|error)"
```

## ✅ Verificar Logs de Produção

Os logs devem mostrar:

```
[PRODUCTION] Arquivo .env carregado de: /opt/s-agendamento/.env
[PRODUCTION] ASAAS_API_KEY carregada com sucesso
```

## 🔍 Verificar se o Serviço está Funcionando

```bash
# Verificar se o processo está rodando
ps aux | grep gunicorn | grep -v grep

# Verificar se o socket existe
ls -la /opt/s-agendamento/s-agendamento.sock

# Testar conexão HTTP local
curl -I http://localhost

# OU testar via Nginx (se configurado)
curl -I https://fourmindstech.com.br
```

## 🧪 Testar Geração de QR Code

1. Acesse a aplicação no navegador
2. Tente gerar um QR Code Pix
3. Deve funcionar sem erros de `ASAAS_API_KEY`

## 📝 Checklist Final

- [ ] Arquivo systemd criado e validado
- [ ] Serviço iniciado: `sudo systemctl start s-agendamento`
- [ ] Serviço habilitado: `sudo systemctl enable s-agendamento`
- [ ] Logs mostram `[PRODUCTION]` e `ASAAS_API_KEY carregada`
- [ ] Processo Gunicorn rodando
- [ ] Socket Unix criado
- [ ] Teste de QR Code funcionando

## ⚠️ Se o Serviço Não Iniciar

```bash
# Ver detalhes do erro
sudo journalctl -xeu s-agendamento.service -n 50

# Verificar se o usuário do serviço tem permissão
sudo -u django ls -la /opt/s-agendamento/.venv/bin/gunicorn

# Verificar se o socket pode ser criado
sudo -u django touch /opt/s-agendamento/s-agendamento.sock
sudo rm /opt/s-agendamento/s-agendamento.sock

# Verificar permissões do diretório
ls -la /opt/s-agendamento | head -10
```

## 🔄 Reiniciar Serviço

```bash
# Reiniciar
sudo systemctl restart s-agendamento

# Ver status
sudo systemctl status s-agendamento

# Ver logs em tempo real
sudo journalctl -u s-agendamento -f
```

