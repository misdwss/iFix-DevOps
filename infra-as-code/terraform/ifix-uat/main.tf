terraform {
  backend "s3" {
    bucket = "ifix-uat-terraform-state-1"
    key = "terraform"
    region = "ap-south-1"
  }
}

module "network" {
  source             = "../modules/kubernetes/aws/network"
  vpc_cidr_block     = "${var.vpc_cidr_block}"
  cluster_name       = "${var.cluster_name}"
  availability_zones = "${var.network_availability_zones}"
}

module "db" {
  source                        = "../modules/db/aws"
  subnet_ids                    = "${module.network.private_subnets}"
  vpc_security_group_ids        = ["${module.network.rds_db_sg_id}"]
  availability_zone             = "${element(var.availability_zones, 0)}"
  instance_class                = "db.t3.medium"
  engine_version                = "12.17"
  storage_type                  = "gp2"
  storage_gb                    = "100"
  backup_retention_days         = "7"
  administrator_login           = "ifixuat"
  administrator_login_password  = "${var.db_password}"
  db_name                       = "${var.cluster_name}-db"
  environment                   = "${var.cluster_name}"
}


module "iam_user_deployer" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-user"

  name          = "${var.cluster_name}-kube-deployer"
  force_destroy = true  
  create_iam_user_login_profile = false
  create_iam_access_key         = true

  # User "egovterraform" has uploaded his public key here - https://keybase.io/egovterraform/pgp_keys.asc
  pgp_key = "${var.iam_keybase_user}"
}

module "iam_user_admin" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-user"

  name          = "${var.cluster_name}-kube-admin"
  force_destroy = true  
  create_iam_user_login_profile = false
  create_iam_access_key         = true

  # User "egovterraform" has uploaded his public key here - https://keybase.io/egovterraform/pgp_keys.asc
  pgp_key = "${var.iam_keybase_user}"
}

module "iam_user_user" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-user"

  name          = "${var.cluster_name}-kube-user"
  force_destroy = true  
  create_iam_user_login_profile = false
  create_iam_access_key         = true

  # User "test" has uploaded his public key here - https://keybase.io/test/pgp_keys.asc
  pgp_key = "${var.iam_keybase_user}"
}

data "aws_eks_cluster" "cluster" {
  name = "${module.eks.cluster_id}"
}

data "aws_eks_cluster_auth" "cluster" {
  name = "${module.eks.cluster_id}"
}

data "aws_caller_identity" "current" {}

data "tls_certificate" "thumb" {
  url = "${data.aws_eks_cluster.cluster.identity.0.oidc.0.issuer}"
}

data "aws_ssm_parameter" "eks_ami" {
  name = "/aws/service/eks/optimized-ami/${var.kubernetes_version}/amazon-linux-2/recommended/image_id"
}

provider "kubernetes" {
  host                   = "${data.aws_eks_cluster.cluster.endpoint}"
  cluster_ca_certificate = "${base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)}"
  token                  = "${data.aws_eks_cluster_auth.cluster.token}"
  load_config_file       = false
  version                = "~> 1.11"
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "17.24.0"
  cluster_name    = "${var.cluster_name}"
  cluster_version = "${var.kubernetes_version}"
  subnets         = "${concat(module.network.private_subnets, module.network.public_subnets)}"

  tags = "${
    tomap({
      "kubernetes.io/cluster/${var.cluster_name}" = "owned",
      "KubernetesCluster" = "${var.cluster_name}"
    })}"

  vpc_id = "${module.network.vpc_id}"

  worker_groups_launch_template = [
    {
      name                     = "spot-common"
      ami_id                   = data.aws_ssm_parameter.eks_ami.value
      subnets                  = "${concat(slice(module.network.private_subnets, 0, length(var.availability_zones)), slice(module.network.public_subnets, 0, length(var.availability_zones)))}"
      instance_type            = "${var.instance_type}"
      override_instance_types  = "${var.override_instance_types}"
      asg_min_size             = "${var.number_of_worker_nodes_common}"
      asg_max_size             = "${var.number_of_worker_nodes_common}"
      asg_desired_capacity     = "${var.number_of_worker_nodes_common}"
      kubelet_extra_args       = "--node-labels=node.kubernetes.io/lifecycle=spot"
      spot_allocation_strategy = "capacity-optimized"
      spot_instance_pools      = null
      launch_template_name     = "${var.cluster_name}-common-lt"
      launch_template_version  = "$Latest"
    },
    {
      name                     = "spot-ifix"
      ami_id                   = data.aws_ssm_parameter.eks_ami.value
      subnets                  = "${concat(slice(module.network.private_subnets, 0, length(var.availability_zones)), slice(module.network.public_subnets, 0, length(var.availability_zones)))}"
      instance_type            = "${var.instance_type}"
      override_instance_types  = "${var.override_instance_types}"
      asg_min_size             = "${var.number_of_worker_nodes_ifix}"
      asg_max_size             = "${var.number_of_worker_nodes_ifix}"
      asg_desired_capacity     = "${var.number_of_worker_nodes_ifix}"
      kubelet_extra_args       = "--node-labels=node.kubernetes.io/lifecycle=spot,Environment=ifix-uat-ng,Name=ifix-uat-ng"
      spot_allocation_strategy = "capacity-optimized"
      spot_instance_pools      = null
      launch_template_name     = "${var.cluster_name}-ifix-lt"
      launch_template_version  = "$Latest"
    },
    {
      name                     = "spot-mgramseva"
      ami_id                   = data.aws_ssm_parameter.eks_ami.value
      subnets                  = "${concat(slice(module.network.private_subnets, 0, length(var.availability_zones)), slice(module.network.public_subnets, 0, length(var.availability_zones)))}"
      instance_type            = "${var.instance_type}"
      override_instance_types  = "${var.override_instance_types}"
      asg_min_size             = "${var.number_of_worker_nodes_mgramseva}"
      asg_max_size             = "${var.number_of_worker_nodes_mgramseva}"
      asg_desired_capacity     = "${var.number_of_worker_nodes_mgramseva}"
      kubelet_extra_args       = "--node-labels=node.kubernetes.io/lifecycle=spot,Environment=mgramseva-uat-ng,Name=mgramseva-uat-ng"
      spot_allocation_strategy = "capacity-optimized"
      spot_instance_pools      = null
      launch_template_name     = "${var.cluster_name}-mgramseva-lt"
      launch_template_version  = "$Latest"
    },
  ]
  
  map_users    = [
    {
      userarn  = "${module.iam_user_deployer.iam_user_arn}"
      username = "${module.iam_user_deployer.iam_user_name}"
      groups   = ["system:masters"]
    },
    {
      userarn  = "${module.iam_user_admin.iam_user_arn}"
      username = "${module.iam_user_admin.iam_user_name}"
      groups   = ["global-readonly", "digit-user"]
    },
    {
      userarn  = "${module.iam_user_user.iam_user_arn}"
      username = "${module.iam_user_user.iam_user_name}"
      groups   = ["global-readonly"]
    },    
  ]
}

