#!/bin/bash

# Path to the flag file
FLAG_FILE="/tmp/host_startup_done"

# Function to run a startup script and check for errors
run_startup_script() {
  local script_path=$1
  echo "Running $script_path..."
  $script_path

  if [ $? -ne 0 ]; then
    echo "Script $script_path failed. Aborting Docker Compose startup."
    exit 1
  fi
}

# Check if the flag file exists
if [ -f "$FLAG_FILE" ]; then
  echo "Pre-startup script has already been run. Skipping..."
else
  # If the flag file doesn't exist, run the script tasks
  echo "Running pre-startup script for the first time..."

  # Insert your host-specific startup tasks here
  # run_startup_script "/home/setup/nvidia_setup.sh"
  # run_startup_script "/home/setup/docker_setup.sh"


  sudo nvidia-ctk runtime configure --runtime=docker
  sudo systemctl restart docker

  # Create the flag file to indicate the script has been run
  touch "$FLAG_FILE"
  echo "Pre-startup script completed successfully."
fi

# Start Docker Compose services
echo "Starting Docker Compose services..."

ACCOUNT_ID=$(aws ssm get-parameter --name "/account/account_id" --query "Parameter.Value" --output text)

aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

docker-compose up -d

if [ $? -eq 0 ]; then
  echo "Docker Compose services started successfully."
else
  echo "Failed to start Docker Compose services."
  exit 1
fi