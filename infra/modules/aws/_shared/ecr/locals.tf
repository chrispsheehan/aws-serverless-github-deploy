locals {
  repository_name = "${var.project_name}-ecs-worker"
  ecr_pull_actions = [
    "ecr:BatchCheckLayerAvailability",
    "ecr:BatchGetImage",
    "ecr:GetDownloadUrlForLayer",
  ]
  allowed_account_principals = [
    for account_id in var.allowed_read_aws_account_ids : "arn:aws:iam::${account_id}:root"
  ]
}
