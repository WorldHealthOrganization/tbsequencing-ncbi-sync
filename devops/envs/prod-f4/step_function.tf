module "sync_taxonomy" {
  source = "git::https://github.com/finddx/seq-treat-tbkb-terraform-modules.git//step_functions?ref=step_functions-v1.0"

  name              = "${local.prefix}-sync-taxonomy"
  create_role       = true
  use_existing_role = false
  role_name         = "${local.prefix}-sync-taxonomy"

  definition = templatefile("taxonomy.json",
    {
      JobDefinitionSync = module.jobs.batch_job_fargate_definition_arn["${local.prefix}-Sync"]
      JobQueueArn       = module.queue.batch_job_queue_arn
      DbHost            = data.aws_ssm_parameter.db_host.value
      DbName            = data.aws_ssm_parameter.db_name.value
      DbUser            = "fdxuser"
      DbPassword        = "RDS"
      DbPort            = data.aws_ssm_parameter.db_port.value
  })

  logging_configuration = {
    include_execution_data = true
    level                  = "ALL"
  }

  attach_policy_json = true
  trusted_entities = [
    "events.amazonaws.com"
  ]
  policy_json  = data.aws_iam_policy_document.taxonomy.json
  policy_jsons = [data.aws_iam_policy_document.xray.json]
  tags = {
    Name = "${local.prefix}-taxonomy"
  }
  attach_policy = false
  policy        = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"

  attach_policies    = false
  policies           = ["arn:aws:iam::aws:policy/AWSXrayReadOnlyAccess"]
  number_of_policies = 1

  attach_policy_statements = false
}

module "sync_INSDC" {
  source = "git::https://github.com/finddx/seq-treat-tbkb-terraform-modules.git//step_functions?ref=step_functions-v1.0"

  name              = "${local.prefix}-sync-INSDC"
  create_role       = true
  use_existing_role = false
  role_name         = "${local.prefix}-sync-INSDC"

  definition = templatefile("sync.json",
    {
      JobDefinitionSync = module.jobs.batch_job_fargate_definition_arn["${local.prefix}-Sync"]
      JobQueueArn       = module.queue.batch_job_queue_arn
      DbHost            = data.aws_ssm_parameter.db_host.value
      DbName            = data.aws_ssm_parameter.db_name.value
      DbUser            = "fdxuser"
      DbPassword        = "RDS"
      DbPort            = data.aws_ssm_parameter.db_port.value
      NcbiSecret        = data.aws_secretsmanager_secret.entrez.arn
  })

  logging_configuration = {
    include_execution_data = true
    level                  = "ALL"
  }

  attach_policy_json = true
  trusted_entities = [
    "events.amazonaws.com"
  ]
  policy_json  = data.aws_iam_policy_document.taxonomy.json
  policy_jsons = [data.aws_iam_policy_document.xray.json]
  tags = {
    Name = "${local.prefix}-sync"
  }
  attach_policy = false
  policy        = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"

  attach_policies    = false
  policies           = ["arn:aws:iam::aws:policy/AWSXrayReadOnlyAccess"]
  number_of_policies = 1

  attach_policy_statements = false
}

data "aws_iam_policy_document" "taxonomy" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = [
      "batch:SubmitJob",
      "batch:DescribeJobs",
      "batch:TerminateJob",
      "events:PutTargets",
      "events:PutRule",
      "events:DescribeRule",
      "batch:DescribeJobQueues",
      "lambda:InvokeFunction",
      "states:StartExecution",
      "states:ListExecutions"
    ]
    resources = [
      "*",
    ]
  }
}

data "aws_iam_policy_document" "xray" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = [
      "xray:*"
    ]
    resources = [
      "*",
    ]
  }
}
