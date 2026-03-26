locals {
  sqs_chunk_size = 5
  lambda_name    = "${var.environment}-${var.project_name}-lambda-worker"
  sqs_queue_name = "${var.project_name}-${var.environment}-lambda-worker-queue"
  sqs_dlq_name   = "${var.project_name}-${var.environment}-lambda-worker-dlq"
}