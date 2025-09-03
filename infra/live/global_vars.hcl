locals {
  aws_region = "eu-west-2"
  allowed_role_actions = [
    "s3:*",
    "iam:*",
    "lambda:*",
    "logs:*"
  ]
}

inputs = {
  aws_region           = local.aws_region
  allowed_role_actions = local.allowed_role_actions
}