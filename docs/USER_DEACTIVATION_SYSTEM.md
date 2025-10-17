# Sistema de Desativação Automática de Usuários

Este documento descreve o sistema implementado para desativar automaticamente usuários após 14 dias de cadastro, conforme solicitado.

## 📋 Visão Geral

O sistema implementa a seguinte regra:
- **Período de teste**: 14 dias a partir da data de cadastro
- **Ação automática**: Após 15º dia, `is_active = False`
- **Execução**: Automática via cron job/task scheduler

## 🛠️ Componentes Implementados

### 1. Comandos de Management

#### `deactivate_expired_users`
Comando principal para desativar usuários expirados.

```bash
# Desativar usuários após 14 dias (padrão)
python manage.py deactivate_expired_users

# Simular sem fazer alterações
python manage.py deactivate_expired_users --dry-run

# Personalizar período (ex: 7 dias)
python manage.py deactivate_expired_users --days 7

# Incluir superusers (cuidado!)
python manage.py deactivate_expired_users --force
```

#### `check_user_status`
Verificar status dos usuários e período de teste.

```bash
# Estatísticas gerais
python manage.py check_user_status

# Verificar usuário específico
python manage.py check_user_status --username usuario123

# Usuários próximos do vencimento
python manage.py check_user_status --expiring-soon

# Personalizar período
python manage.py check_user_status --days 7
```

#### `reactivate_user`
Reativar usuários desativados.

```bash
# Reativar usuário
python manage.py reactivate_user --username usuario123

# Reativar e estender período por 30 dias
python manage.py reactivate_user --username usuario123 --extend-days 30

# Forçar reativação de superuser
python manage.py reactivate_user --username admin --force
```

### 2. Scripts de Configuração

#### Linux/macOS - Cron Job
```bash
# Configurar cron job
python scripts/setup_user_deactivation_cron.py

# Opções disponíveis:
# 1. Adicionar cron job
# 2. Remover cron job  
# 3. Verificar status
# 4. Sair
```

#### Windows - Task Scheduler
```bash
# Configurar task scheduler
python scripts/setup_windows_task.py

# Opções disponíveis:
# 1. Criar tarefa agendada
# 2. Remover tarefa agendada
# 3. Verificar status da tarefa
# 4. Executar tarefa agora
# 5. Testar comando de desativação
# 6. Sair
```

## ⚙️ Configuração Automática

### Linux/macOS (Cron)
- **Agendamento**: Diariamente às 2:00 AM
- **Logs**: `logs/user_deactivation.log`
- **Comando**: `cd /caminho/projeto && python manage.py deactivate_expired_users`

### Windows (Task Scheduler)
- **Agendamento**: Diariamente às 2:00 AM
- **Logs**: `logs/user_deactivation.log`
- **Execução**: Como SYSTEM com privilégios elevados

## 📊 Monitoramento

### Verificar Status
```bash
# Verificar usuários próximos do vencimento
python manage.py check_user_status --expiring-soon

# Estatísticas completas
python manage.py check_user_status
```

### Logs
- **Localização**: `logs/user_deactivation.log`
- **Conteúdo**: Saída dos comandos de desativação
- **Rotação**: Manual (pode ser configurada)

## 🔧 Configurações Avançadas

### Personalizar Período de Teste
```python
# No comando, use --days
python manage.py deactivate_expired_users --days 30  # 30 dias
```

### Excluir Superusers
Por padrão, superusers são protegidos. Para incluí-los:
```bash
python manage.py deactivate_expired_users --force
```

### Modo Dry-Run
Sempre teste antes de executar:
```bash
python manage.py deactivate_expired_users --dry-run
```

## 🚨 Segurança e Boas Práticas

### 1. Backup
- Sempre faça backup antes de executar em produção
- Teste em ambiente de desenvolvimento primeiro

### 2. Monitoramento
- Configure alertas para falhas na execução
- Monitore logs regularmente
- Verifique usuários próximos do vencimento

### 3. Reativação
- Mantenha processo para reativar usuários quando necessário
- Documente casos de reativação
- Use `--extend-days` para estender período de teste

## 🐛 Troubleshooting

### Comando não executa
```bash
# Verificar permissões
ls -la manage.py

# Testar comando manualmente
python manage.py deactivate_expired_users --dry-run
```

### Cron não funciona
```bash
# Verificar se cron está rodando
sudo systemctl status cron

# Verificar logs do sistema
sudo tail -f /var/log/syslog | grep CRON
```

### Task Scheduler não executa
1. Verificar se a tarefa está habilitada
2. Verificar permissões de execução
3. Testar execução manual

## 📈 Estatísticas e Relatórios

### Comandos Úteis
```bash
# Usuários ativos vs inativos
python manage.py check_user_status

# Usuários específicos
python manage.py check_user_status --username usuario123

# Usuários próximos do vencimento
python manage.py check_user_status --expiring-soon
```

### Integração com Admin
- Usuários desativados aparecem com `is_active = False` no admin
- Filtros disponíveis por status de ativação
- Ações em lote para reativação

## 🔄 Fluxo de Trabalho Recomendado

1. **Configuração Inicial**
   ```bash
   # Testar comando
   python manage.py deactivate_expired_users --dry-run
   
   # Configurar agendamento
   python scripts/setup_user_deactivation_cron.py  # Linux/macOS
   python scripts/setup_windows_task.py           # Windows
   ```

2. **Monitoramento Diário**
   ```bash
   # Verificar usuários próximos do vencimento
   python manage.py check_user_status --expiring-soon
   ```

3. **Manutenção Semanal**
   ```bash
   # Verificar estatísticas gerais
   python manage.py check_user_status
   
   # Verificar logs
   tail -f logs/user_deactivation.log
   ```

4. **Reativação Quando Necessário**
   ```bash
   # Reativar usuário específico
   python manage.py reactivate_user --username usuario123
   ```

## 📞 Suporte

Para dúvidas ou problemas:
1. Verifique os logs em `logs/user_deactivation.log`
2. Execute comandos com `--dry-run` para testar
3. Use `check_user_status` para diagnosticar
4. Consulte este documento para referência
