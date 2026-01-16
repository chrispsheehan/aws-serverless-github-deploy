resource "aws_sqs_queue" "queue" {
  name                      = var.sqs_queue_name
  delay_seconds             = 0
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10
}

resource "aws_iam_policy" "queue_read_policy" {
  name   = "${var.sqs_queue_name}-sqs-read-policy"
  policy = data.aws_iam_policy_document.sqs_read.json
}

resource "aws_iam_policy" "queue_write_policy" {
  name   = "${var.sqs_queue_name}-sqs-write-policy"
  policy = data.aws_iam_policy_document.sqs_write.json
}
