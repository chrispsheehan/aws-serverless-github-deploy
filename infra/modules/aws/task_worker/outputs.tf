output "task_definition_arn" {
  value = module.task_worker.task_definition_arn
}

output "cloudwatch_log_group" {
  value = module.task_worker.cloudwatch_log_group
}

output "root_path" {
  value = module.task_worker.root_path
}

output "service_name" {
  value = module.task_worker.service_name
}
