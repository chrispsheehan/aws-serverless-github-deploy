locals {
  sqs_chunk_size = 5
  lambda_name    = "${var.environment}-${var.project_name}-consumer"
}