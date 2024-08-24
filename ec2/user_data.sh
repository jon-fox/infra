#!/bin/bash

sudo snap start amazon-ssm-agent

cd /home
mkdir setup
chmod 775 setup
cd setup

aws s3 cp s3://${bucket_name}/${script_path}/pre_startup_container.sh /home/setup/pre_startup_container.sh
aws s3 cp s3://${bucket_name}/${script_path}/docker_setup.sh /home/setup/docker_setup.sh
aws s3 cp s3://${bucket_name}/${script_path}/docker-compose.yml /home/setup/docker-compose.yml

chmod +x *

DOCKER_IMAGE_URI=$(aws ssm get-parameter --name "/account/docker_image_uri" --query "Parameter.Value" --output text)
ACCOUNT_ID=$(aws ssm get-parameter --name "/account/account_id" --query "Parameter.Value" --output text)

export DOCKER_IMAGE_URI

aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

./pre_startup_container.sh
