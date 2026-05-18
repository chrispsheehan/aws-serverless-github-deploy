include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "security" {
  path = find_in_parent_folders("dependencies/security.hcl")
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

  mock_outputs_allowed_terraform_commands = ["validate", "plan", "destroy", "init", "show"]
}

inputs = {
  load_balancer_sg         = dependency.security.outputs.load_balancer_sg
  api_vpc_link_sg          = dependency.security.outputs.api_vpc_link_sg
  vpc_endpoint_sg          = dependency.security.outputs.vpc_endpoint_sg
  auth_user_pool_client_id = dependency.cognito.outputs.auth_user_pool_client_id
  auth_issuer_url          = dependency.cognito.outputs.auth_issuer_url
}
