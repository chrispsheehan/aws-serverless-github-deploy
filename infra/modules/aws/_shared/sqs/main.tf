resource "aws_sqs_queue" "dlq" {
  name                      = var.sqs_dlq_name
  message_retention_seconds = 1209600 # 14 days (max)
}

resource "aws_sqs_queue" "queue" {
  name                      = var.sqs_queue_name
  delay_seconds             = 0
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 5
  })
}

resource "aws_iam_policy" "queue_read_policy" {
  name   = "${var.sqs_queue_name}-sqs-read-policy"
  policy = data.aws_iam_policy_document.sqs_read.json
}

resource "aws_iam_policy" "queue_write_policy" {
  name   = "${var.sqs_queue_name}-sqs-write-policy"
  policy = data.aws_iam_policy_document.sqs_write.json
}
