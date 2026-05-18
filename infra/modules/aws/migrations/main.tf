resource "aws_iam_policy" "database_secret_read" {
  name   = "${local.lambda_name}-database-secret-read"
  policy = data.aws_iam_policy_document.database_secret_read.json
}

module "migrations" {
  source = "../_shared/lambda"

  project_name     = var.project_name
  environment      = var.environment
  code_bucket      = var.code_bucket
  otel_sample_rate = var.otel_sample_rate
  timeout_seconds  = 120

  lambda_name = local.lambda_name

  environment_variables = {
    DB_HOST       = var.database_readwrite_endpoint
    DB_NAME       = var.database_name
    DB_PORT       = tostring(var.database_port)
    DB_SECRET_ARN = var.database_credentials_secret_arn
  }

  additional_policy_arns = [
    aws_iam_policy.database_secret_read.arn,
  ]

  vpc_subnet_ids = data.aws_subnets.private.ids
  vpc_security_group_ids = [
    var.runtime_security_group_id,
  ]
}
