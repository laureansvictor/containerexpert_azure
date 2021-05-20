#!/bin/bash

sudo apt update && sudo apt upgrade-y
sudo apt install curl -y
curl -fsSL https://get.docker.com | bash
sudo usermod -aG docker $USER
mkdir /etc/docker
sudo touch /etc/docker/daemon.json
cd /etc/docker

sudo chown $USER daemon.json
cat > daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
cd ~
mkdir -p /etc/systemd/system/docker.service.d
sudo systemctl daemon-reload
sudo systemctl restart docker

apt update && apt install -y apt-transport-https gnupg2
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list
apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
reboot