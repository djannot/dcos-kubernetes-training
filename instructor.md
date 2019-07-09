# Instructor Pre-work

## Clear all DC/OS Clusters from your Local Machine
```
rm -rf ~/.dcos/clusters
```

## Move Existing Kube Config File, If Any, to /tmp/kubectl-config
```
sudo mv ~/.kube/config /tmp/kube-config
```

## Set up MAWS
In order to access the Mesosphere AWS account, it is required to set up MAWS

## Spin up a DC/OS Cluster using Terraform

Example main.tf:
```
provider "aws" {
  region = "us-east-1"
}

variable "dcos_install_mode" {
  description = "specifies which type of command to execute. Options: install or upgrade"
  default     = "install"
}

data "http" "whatismyip" {
  url = "http://whatismyip.akamai.com/"
}

module "dcos" {
  #source  = "dcos-terraform/dcos/aws"
  source  = "git::ssh://git@github.com/dcos-terraform/terraform-aws-dcos?ref=release/v0.2"
  custom_dcos_download_path = "http://downloads.mesosphere.com/dcos-enterprise/stable/1.13.2/dcos_generate_config.ee.sh"
  version = "~> 0.2.0"

  providers = {
    aws = "aws"
  }

  cluster_name        = "djannot"
  dcos_instance_os    = "centos_7.5"
  ssh_public_key_file = "~/.ssh/id_rsa.pub"
  #admin_ips           = ["${data.http.whatismyip.body}/32"]
  admin_ips           = ["0.0.0.0/0"]

  num_masters        = "1"
  # 30 private agents for 50 Kubernetes clusters
  num_private_agents = "30"
  num_public_agents  = "2"

  dcos_version = "1.13.2"

  dcos_variant              = "ee"
  dcos_license_key_contents = "${file("./license.txt")}"
  #dcos_variant = "open"

  dcos_security = "strict"
  private_agents_instance_type = "c4.8xlarge"
  public_agents_instance_type = "c4.8xlarge"

  public_agents_additional_ports = ["8443", "9999", "10500", "10339"]

  tags = {
    owner = "denisjannot",
    expiration = "12h"
  }
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

Don't forget to update the owner tag.

Set variables at the top of the `instructor_automated.sh` script
```
export APPNAME=training
export PUBLICIP=34.209.125.234
export CLUSTER=aly-testing
export REGION=us-west-2
clusters=1
```

Install the AWS CLI:
```
brew install awscli
```

Run the automated install to get the DC/OS cluster set up with MKE and EdgeLB:
```
./instructor_automated.sh <URL of the DC/OS cluster including https>
```

# [Teardown Instructions for once the Lab is Completed](https://github.com/djannot/dcos-kubernetes-training/tree/master/teardown.md)
Follow the link above to access teardown instructions for the cluster
