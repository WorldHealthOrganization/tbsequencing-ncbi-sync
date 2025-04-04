data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "assume-eb" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "fargate_execution" {
  # Accessing the Docker repository for getting the image
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
    ]
    resources = [
      module.ecr.ecr_arns["ncbi-sync"]
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
    ]
    resources = [
      "*"
    ]
  }
  # Writting the logs to Cloudwatch
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [
      "${resource.aws_cloudwatch_log_group.sync.arn}:*",
    ]
  }
}

data "aws_iam_policy_document" "step-func" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = [
      "batch:SubmitJob",
      "batch:DescribeJobs",
      "batch:TerminateJob",
      "states:ListExecutions",
      "events:PutTargets",
      "events:PutRule",
      "events:DescribeRule",

    ]
    resources = [
      "*",
    ]
  }
}


data "aws_iam_policy_document" "s3-put-csv-file" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
    ]
    resources = [
      "${data.aws_ssm_parameter.static_bucket_name.value}/*",
    ]
  }
}



data "aws_iam_policy_document" "eb" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = [
      "states:StartExecution",
    ]
    resources = [
      module.sync_taxonomy.state_machine_arn,
      module.sync_INSDC.state_machine_arn
    ]
  }
}
