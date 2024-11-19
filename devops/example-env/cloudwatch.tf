resource "aws_cloudwatch_event_rule" "taxonomy_trigger_query" {
  name = "${local.prefix}-sync-taxonomy"

  # Read: https://docs.aws.amazon.com/eventbridge/latest/userguide/scheduled-events.html
  schedule_expression = "rate(30 days)"
  state               = "DISABLED"
}

resource "aws_cloudwatch_event_target" "sync_taxonomy_step_function_event_target" {
  target_id = "${local.prefix}-sync-taxonomy"
  rule      = aws_cloudwatch_event_rule.taxonomy_trigger_query.name
  arn       = module.sync_taxonomy.state_machine_arn
  role_arn  = resource.aws_iam_role.scheduled_rule.arn
}

resource "aws_cloudwatch_event_rule" "INSDC_trigger_query" {
  name = "${local.prefix}-sync-INSDC"

  # Read: https://docs.aws.amazon.com/eventbridge/latest/userguide/scheduled-events.html
  schedule_expression = "rate(1 day)"
  state               = "DISABLED"
}

resource "aws_cloudwatch_event_target" "sync_INSDC_step_function_event_target" {
  target_id = "${local.prefix}-sync-INSDC"
  rule      = aws_cloudwatch_event_rule.INSDC_trigger_query.name
  arn       = module.sync_INSDC.state_machine_arn
  role_arn  = resource.aws_iam_role.scheduled_rule.arn
}

resource "aws_cloudwatch_log_group" "sync" {
  name = "/aws/batch/job/${local.prefix}-Sync"
  tags = {
    Name = "/aws/batch/job/${local.prefix}-Sync",
  }
}
