#######################
# EKS Cluster Settings
#######################
variable "cluster_name" {
  description = "EKS Cluster Name"
  type        = string
}

variable "cluster_version" {
  description = "EKS Cluster Version"
  type        = string
  default     = "1.22"
}

variable "cluster_enabled_log_types" {
  description = "A list of the desired control plane logs to enable. For more information, see Amazon EKS Control Plane Logging documentation (https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html)"
  type        = list(string)
  default     = ["audit", "api", "authenticator"]
}

#######################
# Cluster IAM Role
#######################
variable "cluster_iam_role" {
  description = "Cluster IAM Role name. If undefined, is the same as the cluster name"
  type        = string
  default     = ""
}

variable "cluster_iam_boundary" {
  description = "IAM boundary for the cluster IAM role, if any"
  type        = string
  default     = null
}

#######################
# Workers IAM Role
#######################
variable "workers_iam_role" {
  description = "Workers IAM Role name. If undefined, is the same as the cluster name suffixed with 'workers'"
  type        = string
  default     = ""
}

variable "workers_iam_boundary" {
  description = "IAM boundary for the workers IAM role, if any"
  type        = string
  default     = null
}

variable "iam_role_additional_policies" {
  description = "Additional policies to be added to the IAM role"
  type        = list(string)
  default     = []
}

#######################
# Cluster RBAC (AWS Auth)
#######################

# For Self managed nodes groups set the create_aws_auth to true
variable "create_aws_auth_configmap" {
  description = "Determines whether to create the aws-auth configmap. NOTE - this is only intended for scenarios where the configmap does not exist (i.e. - when using only self-managed node groups). Most users should use `manage_aws_auth_configmap`"
  type        = bool
  default     = true
}

variable "manage_aws_auth_configmap" {
  description = "Determines whether to manage the contents of the aws-auth configmap"
  type        = bool
  default     = true
}

variable "enable_cluster_windows_support" {
  description = "Determines whether to create the amazon-vpc-cni configmap and windows worker roles into aws-auth."
  type        = bool
  default     = false
}

variable "role_mapping" {
  description = "List of IAM roles to give access to the EKS cluster"
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

variable "user_mapping" {
  description = "List of IAM Users to give access to the EKS Cluster"
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

#######################
# Cluster Networking
#######################

variable "cluster_endpoint_private_access" {
  description = "Indicates whether or not the Amazon EKS private API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access" {
  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks which can access the Amazon EKS public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cluster_additional_security_group_ids" {
  description = "List of additional, externally created security group IDs to attach to the cluster control plane"
  type        = list(string)
  default     = []
}

variable "vpc_id" {
  description = "VPC ID to deploy the cluster into"
  type        = string
}

variable "subnet_ids" {
  description = "A list of subnet IDs where the EKS cluster (ENIs) will be provisioned along with the nodes/node groups. Node groups can be deployed within a different set of subnet IDs from within the node group configuration"
  type        = list(string)
}

variable "cluster_service_ipv4_cidr" {
  description = "The CIDR block to assign Kubernetes service IP addresses from. If you don't specify a block, Kubernetes assigns addresses from either the 10.100.0.0/16 or 172.20.0.0/16 CIDR blocks"
  type        = string
  default     = null
}


variable "cluster_security_group_additional_rules" {
  description = "List of additional security group rules to add to the cluster security group created. Set `source_node_security_group = true` inside rules to set the `node_security_group` as source"
  type        = any
  default     = {}
}

variable "node_security_group_additional_rules" {
  description = "List of additional security group rules to add to the node security group created. Set `source_cluster_security_group = true` inside rules to set the `cluster_security_group` as source"
  type        = any
  default     = {}
}

#######################
# Other IAM
#######################
variable "skip_asg_role" {
  description = "Skip creating ASG Service Linked Role if it's already created"
  type        = bool
  default     = false
}

#######################
# Nodes Configuration
# It is recommended that users create their own node pools using the relevant submodules
# at https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest
# after the EKS cluster is created.
#
# The configuration here is deliberately kept simpler to avoid overcomplicating things. We use
# some "sane" defaults so that the basic services that an EKS cluster need can run to create a
# "default" node group
#######################
variable "default_group_name" {
  description = "Name of the default node group"
  type        = string
  default     = "default"
}

variable "default_group_launch_template_name" {
  description = "Name of the default node group launch template"
  type        = string
  default     = "default"
}

variable "default_group_ami_id" {
  description = "The AMI from which to launch the defualt group instance. If not supplied, EKS will use its own default image"
  type        = string
  default     = ""
}

variable "default_group_instance_types" {
  description = "Instance type for the default node group"
  type        = list(string)
  default     = ["m5a.xlarge", "m5.xlarge", "m5n.xlarge", "m5zn.xlarge"]
}

variable "default_group_min_size" {
  description = "Configuration for min default node group size"
  type        = number
  default     = 1
}

variable "default_group_max_size" {
  description = "Configuration for max default node group size"
  type        = number
  default     = 5
}

variable "default_group_volume_size" {
  description = "Size of the persistentence volume for the default group"
  type        = number
  default     = 50
}

variable "default_group_subnet_ids" {
  description = "Subnet IDs to create the default group ASGs in"
  type        = list(string)
  default     = []
}

variable "default_group_node_labels" {
  description = "Additional node label for default group"
  type        = map(string)
  default     = {}
}

variable "only_critical_addons_enabled" {
  description = "Enabling this option will taint default node group with CriticalAddonsOnly=true:NoSchedule taint. Changing this forces a new resource to be created."
  type        = bool
  default     = false
}

variable "eks_managed_node_groups" {
  description = "Map of EKS managed node group definitions to create"
  type        = any
  default     = {}
}

variable "eks_managed_node_group_defaults" {
  description = "Map of EKS managed node group default configurations"
  type        = any
  default = {
    disk_size = 50

    metadata_options = {
      http_endpoint               = "enabled"
      http_tokens                 = "required"
      http_put_response_hop_limit = 1
      instance_metadata_tags      = "disabled"
    }

    update_launch_template_default_version = true
    protect_from_scale_in                  = false

    ebs_optimized     = true
    enable_monitoring = true

    create_iam_role       = false
    create_security_group = false
  }
}

variable "force_imdsv2" {
  description = "Force IMDSv2 metadata server."
  type        = bool
  default     = true
}

variable "force_irsa" {
  description = "Force usage of IAM Roles for Service Account"
  type        = bool
  default     = true
}
