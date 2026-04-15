locals {
  task_worker_outputs      = var.bootstrap ? null : one(data.terraform_remote_state.task_worker[*].outputs)
  worker_messaging_outputs = var.bootstrap ? null : one(data.terraform_remote_state.worker_messaging[*].outputs)

  task_definition_arn    = var.bootstrap ? "" : local.task_worker_outputs.task_definition_arn
  autoscaling_queue_name = var.bootstrap ? "not_set" : local.worker_messaging_outputs.ecs_worker_queue_name
}
