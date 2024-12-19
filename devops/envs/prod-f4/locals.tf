locals {
  prefix     = "${var.project_name}-${var.module_name}-${var.environment}"
  aws_region = data.aws_region.current.name

  tags = {
    Project     = var.project_name
    Module      = var.module_name
    Environment = var.environment
    Terraformed = "true"
  }
}
