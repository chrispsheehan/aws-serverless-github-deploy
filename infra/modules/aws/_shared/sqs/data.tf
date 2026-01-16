data "aws_iam_policy_document" "sqs_read" {
  statement {
    effect = "Allow"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:ChangeMessageVisibility"
    ]
    resources = [aws_sqs_queue.queue.arn]
  }
}

data "aws_iam_policy_document" "sqs_write" {
  statement {
    effect = "Allow"
    actions = [
      "sqs:SendMessage",
      "sqs:SendMessageBatch",
      "sqs:GetQueueAttributes"
    ]
    resources = [aws_sqs_queue.queue.arn]
  }
}
