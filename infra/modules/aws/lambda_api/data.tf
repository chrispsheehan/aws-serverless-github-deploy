data "aws_iam_policy_document" "worker_topic_publish" {
  statement {
    actions = [
      "sns:Publish",
    ]

    resources = [
      var.worker_topic_arn,
    ]
  }
}
