resource "flux_bootstrap_git" "flux" {
  version                = var.flux_version
  path                   = local.flux_target_path
  components_extra       = var.flux_components_extra
  interval               = var.flux_interval
  log_level              = var.flux_log_level
  kustomization_override = file("${path.module}/kustomization.yaml")
  depends_on             = [helm_release.efs_csi_driver]
}
