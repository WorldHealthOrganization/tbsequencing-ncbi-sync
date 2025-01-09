locals {
  prefix     = "${var.project_name}-${var.module_name}-${var.environment}"
  aws_region = var.aws_region

  tags = {
    Project     = var.project_name
    Module      = var.module_name
    Environment = var.environment
    Terraformed = "true"
  }
}
