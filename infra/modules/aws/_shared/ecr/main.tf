resource "aws_ecr_repository" "this" {
  name = local.repository_name

  force_delete = var.force_delete

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }
}

resource "aws_ecr_repository_policy" "this" {
  repository = aws_ecr_repository.this.name
  policy     = data.aws_iam_policy_document.allow_ecr_pull_policy.json
}

resource "aws_ecr_lifecycle_policy" "this" {
  count = var.image_expiration_days > 0 ? 1 : 0

  repository = aws_ecr_repository.this.name
  policy     = data.aws_ecr_lifecycle_policy_document.this[0].json
}

provider "docker" {
  registry_auth {
    address  = data.aws_ecr_authorization_token.this.proxy_endpoint
    username = data.aws_ecr_authorization_token.this.user_name
    password = data.aws_ecr_authorization_token.this.password
  }
}

resource "docker_image" "bootstrap" {
  name         = var.bootstrap_image_source
  keep_locally = false
}

resource "docker_tag" "bootstrap" {
  source_image = docker_image.bootstrap.name
  target_image = local.bootstrap_image_uri
}

resource "docker_registry_image" "bootstrap" {
  name = docker_tag.bootstrap.target_image

  depends_on = [
    aws_ecr_repository_policy.this,
  ]
}
