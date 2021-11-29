#!/usr/bin/env python3

import sys
import ruamel.yaml as yaml
import os


def assign_worker(groupname):
    if worker is None or len(worker) < 3:
        print("The YAML doesn't have enough worker nodes to use as ETCD")
        sys.exit(1)
    else:
        inventory['all']['children'][groupname]['hosts'] = dict(list(worker.items())[:3])


def add_groups():
    if etcd is None and master is None:
        assign_worker('etcd')
        assign_worker('kube_control_plane')
    elif etcd is None:
        inventory['all']['children']['etcd']['hosts'] = dict(list(master.items())[:3])
    elif master is None:
        inventory['all']['children']['kube_control_plane']['hosts'] = dict(list(etcd.items())[:3])

    with open(ymlfile, 'w') as yfw:
        yaml.dump(inventory, yfw, Dumper=yaml.RoundTripDumper)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(f"Usage: ./{sys.argv[0]} <cluster-name>")

    clusterDir = sys.argv[1]
    ymlfile = clusterDir + "/cluster_inventory.yml"

    if os.path.isfile(ymlfile):
        with open(ymlfile, 'r') as yf:
            try:
                inventory = yaml.safe_load(yf)
            except yaml.YAMLError as yerr:
                print(yerr)
    else:
        print(f"YMAL File not exist: {ymlfile}")
        sys.exit(1)

    etcd = inventory['all']['children']['etcd']['hosts']
    master = inventory['all']['children']['kube_control_plane']['hosts']
    worker = inventory['all']['children']['kube_node']['hosts']
    add_groups()

