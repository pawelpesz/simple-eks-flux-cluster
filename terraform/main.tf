locals {
  github_repo_url  = (var.github_repo_url != null) ? var.github_repo_url : "https://github.com/${var.github_owner}/${terraform.workspace}.git"
  flux_target_path = "${var.flux_target_base_path}/${var.environment}"
}
