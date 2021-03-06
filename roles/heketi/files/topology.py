#!/usr/bin/python
import argparse
import json
import subprocess
import logging


import os.path
from kubernetes import client, config

FORMAT = '%(asctime)-15s %(levelname)-8s %(message)s'
logging.basicConfig(format=FORMAT)
LOG = logging.getLogger(__name__)

class Heketi(object):

    class _Result(object): # pylint: disable=too-few-public-methods
        def __init__(self, heketi, glusterfs):
            self.heketi = heketi
            self.glusterfs = glusterfs

    def __init__(self, kubeconfig, kubectl, gluster_pattern='glusterfs-', heketi_pattern='heketi-'):
        self.kubeconfig = kubeconfig
        self.kubectl = kubectl
        self.pods = None
        self.client = None
        self.heketi_cmd = None

        self._gluster_pattern = gluster_pattern
        self._heketi_pattern = heketi_pattern

    def get_glusterfs_pods(self):
        if not self.pods:
            self.pods = self._get_pods()

        return self.pods

    def get_heketi_pod(self):
        pods = self._get_pods()
        if pods and pods.heketi and pods.heketi.metadata:
            return pods.heketi.metadata.name

        return None

    def get_heketi_ns(self):
        pods = self._get_pods()
        if pods and pods.heketi and pods.heketi.metadata:
            return pods.heketi.metadata.namespace

        return None

    def heketi_exec(self, cmd):
        if not self.heketi_cmd:
            name = self.get_heketi_pod()
            ns = self.get_heketi_ns()

            if name and ns:
                self.heketi_cmd = [self.kubectl, "--kubeconfig", self.kubeconfig, "exec", name, "-n", ns, "--", "sh", "-c"]
            else:
                LOG.error("heketi pod not found")
                exit(0)

        cmdline = list(self.heketi_cmd)
        cmdline.append(cmd)

        LOG.debug(str.join(' ', cmdline))

        return subprocess.check_output(cmdline, shell=False)

    def copy_text(self, text, path):
        cmd = "echo \"" + text.replace("\"", "\\\"") + "\" > " + path
        return self.heketi_exec(cmd) == ""

    def get_topologie(self):
        pods = self._get_pods().glusterfs
        if not pods:
            LOG.error("glusterfs node pods not found")
            exit(0)

        rc = {}

        clusters = list()
        rc['clusters'] = clusters

        cluster = {}
        clusters.append(cluster)

        nodes = list()
        cluster['nodes'] = nodes

        for pod in pods:
            if pod.status.phase == 'Running':
                if pod.spec.hostname and pod.spec.node_name and pod.status.pod_ip:
                    LOG.debug("found " + pod.spec.hostname + " on " + pod.spec.node_name + " (" + pod.status.pod_ip + ")")
                    self._add_node(nodes, pod.spec.node_name, pod.status.pod_ip, ['/dev/sdc'])

        LOG.debug("topology = " + str(json.dumps(rc, indent=4, separators=(',', ': '))))
        return rc

    def _get_pods(self):
        if not self.pods:
            ret = self._get_kube_client().list_pod_for_all_namespaces(watch=False, pretty=True)

            glusterfs = []
            heketi = None

            for i in ret.items:
                if i.metadata.name.startswith(self._gluster_pattern):
                    glusterfs.append(i)
                elif i.metadata.name.startswith(self._heketi_pattern):
                    heketi = i
            self.pods = self._Result(heketi, glusterfs)

        return self.pods

    def _get_kube_client(self):
        if not self.client:
            if not self.kubeconfig or self.kubeconfig == "":
                config.load_kube_config()
            else:
                config.load_kube_config(self.kubeconfig)

            self.client = client.CoreV1Api()

        return self.client

    @staticmethod
    def _strip(topology): # pylint: disable=R0912
        results = []

        for cluster in topology: # pylint: disable=R1702
            if 'nodes' in cluster:
                items = cluster['nodes']
                for item in items:
                    devs = []
                    if 'devices' in item:
                        devices = item['devices']
                        for dev in devices:
                            if 'name' in dev:
                                devs.append(dev['name'])
                            else:
                                devs.append(dev)

                    devs.sort()

                    if 'node' in item:
                        node = item['node']
                        if 'hostnames' in node:
                            hostnames = node['hostnames']
                    elif 'hostnames' in item:
                        hostnames = item['hostnames']
                    else:
                        hostnames = None

                    if hostnames:
                        if 'manage' in hostnames:
                            if 'storage' in hostnames:
                                names = hostnames['manage']
                                ips = hostnames['storage']

                                names.sort()
                                ips.sort()

                                for name in names:
                                    for ip in ips:
                                        for dev in devs:
                                            if name and ip and dev:
                                                results.append(name + ',' + ip + ',' + dev)

        return results

    def check_topology(self, topology):
        data = self.heketi_exec("heketi-cli topology info --json")
        if data:
            tp = json.loads(data.decode('utf-8'))
            LOG.debug(str(json.dumps(tp, indent=4, separators=(',', ': '))))
            return Heketi._is_equal(tp, topology)

        return False


    @staticmethod
    def _is_equal(old, new):
        if (not old) or (not new):
            return False

        cluster_old = Heketi._strip(old['clusters'])
        cluster_new = Heketi._strip(new['clusters'])

        if len(cluster_old) != len(cluster_new):
            return False

        for item in cluster_old:
            if item not in cluster_new:
                return False

        return True

    @staticmethod
    def _add_node(nodes, hostname, ip_address, devices):
        item = {}
        node = {}
        item["node"] = node
        item["devices"] = devices
        nodes.append(item)

        hostnames = {}
        hostnames['manage'] = [hostname]
        hostnames['storage'] = [ip_address]
        node['hostnames'] = hostnames
        node['zone'] = 1



