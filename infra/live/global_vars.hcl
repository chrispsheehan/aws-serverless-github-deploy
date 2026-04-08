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
    "sqs:*",
    "sns:*",
    "cloudfront:*",
    "xray:*",
    "ec2:*",
    "ecs:*",
    "ecr:*"
  ]
}

inputs = {
  vpc_name             = local.vpc_name
  aws_region           = local.aws_region
  allowed_role_actions = local.allowed_role_actions
}