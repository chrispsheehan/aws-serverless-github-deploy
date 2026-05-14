include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  runtime_security = read_terragrunt_config(find_in_parent_folders("dependencies/lambda_runtime_security.hcl"))
}

terraform {
  source = "../../../../modules//aws//migrations"
}

inputs = local.runtime_security.inputs
