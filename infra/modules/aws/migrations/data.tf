data "terraform_remote_state" "database" {
  backend = "s3"

  config = {
    bucket = var.state_bucket
    key    = "${var.environment}/aws/database/terraform.tfstate"
    region = var.aws_region
  }
}

data "terraform_remote_state" "security" {
  backend = "s3"

  config = {
    bucket = var.state_bucket
    key    = "${var.environment}/aws/security/terraform.tfstate"
    region = var.aws_region
  }
}

data "aws_vpc" "this" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this.id]
  }

  filter {
    name   = "tag:Name"
    values = ["*private*"]
  }
}

data "aws_iam_policy_document" "database_secret_read" {
  statement {
    actions = [
      "secretsmanager:GetSecretValue",
    ]

    resources = [
      data.terraform_remote_state.database.outputs.credentials_secret_arn,
    ]
  }
}
