#!/bin/sh

export DEBIAN_FRONTEND="noninteractive"

apt-get update && apt-get dist-upgrade -y 
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" >> /etc/apt/sources.list.d/kubernetes.list 
apt-get update && apt-get install -y docker.io kubelet kubeadm

systemctl stop kubelet
rm -rf /var/lib/kubelet

runuser -l dil mkdir -p ~/.ssh
runuser -l dil ssh-keygen -t ecdsa -b 521 -f ~/.ssh/id_ecdsa -N ''

echo 'APT::Periodic::Update-Package-Lists "1";' > /etc/apt/apt.conf.d/10periodic
echo 'APT::Periodic::Download-Upgradeable-Packages "1";' >> /etc/apt/apt.conf.d/10periodic
echo 'APT::Periodic::Unattended-Upgrade "1";' >> /etc/apt/apt.conf.d/10periodic

adduser dil docker

#mkdir -p /tmp/scripts
#cd /tmp/scripts
#git clone https://github.com/dirk1492/azure-init-script.git
echo "$1" >> /tmp/token.txt

if [ -n "$2" ]; then
    sh "$2"
fi
