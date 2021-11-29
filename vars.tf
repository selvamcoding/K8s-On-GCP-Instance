variable "credentials" {}

variable "project" {}

variable "region" {}

variable "cluster_name" {
  default = "k8s-dev"
}

variable "ansible_ssh_user" {}

variable "etcd_count" {}

variable "etcd_machine_type" {}

variable "etcd_boot_disk_size" {}

variable "master_count" {}

variable "master_machine_type" {}

variable "master_boot_disk_size" {}

variable "worker_count" {}

variable "worker_machine_type" {}

variable "worker_boot_disk_size" {}