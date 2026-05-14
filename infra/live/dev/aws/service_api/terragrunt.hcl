include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  runtime_security = read_terragrunt_config(find_in_parent_folders("dependencies/ecs_runtime_security.hcl"))
  task_api         = read_terragrunt_config(find_in_parent_folders("dependencies/task_api.hcl"))
  cluster          = read_terragrunt_config(find_in_parent_folders("dependencies/cluster.hcl"))
  network_runtime  = read_terragrunt_config(find_in_parent_folders("dependencies/network_runtime.hcl"))
}

terraform {
  source = "../../../../modules//aws//service_api"
}

inputs = merge(
  local.runtime_security.inputs,
  local.task_api.inputs,
  local.cluster.inputs,
  local.network_runtime.inputs,
)
