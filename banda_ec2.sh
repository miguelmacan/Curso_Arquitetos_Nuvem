#!/bin/bash

# 1. Configuração da Instância EC2
echo "Criando uma instância EC2 com Amazon Linux 2..."

# Configuração de variáveis
AMI_ID="ami-0c02fb55956c7d316"  # Amazon Linux 2 (Região us-east-1)
INSTANCE_TYPE="t2.micro"        # Tipo de instância
KEY_NAME="banda-miguel-key"     # Nome da chave SSH (deve ser criada previamente)
SECURITY_GROUP="sg-12345678"    # ID do grupo de segurança (previamente configurado)

# Criar instância EC2
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --instance-type $INSTANCE_TYPE \
  --key-name $KEY_NAME \
  --security-group-ids $SECURITY_GROUP \
  --query "Instances[0].InstanceId" \
  --output text)

echo "Instância EC2 criada com ID: $INSTANCE_ID"

# Aguardar até que a instância esteja em execução
echo "Aguardando a instância iniciar..."
aws ec2 wait instance-running --instance-ids $INSTANCE_ID
echo "Instância está em execução!"

# Obter o endereço IP público
PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --query "Reservations[0].Instances[0].PublicIpAddress" \
  --output text)

echo "Endereço IP público da instância: $PUBLIC_IP"

# 2. Conexão via SSH
echo "Para conectar-se via SSH, use o comando:"
echo "ssh -i $KEY_NAME.pem ec2-user@$PUBLIC_IP"

# 3. Gerenciando o Armazenamento
echo "Criando um novo volume EBS..."
VOLUME_ID=$(aws ec2 create-volume \
  --availability-zone $(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[0].Instances[0].Placement.AvailabilityZone" --output text) \
  --size 10 \
  --volume-type gp2 \
  --query "VolumeId" \
  --output text)

echo "Volume EBS criado com ID: $VOLUME_ID"

# Aguardar até que o volume esteja disponível
echo "Aguardando o volume estar disponível..."
aws ec2 wait volume-available --volume-ids $VOLUME_ID
echo "Volume está disponível!"

# Anexar o volume à instância EC2
echo "Anexando o volume à instância..."
aws ec2 attach-volume \
  --volume-id $VOLUME_ID \
  --instance-id $INSTANCE_ID \
  --device /dev/xvdf

echo "Volume anexado à instância."

# 4. Formatando e Montando o Volume
echo "Conecte-se via SSH e execute os comandos a seguir para formatar e montar o volume:"

FORMAT_AND_MOUNT_COMMANDS="
sudo mkfs.ext4 /dev/xvdf
sudo mkdir /mnt/volume
sudo mount /dev/xvdf /mnt/volume
echo '/dev/xvdf /mnt/volume ext4 defaults 0 0' | sudo tee -a /etc/fstab
"

echo "$FORMAT_AND_MOUNT_COMMANDS"

# 5. Criação de Arquivos
CREATE_FILE_COMMAND="
sudo bash -c 'echo \"Bem-vindo à banda de Miguel!\" > /mnt/volume/banda_miguel.txt'
"

echo "$CREATE_FILE_COMMAND"

# 6. Explorando Recursos
EXPLORATION_COMMANDS="
ls -l /mnt/volume
df -h
cat /mnt/volume/banda_miguel.txt
"

echo "$EXPLORATION_COMMANDS"

echo "Concluído! Não se esqueça de parar a instância EC2 após terminar o exercício:"
echo "aws ec2 stop-instances --instance-ids $INSTANCE_ID"
