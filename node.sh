#!/bin/sh

TOKEN=$(cat /home/dil/token.txt)

kubeadm join --token --discovery-token-unsafe-skip-ca-verification
 