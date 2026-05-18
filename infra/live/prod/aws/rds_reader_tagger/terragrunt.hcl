include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  database = read_terragrunt_config(find_in_parent_folders("dependencies/database.hcl"))
}

terraform {
  source = "../../../../modules//aws//rds_reader_tagger"
}

inputs = local.database.inputs
