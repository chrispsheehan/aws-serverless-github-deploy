output "task_definition_arn" {
  value = module.task_api.task_definition_arn
}

output "cloudwatch_log_group" {
  value = module.task_api.cloudwatch_log_group
}

output "root_path" {
  value = module.task_api.root_path
}

output "service_name" {
  value = module.task_api.service_name
}
