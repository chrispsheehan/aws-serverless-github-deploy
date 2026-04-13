data "terraform_remote_state" "lambda_worker" {
  backend = "s3"

  config = {
    bucket = var.state_bucket
    key    = "${var.environment}/aws/lambda_worker/terraform.tfstate"
    region = var.aws_region
  }
}
