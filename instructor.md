# Instructor Pre-work

## Clear all DC/OS Clusters from your Local Machine
```
rm -rf ~/.dcos/clusters
```

## Move Existing Kube Config File, If Any, to /tmp/kubectl-config
```
sudo mv ~/.kube/config /tmp/kube-config
```

## Spin up a DC/OS Cluster using Terraform

Example main.tf:
```
variable "dcos_install_mode" {
  description = "specifies which type of command to execute. Options: install or upgrade"
  default     = "install"
}

# Used to determine your public IP for forwarding rules
data "http" "whatismyip" {
  url = "http://whatismyip.akamai.com/"
}

module "dcos" {
  source               = "dcos-terraform/dcos/aws"
  #dcos_instance_os    = "centos_7.5"
  dcos_instance_os     = "coreos_1855.5.0"
  cluster_name         = "kubernetes-training-cluster"
  ssh_public_key_file  = "~/.ssh/Mesosphere.pub"
  admin_ips            = ["${data.http.whatismyip.body}/32"]
  #admin_ips           = ["0.0.0.0/0"]
  dcos_resolvers       = "\n   - 169.254.169.253"
  dcos_security        = "permissive"

  num_masters          = "1"
  num_private_agents   = "7"
  num_public_agents    = "2"

  availability_zones   = ["us-west-2a","us-west-2b","us-west-2c","us-west-2d"]

  private_agents_instance_type = "c3.8xlarge"
  public_agents_instance_type  =  "m4.xlarge"

  dcos_version                 = "1.12.3"

  dcos_variant                 = "ee"
  dcos_license_key_contents    = "${file("./license.txt")}"

  dcos_install_mode = "${var.dcos_install_mode}"
}

output "masters-ips" {
  value = "${module.dcos.masters-ips}"
}

output "cluster-address" {
  value = "${module.dcos.masters-loadbalancer}"
}

output "public-agents-loadbalancer" {
  value = "${module.dcos.public-agents-loadbalancer}"
}
```

Set variables at the top of the `instructor_automated.sh` script
```
export APPNAME=training
export PUBLICIP=34.209.125.234
export CLUSTER=aly-testing
export REGION=us-west-2
clusters=1
```

Run the automated install to get the DC/OS cluster set up with MKE and EdgeLB:
```
./instructor_automated.sh
```

# [Teardown Instructions for once the Lab is Completed](https://github.com/ably77/dcos-kubernetes-training/tree/master/teardown.md)
Follow the link above to access teardown instructions for the cluster
