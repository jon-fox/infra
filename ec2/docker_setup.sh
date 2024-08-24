#!/bin/bash

# Update the package index and upgrade the system packages
sudo apt update && sudo apt upgrade -y

# Install necessary packages for Docker installation
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Set up the Docker stable repository
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update the package index again after adding the Docker repo
sudo apt update

# Install Docker packages
sudo apt install -y docker-ce docker-ce-cli containerd.io

# Enable Docker service to start on boot
sudo systemctl enable docker

# Start Docker service
sudo systemctl start docker

# Verify Docker installation
docker_version=$(docker --version)
if [ $? -eq 0 ]; then
    echo "Docker installed successfully: $docker_version"
else
    echo "Docker installation failed"
    exit 1
fi

# Test Docker by running the hello-world container
sudo docker run hello-world

# Check if the hello-world container ran successfully
if [ $? -eq 0 ]; then
    echo "Docker is working correctly!"
else
    echo "Docker test failed"
    exit 1
fi

