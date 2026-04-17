data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket = var.state_bucket
    key    = "${var.environment}/aws/network/terraform.tfstate"
    region = var.aws_region
  }
}

data "terraform_remote_state" "worker_messaging" {
  backend = "s3"

  config = {
    bucket = var.state_bucket
    key    = "${var.environment}/aws/worker_messaging/terraform.tfstate"
    region = var.aws_region
  }
}

data "aws_iam_policy_document" "worker_topic_publish" {
  statement {
    actions = [
      "sns:Publish",
    ]

    resources = [
      data.terraform_remote_state.worker_messaging.outputs.sns_topic_arn,
    ]
  }
}
