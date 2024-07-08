#
# Variables Configuration
#

variable "cluster_name" {
  default = "ifix-cicd"
}

variable "vpc_cidr_block" {
  default = "192.168.0.0/16"
}

variable "network_availability_zones" {
  default = ["ap-south-1b", "ap-south-1a"]
}

variable "availability_zones" {
  default = ["ap-south-1b"]
}

variable "kubernetes_version" {
  default = "1.29"
}

variable "instance_type" {
  default = "m4.large"
}

variable "override_instance_types" {
  default = ["t3.xlarge", "r5ad.xlarge", "r5a.xlarge", "t3a.xlarge"]
}

variable "number_of_worker_nodes" {
  default = "2"
}

variable "spot_max_price" {
  default = "0.0538"
}

variable "ssh_key_name" {
  default = "ifix-cicd"
}
variable "iam_keybase_user" {
  default = "keybase:egovterraform"
}
