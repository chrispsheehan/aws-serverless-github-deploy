locals {
  sqs_queue_name = "${var.project_name}-${var.environment}-ecs-worker-queue"
  sqs_dlq_name   = "${var.project_name}-${var.environment}-ecs-worker-dlq"
}
