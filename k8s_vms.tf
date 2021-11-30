locals {
  etcd_count   = var.etcd_count == 1 || var.etcd_count == 2 ? 3 : var.etcd_count
  master_count = var.etcd_count == 0 && (var.master_count == 1 || var.master_count == 2) ? 3 : var.master_count == 1 ? 2 : var.master_count
  worker_count = var.etcd_count == 0 && var.master_count == 0 && var.worker_count < 3 ? 3 : var.worker_count == 0 ? 1 : var.worker_count
}

data "google_compute_zones" "available" {
  status = "UP"
}

module "k8s_etcd" {
  source         = "./modules/gcp_vm_instance"
  count          = local.etcd_count
  name           = "${var.cluster_name}-etcd-n${count.index + 1}"
  machine_type   = var.etcd_machine_type
  boot_disk_size = var.etcd_boot_disk_size
  region         = var.region
  zone           = data.google_compute_zones.available.names[count.index % length(data.google_compute_zones.available.names)]
}

module "k8s_master" {
  source         = "./modules/gcp_vm_instance"
  count          = local.master_count
  name           = "${var.cluster_name}-master-n${count.index + 1}"
  machine_type   = var.master_machine_type
  boot_disk_size = var.master_boot_disk_size
  region         = var.region
  zone           = data.google_compute_zones.available.names[count.index % length(data.google_compute_zones.available.names)]
}

module "k8s_worker" {
  source         = "./modules/gcp_vm_instance"
  count          = local.worker_count
  name           = "${var.cluster_name}-worker-n${count.index + 1}"
  machine_type   = var.worker_machine_type
  boot_disk_size = var.worker_boot_disk_size
  region         = var.region
  zone           = data.google_compute_zones.available.names[count.index % length(data.google_compute_zones.available.names)]
}

resource "null_resource" "create_venv" {
  provisioner "local-exec" {
    command = <<EOT
      rm -rf "${var.cluster_name}"
      python3 -m venv "${var.cluster_name}"
      cd "${var.cluster_name}"
      curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
      ./bin/python3 get-pip.py
      rm -fr get-pip.py
      ./bin/pip3 install ruamel.yaml
    EOT
  }
}

resource "null_resource" "add_etcd" {
  depends_on = [module.k8s_etcd, null_resource.create_venv]

  count = local.etcd_count
  provisioner "local-exec" {
    command = "sleep $((${count.index} * 10)) && ${var.cluster_name}/bin/python3 Scripts/create_inventory.py ${var.cluster_name} ${module.k8s_etcd[count.index].name} ${module.k8s_etcd[count.index].vm_ip} ${var.ansible_ssh_user}"
  }
}

resource "null_resource" "add_master" {
  depends_on = [module.k8s_master, null_resource.add_etcd]

  count = local.master_count
  provisioner "local-exec" {
    command = "sleep $((${count.index} * 10)) && ${var.cluster_name}/bin/python3 Scripts/create_inventory.py ${var.cluster_name} ${module.k8s_master[count.index].name} ${module.k8s_master[count.index].vm_ip} ${var.ansible_ssh_user}"
  }
}

resource "null_resource" "add_worker" {
  depends_on = [module.k8s_worker, null_resource.add_master]

  count = local.worker_count
  provisioner "local-exec" {
    command = "sleep $((${count.index} * 10)) && ${var.cluster_name}/bin/python3 Scripts/create_inventory.py ${var.cluster_name} ${module.k8s_worker[count.index].name} ${module.k8s_worker[count.index].vm_ip} ${var.ansible_ssh_user}"
  }
}

resource "null_resource" "group_inventory" {
  depends_on = [null_resource.add_worker]

  provisioner "local-exec" {
    command = "${var.cluster_name}/bin/python3 Scripts/group_inventory.py ${var.cluster_name}"
  }

}

resource "null_resource" "clone_kubespray" {
  depends_on = [null_resource.group_inventory]

  provisioner "local-exec" {
    command = <<EOT
      cd "${var.cluster_name}"
      git clone https://github.com/kubernetes-sigs/kubespray.git
      ./bin/pip3 install -r kubespray/requirements.txt
      cd kubespray
      cp -rfp inventory/sample inventory/mycluster
      cp ../cluster_inventory.yml inventory/mycluster/hosts.yaml
      ../bin/ansible-playbook -i inventory/mycluster/hosts.yaml -b -v -f 15 -T 180 cluster.yml 2>&1 | tee k8s_setup.logs
    EOT
  }
}
