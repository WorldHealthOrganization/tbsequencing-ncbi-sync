module "jobs" {
  source                        = "git::git@bitbucket.org:awsopda/who-seq-treat-tbkb-terraform-modules.git//batch_job_definition_fargate?ref=batch_job_definition_fargate-v2.1"
  project_name                  = var.project_name
  module_name                   = var.module_name
  environment                   = var.environment
  batch_job_fargate_definitions = local.batch_job_fargate_definitions
}

locals {
  batch_job_fargate_definitions = {
    "${local.prefix}-Sync" = {
      image = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${local.aws_region}.amazonaws.com/${var.project_name}-ncbi-sync:latest"
      command = [
        "python", "/app/src/main.py",
        "--section", "Ref::SECTION",
        "--db_host", "Ref::DB_HOST",
        "--db_name", "Ref::DB_NAME",
        "--db_user", "Ref::DB_USER",
        "--db_password", "Ref::DB_PASSWORD",
        "--db_port", "Ref::DB_PORT",
        "--ncbi_secret_arn", "Ref::NCBI_SECRET",
        "--set_debug", "Ref::DEBUG"
      ]
      container_vcpu   = "2"
      container_memory = "8192"
      jobRoleArn       = aws_iam_role.ecs_task_execution_role.arn
    }
  }
}

module "compute_environment" {
  source            = "git::git@bitbucket.org:awsopda/who-seq-treat-tbkb-terraform-modules.git//batch_compute_env_fargate?ref=batch_compute_env_fargate-v2.1"
  compute_env_name  = "${local.prefix}-fargate"
  service_role_name = aws_iam_service_linked_role.batch.name
  service_role_arn  = aws_iam_service_linked_role.batch.arn
  subnet_ids        = [data.aws_subnets.private-a.ids[0], data.aws_subnets.private-b.ids[0]]
  security_group_id = data.aws_security_group.batch-compute.id
}


module "queue" {
  source               = "git::git@bitbucket.org:awsopda/who-seq-treat-tbkb-terraform-modules.git//batch_queue?ref=batch_queue-v2.0"
  queue_name           = "${local.prefix}-fargate"
  compute_environments = module.compute_environment.arn
}
