#!/bin/bash

# Set the ECS cluster name
ECS_CLUSTER_NAME="app-cluster"
ECS_AVAILABLE_LOGGING_DRIVERS='["json-file","awslogs"]'

# Install the ECS agent
sudo yum install -y ecs-init

# Update the ECS config file
echo "ECS_CLUSTER=${ECS_CLUSTER_NAME}" | sudo tee /etc/ecs/ecs.config > /dev/null
echo "ECS_AVAILABLE_LOGGING_DRIVERS=${ECS_AVAILABLE_LOGGING_DRIVERS}" | sudo tee -a /etc/ecs/ecs.config > /dev/null

# Restart the ECS agent
sudo systemctl restart ecs

# Enable ECS agent to start on boot
sudo systemctl enable ecs

# Verify ECS agent status
sudo systemctl status ecs