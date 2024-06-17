#
# Variables Configuration
#

variable "cluster_name" {
  default = "magramsewa-prod"
}

variable "vpc_cidr_block" {
  default = "10.1.0.0/16"
}

variable "network_availability_zones" {
  default = ["ap-south-1a", "ap-south-1b"]
}

variable "availability_zones" {
  default = ["ap-south-1a"]
}

variable "node_pool_zone" {
 default = ["ap-south-1a"] 
}

variable "kubernetes_version" {
  default = "1.29"
}

variable "instance_type" {
  default = "r5ad.large"
}

variable "override_instance_types" {
  default = ["r5ad.large", "r5d.large", "r5a.large", "m4.xlarge", "t3a.xlarge"]
  
}

variable "number_of_worker_nodes" {
  default = "1"
}

variable "ssh_key_name" {
  default = "magramsewa-uat"
}
variable "iam_keybase_user" {
 default = "keybase:egovterraform"
}

variable "db_password" {}


