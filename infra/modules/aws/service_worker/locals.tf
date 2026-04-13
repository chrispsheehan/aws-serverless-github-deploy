locals {
  task_worker_outputs = var.bootstrap ? null : one(data.terraform_remote_state.task_worker[*].outputs)

  task_definition_arn    = var.bootstrap ? "" : local.task_worker_outputs.task_definition_arn
  autoscaling_queue_name = var.bootstrap ? "not_set" : local.task_worker_outputs.sqs_queue_name
}
