# Criar instância EC2 com Django
Write-Host "Criando instância EC2 com Django..." -ForegroundColor Cyan

# Parâmetros
$AMI_ID = "ami-0c398cb65a93047f2"
$INSTANCE_TYPE = "t2.micro"
$SUBNET_ID = "subnet-0057559e127d38a38"
$SG_ID = "sg-04a916a777c8b1a5d"
$EIP_ALLOC = "eipalloc-07528d039f65583cf"

# Criar instância
Write-Host "Criando instância EC2..." -ForegroundColor Yellow
$result = aws ec2 run-instances `
    --image-id $AMI_ID `
    --instance-type $INSTANCE_TYPE `
    --subnet-id $SUBNET_ID `
    --security-group-ids $SG_ID `
    --user-data file://user_data_complete.sh `
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=s-agendamento-server}]" `
    --count 1 `
    --output json

$instance = $result | ConvertFrom-Json
$INSTANCE_ID = $instance.Instances[0].InstanceId

Write-Host "Instância criada: $INSTANCE_ID" -ForegroundColor Green

# Aguardar instância estar rodando
Write-Host "Aguardando instância iniciar..." -ForegroundColor Yellow
aws ec2 wait instance-running --instance-ids $INSTANCE_ID

# Associar Elastic IP
Write-Host "Associando Elastic IP..." -ForegroundColor Yellow
aws ec2 associate-address --instance-id $INSTANCE_ID --allocation-id $EIP_ALLOC

# Obter IP público
$PUBLIC_IP = aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[0].Instances[0].PublicIpAddress" --output text

Write-Host "`nInstância EC2 criada e configurada com sucesso!" -ForegroundColor Green
Write-Host "Instance ID: $INSTANCE_ID" -ForegroundColor Cyan
Write-Host "IP Público: $PUBLIC_IP" -ForegroundColor Cyan
Write-Host "`nO Django está sendo instalado automaticamente." -ForegroundColor Yellow
Write-Host "Aguarde 5-10 minutos para a aplicação ficar disponível." -ForegroundColor Yellow
Write-Host "`nWebsite: http://fourmindstech.com.br" -ForegroundColor Cyan
Write-Host "Admin: http://fourmindstech.com.br/admin/" -ForegroundColor Cyan
Write-Host "Usuário: admin | Senha: admin123" -ForegroundColor Yellow
