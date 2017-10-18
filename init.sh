#!/bin/sh

export DEBIAN_FRONTEND="noninteractive"

apt-get update && apt-get dist-upgrade -y 
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" >> /etc/apt/sources.list.d/kubernetes.list 
apt-get update && apt-get install -y docker.io kubelet kubeadm

git clone https://github.com/dirk1492/azure-init-script.git

systemctl stop kubelet
rm -rf /var/lib/kubelet

ssh-keygen -t ecdsa -b 521 -f ~/.ssh/id_ecdsa -N ''

echo "$1" >> /home/dil/token.txt
 
