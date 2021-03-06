#!/bin/bash

HOSTNAME=$(hostname)
HostIP=$(ifconfig eth0 | grep "inet addr:" | cut -d':' -f 2 | cut -d' ' -f 1)

docker stop etcd && docker rm etcd
rm -rf /var/lib/etcd-cluster
mkdir -p /var/lib/etcd-cluster

docker run -d \
--restart always \
-v /etc/ssl/certs:/etc/ssl/certs \
-v /var/lib/etcd-cluster:/var/lib/etcd \
-p 4001:4001 \
-p 2380:2380 \
-p 2379:2379 \
--name etcd \
gcr.io/google_containers/etcd-amd64:3.0.17 \
etcd --name=etcd${HOSTNAME:4} \
--advertise-client-urls=http://${HostIP}:2379,http://${HostIP}:4001 \
--listen-client-urls=http://0.0.0.0:2379,http://0.0.0.0:4001 \
--initial-advertise-peer-urls=http://${HostIP}:2380 \
--listen-peer-urls=http://0.0.0.0:2380 \
--initial-cluster-token=59563cd6-b558-11e7-8157-000d3a1c15d2 \
--initial-cluster=etcd0=http://node0:2380,etcd1=http://node1:2380,etcd2=http://node2:2380 \
--initial-cluster-state=new \
--auto-tls \
--peer-auto-tls \
--data-dir=/var/lib/etcd