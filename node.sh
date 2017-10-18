#!/bin/sh

TOKEN=$(cat /tmp/token.txt)

while [ "$(curl -sL -w "%{http_code}\\n" "https://master/api/v1" -o /dev/null --connect-timeout 1 --max-time 1 --insecure)" != "200" ] ; do
 sleep 5
done
 

sudo kubeadm join --token $TOKEN  --discovery-token-unsafe-skip-ca-verification master:443
 
