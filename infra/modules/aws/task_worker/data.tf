data "terraform_remote_state" "worker_messaging" {
  backend = "s3"

  config = {
    bucket = var.state_bucket
    key    = "${var.environment}/aws/worker_messaging/terraform.tfstate"
    region = var.aws_region
  }
}

data "terraform_remote_state" "database" {
  backend = "s3"

  config = {
    bucket = var.state_bucket
    key    = "${var.environment}/aws/database/terraform.tfstate"
    region = var.aws_region
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
