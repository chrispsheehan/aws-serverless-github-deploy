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
    DB_HOST                   = data.terraform_remote_state.database.outputs.readwrite_endpoint
    DB_NAME                   = data.terraform_remote_state.database.outputs.database_name
    DB_PORT                   = tostring(data.terraform_remote_state.database.outputs.database_port)
    DB_SECRET_ARN             = data.terraform_remote_state.database.outputs.credentials_secret_arn
  }

  additional_policy_arns = [
    aws_iam_policy.database_secret_read.arn,
  ]

  vpc_subnet_ids = data.aws_subnets.private.ids
  vpc_security_group_ids = [
    data.terraform_remote_state.security.outputs.runtime_sg,
  ]
}
