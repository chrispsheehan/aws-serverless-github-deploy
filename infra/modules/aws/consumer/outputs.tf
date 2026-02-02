output "cloudwatch_log_group" {
  value = module.lambda_consumer.cloudwatch_log_group
}

output "lambda_arn" {
  value = module.lambda_consumer.arn
}

output "lambda_function_name" {
  value = module.lambda_consumer.function_name
}

output "lambda_alias_name" {
  value = module.lambda_consumer.alias_name
}

output "sqs_queue_url" {
  value = module.sqs_queue.sqs_queue_url
}

output "dead_letter_queue_url" {
  value = module.sqs_queue.dead_letter_queue_url
}
