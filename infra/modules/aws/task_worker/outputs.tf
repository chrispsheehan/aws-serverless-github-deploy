output "task_definition_arn" {
  value = module.task_consumer.task_definition_arn
}

output "cloudwatch_log_group" {
  value = module.task_consumer.cloudwatch_log_group
}

output "root_path" {
  value = module.task_consumer.root_path
}

output "service_name" {
  value = module.task_consumer.service_name
}
