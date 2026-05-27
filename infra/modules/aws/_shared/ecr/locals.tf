locals {
  repository_name = var.ecr_repository_name
  ecr_pull_actions = [
    "ecr:BatchCheckLayerAvailability",
    "ecr:BatchGetImage",
    "ecr:GetDownloadUrlForLayer",
  ]
  allowed_account_principals = [
    for account_id in var.allowed_read_aws_account_ids : "arn:aws:iam::${account_id}:root"
  ]
  bootstrap_image_uri = "${aws_ecr_repository.this.repository_url}:${var.bootstrap_image_tag}"
}
