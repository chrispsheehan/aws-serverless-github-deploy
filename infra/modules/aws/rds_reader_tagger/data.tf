data "terraform_remote_state" "database" {
  backend = "s3"

  config = {
    bucket = var.state_bucket
    key    = "${var.environment}/aws/database/terraform.tfstate"
    region = var.aws_region
  }
}

data "aws_iam_policy_document" "reader_tag_sync" {
  statement {
    actions = [
      "rds:AddTagsToResource",
      "rds:DescribeDBClusters",
      "rds:DescribeDBInstances",
      "rds:ListTagsForResource",
      "rds:RemoveTagsFromResource",
    ]

    resources = ["*"]
  }
}
