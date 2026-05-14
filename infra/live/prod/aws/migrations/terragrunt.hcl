include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  runtime_security = read_terragrunt_config(find_in_parent_folders("dependencies/lambda_runtime_security.hcl"))
  database         = read_terragrunt_config(find_in_parent_folders("dependencies/database.hcl"))
}

terraform {
  source = "../../../../modules//aws//migrations"
}

inputs = merge(local.runtime_security.inputs, local.database.inputs)
