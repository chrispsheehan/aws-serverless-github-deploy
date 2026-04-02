data "terraform_remote_state" "task_consumer" {
  backend = "s3"

  config = {
    bucket = var.state_bucket
    key    = "${var.environment}/aws/task_consumer/terraform.tfstate"
    region = var.aws_region
  }
}
