#!/bin/sh

export DEBIAN_FRONTEND="noninteractive"

sleep 10

# wait for dpkg 
i=0
tput sc
while fuser /var/lib/dpkg/lock >/dev/null 2>&1 ; do
    case $(($i % 4)) in
        0 ) j="-" ;;
        1 ) j="\\" ;;
        2 ) j="|" ;;
        3 ) j="/" ;;
    esac
    tput rc
    echo -en "\r[$j] Waiting for other software managers to finish..." 
    sleep 0.5
    ((i=i+1))
done 

dpkg -l docker.io >/dev/null 2>&1
if (($?>0)); then
  which ansible > /dev/null  
  if [ $? -ne 0 ]; then	
    apt-add-repository ppa:ansible/ansible
    apt-get install -y ansible
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
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory main.yml

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
