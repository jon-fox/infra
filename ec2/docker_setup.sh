#!/bin/bash

# Update the package index
sudo dnf update -y

# Install Docker from the Amazon Linux 2023 repository
sudo dnf install -y docker

# Enable Docker service to start on boot
sudo systemctl enable docker

# Start Docker service
sudo systemctl start docker

# Add the ec2-user to the docker group to run Docker without sudo
sudo usermod -aG docker ec2-user

# Install Docker Compose (latest version)
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# Apply executable permissions to the Docker Compose binary
sudo chmod +x /usr/local/bin/docker-compose

# Verify Docker installation
docker_version=$(docker --version)
if [ $? -eq 0 ]; then
    echo "Docker installed successfully: $docker_version"
else
    echo "Docker installation failed"
    exit 1
fi

# Verify Docker Compose installation
docker_compose_version=$(docker-compose --version)
if [ $? -eq 0 ]; then
    echo "Docker Compose installed successfully: $docker_compose_version"
else
    echo "Docker Compose installation failed"
    exit 1
fi
