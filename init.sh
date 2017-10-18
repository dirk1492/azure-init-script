#!/bin/sh

export DEBIAN_FRONTEND="noninteractive"

apt-get update && apt-get dist-upgrade -y 

if [ ! -f /etc/apt/sources.list.d/kubernetes.list ] ; then
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
    echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" >> /etc/apt/sources.list.d/kubernetes.list 
    apt-get update && apt-get install -y docker.io kubelet kubeadm

    systemctl stop kubelet
    rm -rf /var/lib/kubelet
fi

sudo -u dil mkdir -p /home/dil/.ssh
[ ! -f /home/dil/.ssh/id_ecdsa ] && sudo -u dil ssh-keygen -t ecdsa -b 521 -f /home/dil/.ssh/id_ecdsa -N ''

echo 'APT::Periodic::Update-Package-Lists "1";' > /etc/apt/apt.conf.d/10periodic
echo 'APT::Periodic::Download-Upgradeable-Packages "1";' >> /etc/apt/apt.conf.d/10periodic
echo 'APT::Periodic::Unattended-Upgrade "1";' >> /etc/apt/apt.conf.d/10periodic

adduser dil docker

if [ -d /tmp/scripts/azure-init-script ]; then
    git pull
else
    mkdir -p /tmp/scripts
    cd /tmp/scripts
    git clone https://github.com/dirk1492/azure-init-script.git
fi

echo "$1" > /tmp/token.txt

if [ -n "$2" ]; then
    sh "/tmp/scripts/azure-init-script/$2"
fi
