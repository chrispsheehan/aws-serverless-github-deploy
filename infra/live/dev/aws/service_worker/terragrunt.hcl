include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  runtime_security = read_terragrunt_config(find_in_parent_folders("dependencies/ecs_runtime_security.hcl"))
}

terraform {
  source = "../../../../modules//aws//service_worker"
}

inputs = local.runtime_security.inputs
