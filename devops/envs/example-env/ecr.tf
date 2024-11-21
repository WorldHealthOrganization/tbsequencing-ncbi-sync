locals {
  ecr_app_repo_names = [
    "ncbi-sync"
  ]
}

module "ecr" {
  source             = "git::https://github.com/finddx/seq-treat-tbkb-terraform-modules.git//ecr?ref=ecr-v1.2"
  ecr_app_repo_names = local.ecr_app_repo_names
  project_name       = var.project_name
}
