locals {
  account_id        = data.aws_caller_identity.current.account_id
  policy_arn_prefix = "arn:${data.aws_partition.current.partition}:iam::aws:policy"

  # Force depdendence on aws_iam_service_linked_role resources
  asg_role = var.skip_asg_role ? (
    "arn:aws:iam::${local.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
    ) : (
    "arn:aws:iam::${local.account_id}:role/aws-service-role/${aws_iam_service_linked_role.autoscaling[0].aws_service_name}/AWSServiceRoleForAutoScaling"
  )
}

# Cluster IAM Role
resource "aws_iam_role" "cluster" {
  name        = coalesce(var.cluster_iam_role, var.cluster_name)
  description = "IAM Role for the EKS Cluster named ${var.cluster_name}"

  assume_role_policy    = data.aws_iam_policy_document.eks_assume_role_policy.json
  permissions_boundary  = var.cluster_iam_boundary
  force_detach_policies = true
}

resource "aws_iam_role_policy_attachment" "cluster" {
  for_each = toset([
    "${local.policy_arn_prefix}/AmazonEKSClusterPolicy",
    "${local.policy_arn_prefix}/AmazonEKSVPCResourceController",
  ])

  policy_arn = each.key
  role       = aws_iam_role.cluster.name
}

# Workers IAM Role
resource "aws_iam_role" "workers" {
  name        = coalesce(var.workers_iam_role, "${var.cluster_name}-workers")
  description = "IAM Role for the workers in EKS Cluster named ${var.cluster_name}"

  assume_role_policy    = data.aws_iam_policy_document.ec2_assume_role_policy.json
  permissions_boundary  = var.workers_iam_boundary
  force_detach_policies = true
}

resource "aws_iam_role_policy_attachment" "workers" {
  for_each = toset(compact(distinct(concat([
    "${local.policy_arn_prefix}/AmazonEKSWorkerNodePolicy",
    "${local.policy_arn_prefix}/AmazonEC2ContainerRegistryReadOnly",
    "${local.policy_arn_prefix}/AmazonSSMManagedInstanceCore",
    "${local.policy_arn_prefix}/AmazonEKS_CNI_Policy",
  ], var.iam_role_additional_policies))))

  policy_arn = each.value
  role       = aws_iam_role.workers.name
}

# Activate role for ASG
resource "aws_iam_service_linked_role" "autoscaling" {
  count = !var.skip_asg_role ? 1 : 0

  aws_service_name = "autoscaling.amazonaws.com"
}

############################
# IRSA for addon components
############################
module "vpc_cni_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 4.21.1"

  role_name_prefix = "${var.cluster_name}-cni-"
  role_description = "EKS Cluster ${var.cluster_name} VPC CNI Addon"

  attach_vpc_cni_policy = true
  vpc_cni_enable_ipv4   = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-node"]
    }
  }
}

module "ebs_csi_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 4.21.1"

  role_name_prefix = "${var.cluster_name}-ebs-csi-"
  role_description = "EKS Cluster ${var.cluster_name} EBS CSI Addon"

  attach_ebs_csi_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
}

resource "aws_iam_role_policy" "ebs_csi_kms" {
  name_prefix = "kms"
  role        = module.ebs_csi_irsa_role.iam_role_name

  policy = data.aws_iam_policy_document.kms_csi_ebs.json
}
