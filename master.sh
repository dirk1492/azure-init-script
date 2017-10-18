#!/bin/sh

IP=$(dig k8s-dil001.eastus.cloudapp.azure.com | grep "^k8s-dil001.eastus.cloudapp.azure.com" | awk '{ print $5 }')
TOKEN=$(cat /tmp/token.txt)

until docker info &>/dev/null ; do
   sleep 1
done

kubeadm init --token $TOKEN --apiserver-bind-port 443 --apiserver-cert-extra-sans $IP --token-ttl 0

sudo -u dil mkdir -p /home/dil/.kube
cp /etc/kubernetes/admin.conf /home/dil/.kube/config
chown dil /home/dil/.kube/config 
