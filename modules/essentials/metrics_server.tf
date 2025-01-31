locals {
  helm_config = merge(
    var.metrics_server_helm_config_defaults,
    var.metrics_server_helm_config
  )
}

module "helm_metrics_server" {
  count = var.metrics_server_enabled ? 1 : 0

  source  = "SPHTech-Platform/release/helm"
  version = "~> 0.1.0"

  helm_config = local.helm_config
}