resource "aws_iam_role" "eks_iam" {
  name = "${var.cluster_name}-eks"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid = "EKSWorkerAssumeRole"
        Effect = "Allow",
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}"
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "custom_ebs_policy" {
  name        = "${var.cluster_name}-ebs"
  description = "Custom policy for EBS volume management"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Statement1"
        Effect = "Allow"
        Action = [
          "ec2:CreateVolume",
          "ec2:AttachVolume",
          "ec2:CreateTags"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "kubernetes_service_account" "ebs_service_account" {
  metadata {
    name      = "ebs-service-account"
    namespace = "default"
    annotations = {
      "example.com/annotation" = "${aws_iam_role.eks_iam.arn}"
    }
  }
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEBSCSIDriverPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = "${aws_iam_role.eks_iam.name}"
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEC2FullAccess" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
  role       = "${aws_iam_role.eks_iam.name}"
}

resource "aws_iam_role_policy_attachment" "cluster_custom_ebs" {
  policy_arn = aws_iam_policy.custom_ebs_policy.arn
  role       = "${aws_iam_role.eks_iam.name}"
}

resource "aws_iam_openid_connect_provider" "eks_oidc_provider" {
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = ["${data.tls_certificate.thumb.certificates.0.sha1_fingerprint}"] # This should be empty or provide certificate thumbprints if needed
  url            = "${data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer}" # Replace with the OIDC URL from your EKS cluster details
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name      = data.aws_eks_cluster.cluster.name
  addon_name        = "kube-proxy"
  resolve_conflicts = "OVERWRITE"
}
resource "aws_eks_addon" "core_dns" {
  cluster_name      = data.aws_eks_cluster.cluster.name
  addon_name        = "coredns"
  resolve_conflicts = "OVERWRITE"
}
resource "aws_eks_addon" "aws_ebs_csi_driver" {
  cluster_name      = data.aws_eks_cluster.cluster.name
  addon_name        = "aws-ebs-csi-driver"
  resolve_conflicts = "OVERWRITE"
}

module "zookeeper_ifix" {

  source = "../modules/storage/aws"
  storage_count = 3
  environment = "${var.cluster_name}"
  disk_prefix = "zookeeper-ifix"
  availability_zones = "${var.availability_zones}"
  storage_sku = "gp2"
  disk_size_gb = "5"

}

module "kafka_ifix" {

  source = "../modules/storage/aws"
  storage_count = 3
  environment = "${var.cluster_name}"
  disk_prefix = "kafka-ifix"
  availability_zones = "${var.availability_zones}"
  storage_sku = "gp2"
  disk_size_gb = "100"

}

module "pgadmin" {

  source = "../modules/storage/aws"
  storage_count = 1
  environment = "${var.cluster_name}"
  disk_prefix = "pgadmin"
  availability_zones = "${var.availability_zones}"
  storage_sku = "gp2"
  disk_size_gb = "5"

}


