data "aws_iam_policy_document" "secret_access_document" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
    ]
    resources = [
      data.aws_secretsmanager_secret.entrez.arn
    ]
  }
}

resource "aws_iam_policy" "ncbi_secret_access" {
  name        = "${local.prefix}-ncbi_secret_access_policy"
  description = "Policy to allow reading of the NCBI secret"
  policy      = data.aws_iam_policy_document.secret_access_document.json
}

resource "aws_iam_service_linked_role" "batch" {
  aws_service_name = "batch.amazonaws.com"
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${local.prefix}-ecs_fargate_task_execution_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  tags = {
    Name = "${local.prefix}-ecs_fargate_task_execution_role"
  }
}

locals {
  policy_mapping = {
    ecs_task_execution_role = {
      role   = aws_iam_role.ecs_task_execution_role.name
      policy = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
    },
    ecs_task_rds_iam_access = {
      role   = aws_iam_role.ecs_task_execution_role.name
      policy = data.aws_iam_policy.rds_iam_access.arn
    },
    ecs_task_ncbi_secret_access = {
      role   = aws_iam_role.ecs_task_execution_role.name
      policy = aws_iam_policy.ncbi_secret_access.arn
    }
  }
}

module "ecs-task-policy-mapping" {
  source = "git::git@bitbucket.org:awsopda/who-seq-treat-tbkb-terraform-modules.git//iam_policy_mapping?ref=iam_policy_mapping-v1.1"
  roles  = local.policy_mapping
}
