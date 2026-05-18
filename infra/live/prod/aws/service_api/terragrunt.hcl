include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "security" {
  path = find_in_parent_folders("dependencies/security.hcl")
}

locals {
  cluster = read_terragrunt_config(find_in_parent_folders("dependencies/cluster.hcl"))
  network = read_terragrunt_config(find_in_parent_folders("dependencies/network.hcl"))
}

terraform {
  source = "../../../../modules//aws//service_api"
}

inputs = merge(
  {
    ecs_security_group_id = dependency.security.outputs.ecs_sg
  },
  local.cluster.inputs,
  local.network.inputs,
)
