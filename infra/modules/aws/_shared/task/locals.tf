locals {
  cloudwatch_log_name          = "/ecs/${var.service_name}"
  cloudwatch_otel_log_name     = "/ecs/${var.service_name}/otel"
  image_uri                    = var.image_uri
  aws_otel_collector_image_uri = var.aws_otel_collector_image_uri
  debug_image_uri              = var.debug_image_uri
  root_path_prefix             = var.root_path != "" ? "/${var.root_path}" : ""

  shared_environment = [
    {
      name  = "AWS_REGION"
      value = "${var.aws_region}"
    },
    {
      name  = "AWS_SERVICE_NAME"
      value = "${var.service_name}"
    },
    {
      name  = "IMAGE"
      value = "${local.image_uri}"
    },
    {
      name  = "AWS_XRAY_ENDPOINT"
      value = "http://localhost:4317"
    },
    {
      name  = "ROOT_PATH"
      value = local.root_path_prefix
    },
  ]

  otel_environment = [
    {
      name  = "AWS_REGION"
      value = "${var.aws_region}"
    },
    {
      name  = "OTEL_SAMPLING_PERCENTAGE"
      value = tostring(var.otel_sampling_percentage)
    },
    {
      name  = "OTEL_ENDPOINT"
      value = "0.0.0.0:4317"
    },
  ]

  base_containers = [
    local.svc-container
  ]

  debug_sidecar = var.local_tunnel ? [local.debug-container] : []
  xray_sidecar  = var.xray_enabled ? [local.otel-collector] : []

  container_definitions = concat(
    local.base_containers,
    local.debug_sidecar,
    local.xray_sidecar
  )

  svc-container = {
    name        = var.service_name
    networkMode = "awsvpc"
    image       = local.image_uri

    portMappings = [
      {
        name          = "${var.service_name}-${var.container_port}-tcp"
        containerPort = var.container_port
        hostPort      = var.container_port
        protocol      = "tcp"
        appProtocol   = "http"
      }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "${local.cloudwatch_log_name}"
        "awslogs-region"        = "${var.aws_region}"
        "awslogs-stream-prefix" = "ecs"
      }
    }

    essential   = true
    environment = concat(local.shared_environment, var.additional_env_vars)

    command = var.command
  }

  otel-collector = {
    name  = "${var.service_name}-otel-collector"
    image = local.aws_otel_collector_image_uri

    portMappings = [
      {
        name          = "${var.service_name}-otel-collector-${var.container_port}-tcp"
        containerPort = 4317
        hostPort      = 4317
        protocol      = "tcp"
        appProtocol   = "http"
      }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "${local.cloudwatch_otel_log_name}"
        "awslogs-region"        = "${var.aws_region}"
        "awslogs-stream-prefix" = "ecs"
      }
    }

    command = ["--config", "/opt/aws/aws-otel-collector/etc/collector-config.yaml"]

    essential   = false
    environment = local.otel_environment
  }

  debug-container = {
    name  = "${var.service_name}-debug"
    image = local.debug_image_uri

    command = ["sleep", "infinity"]

    essential = false
  }
}
