output "service_name" {
  value = module.service_consumer.service_name
}

output "cluster_name" {
  value = data.terraform_remote_state.cluster.outputs.cluster_name
}

output "codedeploy_app_name" {
  value = module.service_consumer.codedeploy_app_name
}

output "codedeploy_deployment_group_name" {
  value = module.service_consumer.codedeploy_deployment_group_name
}

output "container_port" {
  value = var.container_port
}
