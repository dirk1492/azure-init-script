#!/bin/sh

export DEBIAN_FRONTEND="noninteractive"

echo "sleep 10 seconds"
sleep 10

echo "wait for dpkg to get unlocked" 
while fuser /var/lib/dpkg/lock >/dev/null 2>&1 ; do
    sleep 0.5
done 

dpkg -l docker.io >/dev/null 2>&1
if [ $? -ne 0 ];  then
  which ansible > /dev/null  
  if [ $? -ne 0 ]; then	
    
    if [ ! -f "/etc/apt/sources.list.d/ansible-ubuntu-ansible-xenial.list" ]; then
      apt-add-repository -y ppa:ansible/ansible
    fi
    apt update
    apt install -y ansible
  fi
fi

if [ -d /tmp/scripts/azure-init-script ]; then
    git pull
else
    mkdir -p /tmp/scripts
    cd /tmp/scripts
    git clone https://github.com/dirk1492/azure-init-script.git
fi

cd /tmp/scripts/azure-init-script

if [ -n "$2" ]; then
    TOKEN="$2"
else
    TOKEN="edfe65.2dcb815d96fd4a5b"    
fi

if [ -n "$3" ]; then
    PORT="$3"
else
    PORT="443"    
fi

if [ -n "$1" ]; then
    ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory --extra-vars="k8s_token=$TOKEN apiserver_bind_port=$PORT" $1.yml 
else     
    ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory --extra-vars="k8s_token=$TOKEN apiserver_bind_port=$PORT" basic.yml
fi

# apt-get update && apt-get dist-upgrade -y 

# if [ ! -f /etc/apt/sources.list.d/kubernetes.list ] ; then
#     curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
#     echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" >> /etc/apt/sources.list.d/kubernetes.list 
#     apt-get update && apt-get install -y docker.io kubelet kubeadm glusterfs-client

#     systemctl stop kubelet
#     rm -rf /var/lib/kubelet
# fi

# sudo -u dil mkdir -p /home/dil/.ssh
# [ ! -f /home/dil/.ssh/id_ecdsa ] && sudo -u dil ssh-keygen -t ecdsa -b 521 -f /home/dil/.ssh/id_ecdsa -N ''

# echo 'APT::Periodic::Update-Package-Lists "1";' > /etc/apt/apt.conf.d/10periodic
# echo 'APT::Periodic::Download-Upgradeable-Packages "1";' >> /etc/apt/apt.conf.d/10periodic
# echo 'APT::Periodic::Unattended-Upgrade "1";' >> /etc/apt/apt.conf.d/10periodic

# adduser dil docker

# sed -i "s/^\/dev\/disk\/cloud/#\/dev\/disk\/cloud/g" /etc/fstab
# umount /mnt
# wipefs -fa /dev/sdb1
# pvcreate /dev/sdb1

# if [ -d /tmp/scripts/azure-init-script ]; then
#     git pull
# else
#     mkdir -p /tmp/scripts
#     cd /tmp/scripts
#     git clone https://github.com/dirk1492/azure-init-script.git
# fi

# echo "dm_thin_pool" >> /etc/modules
# modprobe dm_thin_pool

# echo "$1" > /tmp/token.txt

# if [ -n "$2" ]; then
#     sh "/tmp/scripts/azure-init-script/$2"
# fi
