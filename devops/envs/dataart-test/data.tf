data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_ssm_parameter" "db_host" {
  name = "/${var.environment}/db_host"
}

data "aws_ssm_parameter" "db_name" {
  name = "/${var.environment}/db_name"
}

data "aws_ssm_parameter" "db_port" {
  name = "/${var.environment}/db_port"
}

data "aws_subnets" "public-a" {
  filter {
    name   = "tag:Name"
    values = ["${var.project_name}-main-${var.environment}-public-${local.aws_region}a"]
  }
}
data "aws_subnets" "public-b" {
  filter {
    name   = "tag:Name"
    values = ["${var.project_name}-main-${var.environment}-public-${local.aws_region}b"]
  }
}
data "aws_security_group" "batch-compute" {
  filter {
    name   = "tag:Label"
    values = ["${var.project_name}-main-${var.environment}-batch-compute"]
  }
}

data "aws_iam_policy" "rds_iam_access" {
  arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${var.project_name}-main-${var.environment}-rds_access"
}

data "aws_secretsmanager_secret" "entrez" {
  name = "${var.environment}/ncbi-entrez"
}
