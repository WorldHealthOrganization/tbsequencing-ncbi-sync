module "sync_taxonomy" {
  source = "git::https://github.com/finddx/seq-treat-tbkb-terraform-modules.git//step_functions?ref=step_functions-v1.1"

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
      DbUser            = "rdsiamuser"
      DbPassword        = "RDS"
      DbPort            = data.aws_ssm_parameter.db_port.value
  })

  logging_configuration = {
    include_execution_data = true
    level                  = "ALL"
  }

  attach_policy_json = true

  policy_json = data.aws_iam_policy_document.step-func.json

  tags = {
    Name = "${local.prefix}-taxonomy"
  }

  attach_policy = false

  attach_policies = false

  number_of_policies = 1

  attach_policy_statements = false
}

module "sync_INSDC" {
  source = "git::https://github.com/finddx/seq-treat-tbkb-terraform-modules.git//step_functions?ref=step_functions-v1.1"

  name              = "${local.prefix}-sync-INSDC"
  create_role       = false
  use_existing_role = true
  role_arn          = module.sync_taxonomy.role_arn

  definition = templatefile("sync.json",
    {
      JobDefinitionSync = module.jobs.batch_job_fargate_definition_arn["${local.prefix}-Sync"]
      JobQueueArn       = module.queue.batch_job_queue_arn
      DbHost            = data.aws_ssm_parameter.db_host.value
      DbName            = data.aws_ssm_parameter.db_name.value
      DbUser            = "rdsiamuser"
      DbPassword        = "RDS"
      DbPort            = data.aws_ssm_parameter.db_port.value
      NcbiSecret        = data.aws_secretsmanager_secret.entrez.arn
  })

  logging_configuration = {
    include_execution_data = true
    level                  = "ALL"
  }

  attach_policy_json = true

  policy_json = data.aws_iam_policy_document.step-func.json

  tags = {
    Name = "${local.prefix}-sync"
  }

  attach_policy = false

  attach_policies = false

  number_of_policies = 1

  attach_policy_statements = false
}
