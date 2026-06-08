locals {
  vpc_name    = "vpc"
  aws_region  = "eu-west-2"
  domain_name = "chrispsheehan.com"
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
    "route53:**",
    "cognito-idp:*",
    "tag:GetResources",
  ]
  code_artifact_expiration_days = 0
}

inputs = {
  vpc_name                      = local.vpc_name
  aws_region                    = local.aws_region
  domain_name                   = local.domain_name
  allowed_role_actions          = local.allowed_role_actions
  code_artifact_expiration_days = local.code_artifact_expiration_days
}
