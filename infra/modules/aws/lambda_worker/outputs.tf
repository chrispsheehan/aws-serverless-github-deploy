output "cloudwatch_log_group" {
  value = module.lambda_worker.cloudwatch_log_group
}

output "lambda_arn" {
  value = module.lambda_worker.arn
}

output "lambda_function_name" {
  value = module.lambda_worker.function_name
}

output "lambda_alias_name" {
  value = module.lambda_worker.alias_name
}

output "sqs_queue_url" {
  value = module.sqs_queue.sqs_queue_url
}

output "sqs_queue_name" {
  value = module.sqs_queue.sqs_queue_name
}

output "sqs_queue_read_policy_arn" {
  value = module.sqs_queue.sqs_queue_read_policy_arn
}

output "dead_letter_queue_url" {
  value = module.sqs_queue.dead_letter_queue_url
}
