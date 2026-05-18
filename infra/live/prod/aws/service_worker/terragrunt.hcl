include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "security" {
  path = find_in_parent_folders("dependencies/security.hcl")
}

locals {
  worker_messaging = read_terragrunt_config(find_in_parent_folders("dependencies/worker_messaging.hcl"))
  cluster          = read_terragrunt_config(find_in_parent_folders("dependencies/cluster.hcl"))
  network          = read_terragrunt_config(find_in_parent_folders("dependencies/network.hcl"))
}

terraform {
  source = "../../../../modules//aws//service_worker"
}

inputs = merge(
  {
    ecs_security_group_id = dependency.security.outputs.ecs_sg
  },
  local.worker_messaging.inputs,
  local.cluster.inputs,
  local.network.inputs,
)
