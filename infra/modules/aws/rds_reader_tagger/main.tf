resource "aws_iam_policy" "reader_tag_sync" {
  name   = "${local.lambda_name}-reader-tag-sync"
  policy = data.aws_iam_policy_document.reader_tag_sync.json
}

module "rds_reader_tagger" {
  source = "../_shared/lambda"

  project_name     = var.project_name
  environment      = var.environment
  code_bucket      = var.code_bucket
  otel_sample_rate = var.otel_sample_rate
  timeout_seconds  = 30

  lambda_name = local.lambda_name

  environment_variables = {
    EXPECTED_CLUSTER_IDENTIFIER = data.terraform_remote_state.database.outputs.cluster_identifier
  }

  additional_policy_arns = [
    aws_iam_policy.reader_tag_sync.arn,
  ]
}

resource "aws_cloudwatch_event_rule" "reader_instance_created" {
  name = local.event_rule_name

  event_pattern = jsonencode({
    source      = ["aws.rds"]
    detail-type = ["RDS DB Instance Event"]
    detail = {
      EventID    = ["RDS-EVENT-0005"]
      SourceType = ["DB_INSTANCE"]
    }
  })
}

resource "aws_cloudwatch_event_target" "reader_instance_created" {
  rule      = aws_cloudwatch_event_rule.reader_instance_created.name
  target_id = module.rds_reader_tagger.alias_name
  arn       = module.rds_reader_tagger.alias_arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.rds_reader_tagger.alias_arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.reader_instance_created.arn
}
