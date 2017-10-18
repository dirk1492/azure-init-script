#!/bin/sh

TOKEN=$(cat /tmp/token.txt)

kubeadm join --token --discovery-token-unsafe-skip-ca-verification
 