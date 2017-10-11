#!/bin/sh

export DEBIAN_FRONTEND="noninteractive"

apt-get update && apt-get dist-upgrade -y 
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" >> /etc/apt/sources.list.d/kubernetes.list 
apt-get update && apt-get install -y docker.io kubelet kubeadm

systemctl stop kubelet
rm -rf /var/lib/kubelet

#sleep 20

#kubeadm init --token $1 --apiserver-bind-port $2 --apiserver-cert-extra-sans $3
 
