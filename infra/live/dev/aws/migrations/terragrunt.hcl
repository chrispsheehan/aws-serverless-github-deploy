include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "security" {
  path = find_in_parent_folders("dependencies/security.hcl")
}

locals {
  database = read_terragrunt_config(find_in_parent_folders("dependencies/database.hcl"))
}

terraform {
  source = "../../../../modules//aws//migrations"
}

inputs = merge(
  {
    runtime_security_group_id = dependency.security.outputs.runtime_sg
  },
  local.database.inputs,
)
