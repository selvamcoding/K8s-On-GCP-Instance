# K8s Cluster Setup On GCP Instances
This Terraform Automation helps to setup Kubernetes Cluster on GCP Instance using [Kubespray](https://github.com/kubernetes-sigs/kubespray).

#### Pre-requisites:

1. terraform
2. GCP Project   
3. python3 and virtualenv
4. git

Change the network and subnet in the terraform module if needed - [network](modules/gcp_vm_instance/main.tf#L15)

### Nodes Count conditions
The minimum quorum conditions for K8s nodes are enabled on Terraform as below,

#### ETCD Nodes:
* The etcd_count value should be 0 or >= 3, If it is mentioned 1 or 2, the terraform code will create 3 etcd instances as it is minimum required.

* If etcd_count value is mentioned as 0 in tfvars file, the Master nodes will be used for etcd setup. If the master_count value is also 0, then first 3 worker nodes will be used for etcd.


#### Master nodes
* If etcd_count is 0 and master_count is 1 or 2, then 3 master instances will be created and used for etcd also.

* If etcd_count is 3 and master_count is 0, the ETCD nodes will be used for master setup.

* If etcd_count is 3 and master count is 1, then 2 master nodes will be created for setup as minimum required.

* If both etcd_value and master_count value is 0 in tfvars file, then the first 3 worker nodes will be used for master setup.


#### Worker nodes
* If both etcd_count and master_count value is 0 and worker_count < 3, the 3 worker nodes will be created for all etcd, master and worker setup.

* If etcd or master value is >=3 and worker_count is 0, then atleast one worker will be created for worker setup.


The bottom line, if any node's count value is >=3, it will be created as per the count. For any POC purpose, we need minimum 3 nodes for K8s Cluster setup, in that case, update etcd_count and master_count as 0 and worker_count as 3(the nodes will be used for etcd, master and worker setup)

Update the values on the [k8s_cluster.tfvars](k8s_cluster.tfvars) file based on your requirements.

#### Run Terraform command
```shell
terraform apply -var 'project=<gcp-project>' -var 'credentials=<gcp-access.json>' -var 'ansible_ssh_user=<ansible_ssh_user>' -var-file k8s_cluster.tfvars
```
