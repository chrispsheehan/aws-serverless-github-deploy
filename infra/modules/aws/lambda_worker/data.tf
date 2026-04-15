data "terraform_remote_state" "worker_messaging" {
  backend = "s3"

  config = {
    bucket = var.state_bucket
    key    = "${var.environment}/aws/worker_messaging/terraform.tfstate"
    region = var.aws_region
  }
}
