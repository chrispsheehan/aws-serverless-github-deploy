include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  frontend_runtime = read_terragrunt_config(find_in_parent_folders("dependencies/frontend.hcl"))
}

terraform {
  source = "../../../../modules//aws//frontend"
}

inputs = local.frontend_runtime.inputs
