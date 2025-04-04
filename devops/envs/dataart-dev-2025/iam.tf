resource "aws_iam_service_linked_role" "batch" {
  aws_service_name = "batch.amazonaws.com"
}

resource "aws_iam_role" "fargate_execution" {
  name               = "${local.prefix}-fargate-execution"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  tags = {
    Name = "${local.prefix}-fargate-execution"
  }
}

resource "aws_iam_role" "fargate_task" {
  name               = "${local.prefix}-fargate-task"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  tags = {
    Name = "${local.prefix}-fargate-task"
  }
}

resource "aws_iam_role" "scheduled_rule" {
  name               = "${local.prefix}-eb-rule"
  assume_role_policy = data.aws_iam_policy_document.assume-eb.json
  tags = {
    Name = "${local.prefix}-eb-rule"
  }

}

locals {
  policies = [
    {
      name        = "fargate-execution"
      description = ""
      policy      = data.aws_iam_policy_document.fargate_execution.json
    },
    {
      name        = "eb-rule"
      description = ""
      policy      = data.aws_iam_policy_document.eb.json
    },
    {
      name        = "s3-put-csv-file"
      description = ""
      policy      = data.aws_iam_policy_document.s3-put-csv-file.json
    }
  ]
  policy_mapping = {
    ecs_task_execution_role = {
      role   = aws_iam_role.fargate_execution.name
      policy = module.policies.policy_arn["fargate-execution"]
    },
    ecs_task_rds_iam_access = {
      role   = aws_iam_role.fargate_task.name
      policy = data.aws_iam_policy.rds_iam_access.arn
    },
    ecs_task_ncbi_secret_access = {
      role   = aws_iam_role.fargate_task.name
      policy = data.aws_iam_policy.ncbi_secret_access.arn
    },
    ecs_task_s3_writting = {
      role   = aws_iam_role.fargate_task.name
      policy = module.policies.policy_arn["s3-put-csv-file"]
    },
    eb = {
      role   = aws_iam_role.scheduled_rule.name
      policy = module.policies.policy_arn["eb-rule"]
    }
  }
}

module "ecs-task-policy-mapping" {
  source = "git::https://github.com/finddx/seq-treat-tbkb-terraform-modules.git//iam_policy_mapping?ref=iam_policy_mapping-v1.1"
  roles  = local.policy_mapping
}

module "policies" {
  source       = "git::https://github.com/finddx/seq-treat-tbkb-terraform-modules.git//iam_policy?ref=iam_policy-v1.0"
  aws_region   = local.aws_region
  environment  = var.environment
  project_name = var.project_name
  module_name  = var.module_name
  policies     = local.policies
}
