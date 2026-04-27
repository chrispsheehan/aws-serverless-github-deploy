locals {
  vpc_name   = "vpc"
  aws_region = "eu-west-2"
  allowed_role_actions = [
    "s3:*",
    "iam:*",
    "lambda:*",
    "logs:*",
    "apigateway:*",
    "codedeploy:*",
    "application-autoscaling:*",
    "cloudwatch:*",
    "events:*",
    "sqs:*",
    "sns:*",
    "cloudfront:*",
    "xray:*",
    "ec2:*",
    "ecs:*",
    "ecr:*",
    "elasticloadbalancing:*",
    "rds:*",
    "ssm:*",
    "secretsmanager:*",
    "kms:*",
    "acm:*",
    "route53:*",
    "cognito-idp:*",
  ]
  container_port                      = 80
  code_artifact_expiration_days       = 0
  infra_plan_artifact_expiration_days = 30
}

inputs = {
  vpc_name                           = local.vpc_name
  aws_region                         = local.aws_region
  allowed_role_actions               = local.allowed_role_actions
  container_port                     = local.container_port
  code_artifact_expiration_days       = local.code_artifact_expiration_days
  infra_plan_artifact_expiration_days = local.infra_plan_artifact_expiration_days
}
