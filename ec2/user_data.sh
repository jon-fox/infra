#!/bin/bash

# Variables passed from Terraform
REGION=${region}
REPOSITORY_URL=${repository_url}
BUCKET_NAME=${bucket_name}
SCRIPT_PATH=${script_path}

aws s3 cp s3://${BUCKET_NAME}/${SCRIPT_PATH}/pre_startup_container.sh /home/setup/pre_startup_container.sh
aws s3 cp s3://${BUCKET_NAME}/${SCRIPT_PATH}/docker_setup.sh /home/setup/docker_setup.sh
aws s3 cp s3://${BUCKET_NAME}/${SCRIPT_PATH}/docker-compose.yml /home/setup/docker-compose.yml

chmod +x /home/setup/*.sh

DOCKER_IMAGE_URI=$(aws ssm get-parameter --name "/account/docker_image_uri" --query "Parameter.Value" --output text)

export DOCKER_IMAGE_URI

./home/setup/pre_startup_container.sh
