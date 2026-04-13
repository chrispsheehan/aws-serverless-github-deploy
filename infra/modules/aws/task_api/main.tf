module "task_api" {
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

  additional_env_vars            = []
  additional_runtime_policy_arns = []

  root_path    = "blue-green-api"
  service_name = "ecs-blue-green-api"
  command      = ["python", "-u", "app.py"]
}
