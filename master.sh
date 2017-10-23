#!/bin/sh

IP=$(dig k8s-dil001.eastus.cloudapp.azure.com | grep "^k8s-dil001.eastus.cloudapp.azure.com" | awk '{ print $5 }')
TOKEN=$(cat /tmp/token.txt)

until docker info &>/dev/null ; do
   sleep 1
done

kubeadm init --token $TOKEN --apiserver-bind-port 443 --apiserver-cert-extra-sans $IP, --token-ttl 0 --config /tmp/scripts/azure-init-script/kubeadm.yaml

while [ "$(curl -sL -w "%{http_code}\\n" "https://master/api/v1" -o /dev/null --connect-timeout 1 --max-time 1 --insecure)" != "200" ] ; do
 sleep 5
done

sudo -u dil mkdir -p /home/dil/.kube
cp /etc/kubernetes/admin.conf /home/dil/.kube/config
chown dil /home/dil/.kube/config 

export kubever=$(kubectl version | base64 | tr -d '\n')
sudo -u dil kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$kubever"

kubectl apply -f https://raw.githubusercontent.com/kubernetes/heapster/master/deploy/kube-config/rbac/heapster-rbac.yaml

kubectl apply -f https://raw.githubusercontent.com/kubernetes/heapster/master/deploy/kube-config/standalone/heapster-controller.yaml 

kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/alternative/kubernetes-dashboard.yaml

kubectl apply -f /tmp/scripts/azure-init-script/kube-dashboard-admin.yaml

kubectl apply -f https://raw.githubusercontent.com/rook/rook/master/cluster/examples/kubernetes/rook-operator.yaml

kubectl taint nodes --all node-role.kubernetes.io/master-



