#!/bin/bash

# https://docs.nvidia.com/cuda/cuda-installation-guide-linux/index.html#amazon

sudo dnf install -y kernel-devel-$(uname -r) kernel-headers-$(uname -r) kernel-modules-extra-$(uname -r)

sudo dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/amzn2023/x86_64/cuda-amzn2023.repo

sudo dnf module install -y nvidia-driver:latest-dkms
sudo dnf install -y cuda-toolkit

sudo dnf install -y nvidia-gds

curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo | \
  sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo

sudo yum-config-manager --enable nvidia-container-toolkit-experimental

sudo yum install -y nvidia-container-toolkit
