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
  value = data.terraform_remote_state.worker_messaging.outputs.lambda_worker_queue_url
}

output "sqs_queue_name" {
  value = data.terraform_remote_state.worker_messaging.outputs.lambda_worker_queue_name
}

output "sqs_queue_read_policy_arn" {
  value = data.terraform_remote_state.worker_messaging.outputs.lambda_worker_queue_read_policy_arn
}

output "dead_letter_queue_url" {
  value = data.terraform_remote_state.worker_messaging.outputs.lambda_worker_dead_letter_queue_url
}
