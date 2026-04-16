data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket = var.state_bucket
    key    = "${var.environment}/aws/network/terraform.tfstate"
    region = var.aws_region
  }
}

data "terraform_remote_state" "cognito" {
  backend = "s3"

  config = {
    bucket = var.state_bucket
    key    = "${var.environment}/aws/cognito/terraform.tfstate"
    region = var.aws_region
  }
}
