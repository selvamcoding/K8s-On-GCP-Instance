#!/usr/bin/env python3

import sys
import ruamel.yaml as yaml
import os
import re


def load_yml(ymlfile, vmname, vmipaddr, ansibleuser):
    inventory = None

    if os.path.isfile(ymlfile):
        with open(ymlfile, 'r') as yf:
            try:
                inventory = yaml.safe_load(yf)
            except yaml.YAMLError as yerr:
                print(yerr)

    if inventory is None:
        inventory = {
            'all': {
                'hosts': None,
                'children': {
                    'kube_control_plane': {
                        'hosts': None
                    },
                    'kube_node': {
                        'hosts': None
                    },
                    'etcd': {
                        'hosts': None
                    },
                    'k8s_cluster': {
                        'children': {
                            'kube_control_plane': None,
                            'kube_node': None,
                        }
                    },
                    'calico_rr': {
                        'hosts': {}
                    }
                }
            }
        }

    with open(ymlfile, 'w') as yfw:
        hosts_env = dict()
        hosts_env['ansible_host'] = vmipaddr
        hosts_env['ansible_ssh_user'] = ansibleuser

        if inventory['all']['hosts'] is None:
            inventory['all']['hosts'] = {}

        inventory['all']['hosts'][vmname] = hosts_env

        group_name = None
        if re.search('master', vmname):
            group_name = 'kube_control_plane'
        elif re.search('worker', vmname):
            group_name = 'kube_node'
        elif re.search('etcd', vmname):
            group_name = 'etcd'

        if group_name:
            if inventory['all']['children'][group_name]['hosts'] is None:
                inventory['all']['children'][group_name]['hosts'] = {vmname: None}
            else:
                inventory['all']['children'][group_name]['hosts'][vmname] = None

        yaml.dump(inventory, yfw, Dumper=yaml.RoundTripDumper)


if __name__ == "__main__":
    if len(sys.argv) != 5:
        print(f"Usage: ./{sys.argv[0]} <cluster-name> <vm-name> <vm-ipaddr> <ansible-ssh-user>")
        sys.exit(1)

    clusterDir = sys.argv[1]
    vmName = sys.argv[2]
    vmIPAddr = sys.argv[3]
    ansibleUser = sys.argv[4]

    load_yml(clusterDir + "/cluster_inventory.yml", vmName, vmIPAddr, ansibleUser)
