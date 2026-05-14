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
      var.database_credentials_secret_arn,
    ]
  }
}
