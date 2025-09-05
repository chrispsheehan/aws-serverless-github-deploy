module "lambda_api" {
  source = "../lambda"

  project_name  = var.project_name
  environment   = var.environment
  lambda_bucket = var.lambda_bucket

  lambda_name    = "api"
  lambda_version = var.lambda_version
}