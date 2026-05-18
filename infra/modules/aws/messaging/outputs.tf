output "sns_topic_name" {
  value = aws_sns_topic.worker_events.name
}

output "sns_topic_arn" {
  value = aws_sns_topic.worker_events.arn
}

output "sns_topic_publish_policy_arn" {
  value = aws_iam_policy.topic_publish.arn
}

output "lambda_worker_queue_name" {
  value = module.lambda_worker_queue.sqs_queue_name
}

output "lambda_worker_queue_arn" {
  value = module.lambda_worker_queue.sqs_queue_arn
}

output "lambda_worker_queue_url" {
  value = module.lambda_worker_queue.sqs_queue_url
}

output "lambda_worker_queue_read_policy_arn" {
  value = module.lambda_worker_queue.sqs_queue_read_policy_arn
}

output "lambda_worker_queue_write_policy_arn" {
  value = module.lambda_worker_queue.sqs_queue_write_policy_arn
}

output "lambda_worker_dead_letter_queue_name" {
  value = module.lambda_worker_queue.dead_letter_queue_name
}

output "lambda_worker_dead_letter_queue_arn" {
  value = module.lambda_worker_queue.dead_letter_queue_arn
}

output "lambda_worker_dead_letter_queue_url" {
  value = module.lambda_worker_queue.dead_letter_queue_url
}

output "ecs_worker_queue_name" {
  value = module.ecs_worker_queue.sqs_queue_name
}

output "ecs_worker_queue_arn" {
  value = module.ecs_worker_queue.sqs_queue_arn
}

output "ecs_worker_queue_url" {
  value = module.ecs_worker_queue.sqs_queue_url
}

output "ecs_worker_queue_read_policy_arn" {
  value = module.ecs_worker_queue.sqs_queue_read_policy_arn
}

output "ecs_worker_queue_write_policy_arn" {
  value = module.ecs_worker_queue.sqs_queue_write_policy_arn
}

output "ecs_worker_dead_letter_queue_name" {
  value = module.ecs_worker_queue.dead_letter_queue_name
}

output "ecs_worker_dead_letter_queue_arn" {
  value = module.ecs_worker_queue.dead_letter_queue_arn
}

output "ecs_worker_dead_letter_queue_url" {
  value = module.ecs_worker_queue.dead_letter_queue_url
}
