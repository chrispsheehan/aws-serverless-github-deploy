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

  mock_outputs_merge_strategy_with_state = "shallow"
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "destroy", "init", "show", "graph-dependencies", "output-module-groups"]
}

terraform {
  source = "../../../../modules//aws//database"
}

inputs = merge(
  {
    database_security_group_id = dependency.security.outputs.postgres_sg
  },
  {
    database_name                         = "app"
    backup_retention_period               = 7
    rds_min_capacity                      = 0.5
    rds_max_capacity                      = 2.0
    rds_max_reader_count                  = 1
    performance_insights_enabled          = true
    performance_insights_retention_period = 7
  },
)
