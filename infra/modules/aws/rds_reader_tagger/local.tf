locals {
  lambda_name     = "${var.environment}-${var.project_name}-rds-reader-tagger"
  event_rule_name = "${local.lambda_name}-instance-created"
}
