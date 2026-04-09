data "terraform_remote_state" "task_worker" {
  count   = var.bootstrap ? 0 : 1
  backend = "s3"

  config = {
    bucket = var.state_bucket
    key    = "${var.environment}/aws/task_worker/terraform.tfstate"
    region = var.aws_region
  }
}

data "terraform_remote_state" "lambda_worker" {
  backend = "s3"

  config = {
    bucket = var.state_bucket
    key    = "${var.environment}/aws/lambda_worker/terraform.tfstate"
    region = var.aws_region
  }
}

data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket = var.state_bucket
    key    = "${var.environment}/aws/network/terraform.tfstate"
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

data "terraform_remote_state" "cluster" {
  backend = "s3"

  config = {
    bucket = var.state_bucket
    key    = "${var.environment}/aws/cluster/terraform.tfstate"
    region = var.aws_region
  }
}

data "terraform_remote_state" "api" {
  backend = "s3"

  config = {
    bucket = var.state_bucket
    key    = "${var.environment}/aws/api/terraform.tfstate"
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
