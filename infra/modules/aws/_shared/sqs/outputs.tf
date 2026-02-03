output "sqs_queue_name" {
  value = aws_sqs_queue.queue.name
}

output "sqs_queue_arn" {
  value = aws_sqs_queue.queue.arn
}

output "sqs_queue_url" {
  value = aws_sqs_queue.queue.url
}

output "dead_letter_queue_name" {
  value = aws_sqs_queue.dlq.name
}

output "dead_letter_queue_arn" {
  value = aws_sqs_queue.dlq.arn
}

output "dead_letter_queue_url" {
  value = aws_sqs_queue.dlq.url
}

output "sqs_queue_read_policy_arn" {
  value = aws_iam_policy.queue_read_policy.arn
}

output "sqs_queue_write_policy_arn" {
  value = aws_iam_policy.queue_write_policy.arn
}
