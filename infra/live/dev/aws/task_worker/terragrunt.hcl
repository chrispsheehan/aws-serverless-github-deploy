include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  messaging = read_terragrunt_config(find_in_parent_folders("dependencies/messaging.hcl"))
  database  = read_terragrunt_config(find_in_parent_folders("dependencies/database.hcl"))
}

terraform {
  source = "../../../../modules//aws//task_worker"
}

inputs = merge(local.messaging.inputs, local.database.inputs)
