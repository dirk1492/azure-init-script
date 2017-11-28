#!/usr/local/bin/python3
import argparse
import json

from kubernetes import client, config

def add_node(nodes, hostname, ip_address, devices):
  item = {}
  node = {}
  item["node"] = node
  item["devices"] = devices
  nodes.append(item)

  hostnames = {}
  hostnames['manage'] = [hostname]
  hostnames['storage'] = [ip_address]
  node['hostnames'] = hostnames

def get_pods(kubeconfig):
  if kubeconfig == "":  
    config.load_kube_config()
  else:
    config.load_kube_config(kubeconfig)

  v1 = client.CoreV1Api()
  ret = v1.list_pod_for_all_namespaces(watch=False, pretty=True)

  rc = []

  for i in ret.items:
    if i.metadata.name.startswith('glusterfs-'):
      rc.append(i)

  return rc

def create_topology(podlist):
  rc = {}

  clusters = list()
  rc['clusters'] = clusters

  cluster = {}
  clusters.append(cluster)

  nodes = list()
  cluster['nodes'] = nodes

  for pod in podlist:
    add_node(nodes, pod.spec.node_name, pod.status.pod_ip, ['/dev/sdc'])

  return rc

PARSER = argparse.ArgumentParser(description='Autodetect hektei topology file.')
PARSER.add_argument('--kubeconfig', help='path to the kubernetes admin config file (default: ~/.kube.config)', default="")
ARGS = PARSER.parse_args()

PODS = get_pods(ARGS.kubeconfig)
TOPOLOGY = create_topology(PODS)

print json.dumps(TOPOLOGY, sort_keys=False, indent=4, separators=(',', ': '))
