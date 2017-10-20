export MONS=$(kubectl -n rook get service -l app=rook-ceph-mon -o json|jq ".items[].spec.clusterIP"|tr -d "\""|sed -e 's/$/:6790/'|paste -s -d, -)
sed "s/INSERT_MONS_HERE/$MONS/g" kube-registry.yaml | kubectl create -f -