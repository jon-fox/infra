#!/bin/bash

sudo yum install -y nc

while true; do echo -e "HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\nOK" | nc -l -p 8080 >/dev/null 2>&1; done &

sudo snap start amazon-ssm-agent

cd /home
mkdir setup
chmod 775 setup
cd setup

aws s3 cp s3://${bucket_name}/${script_path}/pre_startup_container.sh /home/setup/pre_startup_container.sh
# aws s3 cp s3://${bucket_name}/${script_path}/docker_setup.sh /home/setup/docker_setup.sh
# aws s3 cp s3://${bucket_name}/${script_path}/nvidia_setup.sh /home/setup/nvidia_setup.sh
aws s3 cp s3://${bucket_name}/${script_path}/docker-compose.yml /home/setup/docker-compose.yml

chmod +x *

DOCKER_IMAGE_URI=$(aws ssm get-parameter --name "/account/docker_image_uri" --query "Parameter.Value" --output text)

export DOCKER_IMAGE_URI

./pre_startup_container.sh
