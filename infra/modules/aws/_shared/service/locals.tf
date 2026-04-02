locals {
  network_count = var.connection_type == "internal_dns" || var.connection_type == "vpc_link" ? 1 : 0
  use_vpc_link  = var.connection_type == "vpc_link"

  load_balancers = var.connection_type == "internal_dns" || var.connection_type == "vpc_link" ? [{
    target_group_arn = module.network[0].target_group_arn
    container_name   = var.service_name
    container_port   = var.container_port
  }] : []

  base_url = var.connection_type == "internal" ? null : (
    var.connection_type == "internal_dns"
    ? data.terraform_remote_state.network.outputs.internal_invoke_url
    : data.terraform_remote_state.api.outputs.invoke_url
  )
  invoke_url = var.root_path == "" ? local.base_url : "${local.base_url}/${var.root_path}"
}
