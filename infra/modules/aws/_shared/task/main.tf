resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${var.service_name}-ecs-task-execution-role"
  description        = "Role used to pull from ECR and setup Cloudwatch logging access"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_policy" "logs_access_policy" {
  name   = "${var.service_name}-logs-access-policy"
  policy = data.aws_iam_policy_document.logs_policy.json
}

resource "aws_iam_policy" "ecr_access_policy" {
  name   = "${var.service_name}-ecr-access-policy"
  policy = data.aws_iam_policy_document.ecr_policy.json
}

resource "aws_iam_policy" "ssm_messages_policy" {
  name   = "${var.service_name}-ssm-messages-policy"
  policy = data.aws_iam_policy_document.ssm_messages.json
}

resource "aws_iam_role_policy_attachment" "logs_access_policy_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.logs_access_policy.arn
}

resource "aws_iam_role_policy_attachment" "ecr_access_policy_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecr_access_policy.arn
}

resource "aws_iam_role_policy_attachment" "ssm_messages_policy_attachment" {
  count = var.local_tunnel ? 1 : 0

  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ssm_messages_policy.arn
}

resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = local.cloudwatch_log_name
  retention_in_days = 1
}

resource "aws_cloudwatch_log_group" "ecs_otel_log_group" {
  name              = local.cloudwatch_otel_log_name
  retention_in_days = 1
}

resource "aws_iam_role" "ecs_task_role" {
  name               = "${var.service_name}-ecs-task-role"
  description        = "Role used to give the task runtime access"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_policy" "xray_put_policy" {
  name   = "${var.service_name}-xray-put-policy"
  policy = data.aws_iam_policy_document.xray_put.json
}

resource "aws_iam_role_policy_attachment" "xray_put_policy_attachment" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.xray_put_policy.arn
}

resource "aws_iam_role_policy_attachment" "task_runtime_additional_attachments" {
  for_each = { for idx, arn in var.additional_runtime_policy_arns : idx => arn }

  role       = aws_iam_role.ecs_task_role.name
  policy_arn = each.value
}

resource "aws_ecs_task_definition" "task" {
  family                   = "${var.service_name}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn

  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }

  container_definitions = jsonencode(local.container_definitions)
}