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
      value = data.terraform_remote_state.lambda_worker.outputs.sqs_queue_url
    }
  ]
  additional_runtime_policy_arns = [
    data.terraform_remote_state.lambda_worker.outputs.sqs_queue_read_policy_arn
  ]

  root_path    = ""
  service_name = "ecs-worker"
  command      = ["python", "-u", "app.py"]
}
