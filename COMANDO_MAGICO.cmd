=================================================
🚀 COMANDO MÁGICO - RESOLVER 502 AGORA
=================================================

Execute este comando DEPOIS de conectar via SSM:

aws ssm start-session --target i-0077873407e4114b1

Dentro da sessão SSM:

cd /opt/s-agendamento
sudo supervisorctl restart s-agendamento
sudo systemctl reload nginx
exit

=================================================
OU: Executar remotamente (SEM CONECTAR):
=================================================

aws ssm send-command \
  --instance-ids i-0077873407e4114b1 \
  --document-name "AWS-RunShellScript" \
  --parameters 'commands=["cd /opt/s-agendamento","sudo supervisorctl restart s-agendamento","sudo systemctl reload nginx","sudo supervisorctl status"]' \
  --query 'Command.CommandId' \
  --output text

Aguarde 30 segundos e teste:
https://fourmindstech.com.br/s_agendamentos/

=================================================

