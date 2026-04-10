output "invoke_url" {
  value = local.invoke_url
}

output "service_name" {
  value = aws_ecs_service.service.name
}

output "codedeploy_app_name" {
  value = var.deployment_strategy != "rolling" ? aws_codedeploy_app.ecs[0].name : null
}

output "codedeploy_deployment_group_name" {
  value = local.enable_codedeploy ? aws_codedeploy_deployment_group.ecs[0].deployment_group_name : null
}

output "blue_target_group_name" {
  value = local.enable_codedeploy ? local.blue_target_group_name : null
}

output "green_target_group_name" {
  value = local.enable_codedeploy ? aws_lb_target_group.green_target_group[0].name : null
}
