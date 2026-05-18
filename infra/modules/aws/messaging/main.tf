module "lambda_worker_queue" {
  source = "../_shared/sqs"

  sqs_queue_name = local.lambda_worker_queue_name
  sqs_dlq_name   = local.lambda_worker_dlq_name
}

module "ecs_worker_queue" {
  source = "../_shared/sqs"

  sqs_queue_name = local.ecs_worker_queue_name
  sqs_dlq_name   = local.ecs_worker_dlq_name
}

resource "aws_sns_topic" "worker_events" {
  name = local.sns_topic_name
}

resource "aws_sns_topic_subscription" "lambda_worker_queue" {
  topic_arn = aws_sns_topic.worker_events.arn
  protocol  = "sqs"
  endpoint  = module.lambda_worker_queue.sqs_queue_arn

  raw_message_delivery = true

  depends_on = [aws_sqs_queue_policy.lambda_worker_queue_sns]
}

resource "aws_sns_topic_subscription" "ecs_worker_queue" {
  topic_arn = aws_sns_topic.worker_events.arn
  protocol  = "sqs"
  endpoint  = module.ecs_worker_queue.sqs_queue_arn

  raw_message_delivery = true

  depends_on = [aws_sqs_queue_policy.ecs_worker_queue_sns]
}

resource "aws_sqs_queue_policy" "lambda_worker_queue_sns" {
  queue_url = module.lambda_worker_queue.sqs_queue_url
  policy    = data.aws_iam_policy_document.lambda_worker_queue_sns_send.json
}

resource "aws_sqs_queue_policy" "ecs_worker_queue_sns" {
  queue_url = module.ecs_worker_queue.sqs_queue_url
  policy    = data.aws_iam_policy_document.ecs_worker_queue_sns_send.json
}

resource "aws_iam_policy" "topic_publish" {
  name   = "${local.sns_topic_name}-sns-publish-policy"
  policy = data.aws_iam_policy_document.topic_publish.json
}