PARSER = argparse.ArgumentParser(description='Autodetect hektei topology file.')
PARSER.add_argument('--kubeconfig', help='path to the kubernetes admin config file (default: ~/.kube.config)', default="")
PARSER.add_argument('--kubectl', help='path to the kubectl (default: kubectl)', default="kubectl")
PARSER.add_argument('--pretty', help='print topology in pretty format', action='store_true')
PARSER.add_argument('--dryrun', help='don\'t load topology to heketi', action='store_true')
PARSER.add_argument('--force', help='reload an existing topology to heketi', action='store_true')
PARSER.add_argument('--loglevel', help='set the loglevel (0 < x < 60)', default=logging.INFO)

ARGS = PARSER.parse_args()

if ARGS.kubeconfig and ARGS.kubeconfig != "" and (not os.path.isfile(ARGS.kubeconfig)):
    LOG.error("Kubernetes configuration file not found.")
    exit(-1)

if (ARGS.kubectl != "kubectl") and (not os.path.isfile(ARGS.kubectl)):
    LOG.error("kubectl not found.")
    exit(-1)


HEKETI = Heketi(ARGS.kubeconfig, ARGS.kubectl)
LOGLEVEL = ARGS.loglevel

LOG.setLevel(LOGLEVEL)

LOG.info("Start topology detection for heketi...")
TOPOLOGY = HEKETI.get_topologie()

if not ARGS.force and HEKETI.check_topology(TOPOLOGY):
    LOG.info("Current topology is already loaded")
    exit(0)

LOG.info('copy topology to /tmp/topology.json on heketi pod')
if ARGS.pretty:
    HEKETI.copy_text(str(json.dumps(TOPOLOGY, indent=4, separators=(',', ': '))), "/tmp/topology.json")
else:
    HEKETI.copy_text(str(json.dumps(TOPOLOGY)), "/tmp/topology.json")

if not ARGS.dryrun:
    LOG.info("Result:\n" + str(HEKETI.heketi_exec("heketi-cli topology load --json=/tmp/topology.json")))
else:
    LOG.info('Please run heketi-cli topology load --json=/tmp/topology.json on ' + HEKETI.get_heketi_pod())
