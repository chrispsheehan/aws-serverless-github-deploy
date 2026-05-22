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

terraform {
  source = "../../../../modules//aws//network"
}

dependency "cognito" {
  config_path = "${get_original_terragrunt_dir()}/../cognito"

  mock_outputs = {
    auth_user_pool_client_id = "mock-user-pool-client-id"
    auth_issuer_url          = "https://cognito-idp.eu-west-2.amazonaws.com/eu-west-2_mock"
  }

  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "destroy", "init", "show", "graph-dependencies", "output-module-groups"]
}

inputs = {
  load_balancer_sg         = dependency.security.outputs.load_balancer_sg
  api_vpc_link_sg          = dependency.security.outputs.api_vpc_link_sg
  vpc_endpoint_sg          = dependency.security.outputs.vpc_endpoint_sg
  auth_user_pool_client_id = dependency.cognito.outputs.auth_user_pool_client_id
  auth_issuer_url          = dependency.cognito.outputs.auth_issuer_url
}
