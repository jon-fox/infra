#!/bin/bash

# Update the package index and upgrade the system packages
sudo yum update -y

# Install necessary packages for Docker installation
sudo yum install -y yum-utils device-mapper-persistent-data lvm2

# Add Docker's official GPG key and set up the Docker stable repository
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# Update the package index again after adding the Docker repo
sudo yum update -y

# Install Docker packages
sudo yum install -y docker-ce docker-ce-cli containerd.io

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