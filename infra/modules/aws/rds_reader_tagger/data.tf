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
