module "sqs_queue" {
  source = "../_shared/sqs"

  sqs_queue_name = local.sqs_queue_name
  sqs_dlq_name   = local.sqs_dlq_name
}

module "task_worker" {
  source = "../_shared/task"

  project_name        = var.project_name
  ecr_repository_name = var.ecr_repository_name
  aws_region          = var.aws_region
  container_port      = var.container_port
  cpu                 = var.cpu
  memory              = var.memory

  image_uri                    = var.image_uri
  debug_image_uri              = var.debug_image_uri
  aws_otel_collector_image_uri = var.aws_otel_collector_image_uri
  otel_sampling_percentage     = var.otel_sampling_percentage

  local_tunnel = var.local_tunnel
  xray_enabled = var.xray_enabled

  additional_env_vars = [
    {
      name  = "AWS_SQS_QUEUE_URL"
      value = module.sqs_queue.sqs_queue_url
    }
  ]
  additional_runtime_policy_arns = [
    module.sqs_queue.sqs_queue_read_policy_arn
  ]

  health_check = {
    command      = ["CMD-SHELL", "python -c \"import boto3, os; boto3.client('sqs', region_name=os.environ['AWS_REGION']).get_queue_attributes(QueueUrl=os.environ['AWS_SQS_QUEUE_URL'], AttributeNames=['QueueArn'])\""]
    interval     = 60
    timeout      = 5
    retries      = 3
    start_period = 10
  }

  root_path    = ""
  service_name = "ecs-worker"
  command      = ["python", "-u", "app.py"]
}
