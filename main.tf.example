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
  source  = "dcos-terraform/dcos/aws"
  version = "~> 0.1.0"

  providers = {
    aws = "aws"
  }

  dcos_instance_os    = "centos_7.5"
  cluster_name        = "djannot"
  ssh_public_key_file = "~/.ssh/id_rsa.pub"
  #admin_ips           = ["${data.http.whatismyip.body}/32"]
  admin_ips           = ["0.0.0.0/0"]

  num_masters        = "1"
  # 25 private agents for 50 Kubernetes clusters
  num_private_agents = "25"
  num_public_agents  = "2"

  dcos_version = "1.12.1"

  dcos_variant              = "ee"
  dcos_license_key_contents = "${file("./license.txt")}"
  #dcos_variant = "open"

  dcos_security = "strict"
  private_agents_instance_type = "c4.8xlarge"
  public_agents_instance_type = "c4.8xlarge"

  dcos_install_mode = "${var.dcos_install_mode}"
  public_agents_additional_ports = ["8443"]
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
