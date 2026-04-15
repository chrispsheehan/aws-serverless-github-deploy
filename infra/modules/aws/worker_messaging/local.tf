locals {
  sns_topic_name = "${var.project_name}-${var.environment}-worker-events"

  lambda_worker_queue_name = "${var.project_name}-${var.environment}-lambda-worker-queue"
  lambda_worker_dlq_name   = "${var.project_name}-${var.environment}-lambda-worker-dlq"

  ecs_worker_queue_name = "${var.project_name}-${var.environment}-ecs-worker-queue"
  ecs_worker_dlq_name   = "${var.project_name}-${var.environment}-ecs-worker-dlq"
}
