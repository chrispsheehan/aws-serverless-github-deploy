include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "security" {
  config_path = "${get_original_terragrunt_dir()}/../security"

  mock_outputs = {
    load_balancer_sg = "sg-00000000000000001"
    api_vpc_link_sg  = "sg-00000000000000002"
    vpc_endpoint_sg  = "sg-00000000000000003"
    ecs_sg           = "sg-00000000000000004"
    runtime_sg       = "sg-00000000000000005"
    postgres_sg      = "sg-00000000000000006"
  }

  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "destroy", "init", "show", "graph-dependencies", "output-module-groups"]
}

dependency "database" {
  config_path = "${get_original_terragrunt_dir()}/../database"

  mock_outputs = {
    database_credentials_secret_arn = "arn:aws:secretsmanager:eu-west-2:111111111111:secret:mock-database-credentials"
    database_readwrite_endpoint     = "mock-database.cluster-abcdefghijkl.eu-west-2.rds.amazonaws.com"
    database_name                   = "app"
    database_port                   = 5432
    database_cluster_identifier     = "mock-database-cluster"
  }

  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "destroy", "init", "show", "graph-dependencies", "output-module-groups"]
}

terraform {
  source = "../../../../modules//aws//migrations"
}

inputs = merge(
  {
    runtime_security_group_id = dependency.security.outputs.runtime_sg
  },
  {
    database_credentials_secret_arn = dependency.database.outputs.database_credentials_secret_arn
    database_readwrite_endpoint     = dependency.database.outputs.database_readwrite_endpoint
    database_name                   = dependency.database.outputs.database_name
    database_port                   = dependency.database.outputs.database_port
    database_cluster_identifier     = dependency.database.outputs.database_cluster_identifier
  },
)
