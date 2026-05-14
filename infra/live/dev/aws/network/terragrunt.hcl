include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  network_dependencies = read_terragrunt_config(find_in_parent_folders("dependencies/network.hcl"))
}

terraform {
  source = "../../../../modules//aws//network"
}

inputs = local.network_dependencies.inputs
