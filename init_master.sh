#!/bin/sh

export DEBIAN_FRONTEND="noninteractive"

apt-get update && apt-get dist-upgrade -y 
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" >> /etc/apt/sources.list.d/kubernetes.list 
apt-get update && apt-get install -y docker.io kubelet kubeadm

systemctl stop kubelet
rm -rf /var/lib/kubelet

echo "10.0.2.10 master" >> /etc/hosts

echo "10.0.2.101 node01" >> /etc/hosts
echo "10.0.2.102 node02" >> /etc/hosts
echo "10.0.2.103 node03" >> /etc/hosts
echo "10.0.2.104 node04" >> /etc/hosts
echo "10.0.2.105 node05" >> /etc/hosts

#sleep 20

#kubeadm init --token $1 --apiserver-bind-port $2 --apiserver-cert-extra-sans $3
 
