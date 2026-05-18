data "aws_iam_policy_document" "topic_publish" {
  statement {
    actions = [
      "sns:Publish"
    ]
    resources = [aws_sns_topic.worker_events.arn]
  }
}

data "aws_iam_policy_document" "lambda_worker_queue_sns_send" {
  statement {
    actions = [
      "sqs:SendMessage"
    ]
    resources = [module.lambda_worker_queue.sqs_queue_arn]

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_sns_topic.worker_events.arn]
    }
  }
}

data "aws_iam_policy_document" "ecs_worker_queue_sns_send" {
  statement {
    actions = [
      "sqs:SendMessage"
    ]
    resources = [module.ecs_worker_queue.sqs_queue_arn]

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_sns_topic.worker_events.arn]
    }
  }
}
