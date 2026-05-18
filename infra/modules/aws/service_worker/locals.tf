locals {
  task_definition_arn    = var.bootstrap ? "" : var.task_definition_arn
  autoscaling_queue_name = var.bootstrap ? "not_set" : var.ecs_worker_queue_name
}
