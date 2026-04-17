locals {
  lambda_name     = "${var.environment}-${var.project_name}-rds-tag-sync"
  event_rule_name = "${local.lambda_name}-created"
}
