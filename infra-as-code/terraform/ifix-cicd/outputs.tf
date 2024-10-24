output "vpc_id" {
  value = module.network.vpc_id
}

output "private_subnets" {
  value = module.network.private_subnets
}

output "public_subnets" {
  value = module.network.public_subnets
}

output "master_nodes_sg_id" {
  value = module.network.master_nodes_sg_id
}

output "worker_nodes_sg_id" {
  value = module.network.worker_nodes_sg_id
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane."
  value       = module.eks.cluster_endpoint
}

output "kubectl_config" {
  description = "kubectl config as generated by the module."
  value       = module.eks.kubeconfig
}

output "config_map_aws_auth" {
  description = "A kubernetes configuration to authenticate to this EKS cluster."
  value       = module.eks.config_map_aws_auth
}

output "jenkins" {
  value = "${module.jenkins.volume_ids}"
}

output "deployer_secret_key_cmd" {
  value = "${
  tomap({
  (module.iam_user_deployer.iam_access_key_id) = module.iam_user_deployer.keybase_secret_key_decrypt_command
  })}"
}

output "admin_secret_key_cmd" {
  value = "${
  tomap({
  (module.iam_user_admin.iam_access_key_id) = module.iam_user_admin.keybase_secret_key_decrypt_command
  })}"
}

output "user_secret_key_cmd" {
  value = "${
  tomap({
  (module.iam_user_user.iam_access_key_id) = module.iam_user_user.keybase_secret_key_decrypt_command
  })}"
}