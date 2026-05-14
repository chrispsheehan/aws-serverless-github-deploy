dependency "network" {
  config_path = "${get_original_terragrunt_dir()}/../network"

  mock_outputs = {
    api_invoke_url = "https://mockapi123.execute-api.eu-west-2.amazonaws.com"
  }

  mock_outputs_allowed_terraform_commands = ["validate", "plan", "destroy", "init", "show"]
}

dependency "cognito" {
  config_path = "${get_original_terragrunt_dir()}/../cognito"

  mock_outputs = {
    user_pool_id        = "eu-west-2_mock"
    user_pool_client_id = "mock-user-pool-client-id"
    hosted_ui_url       = "https://mock-domain.auth.eu-west-2.amazoncognito.com"
    readonly_group_name = "readonly"
  }

  mock_outputs_allowed_terraform_commands = ["validate", "plan", "destroy", "init", "show"]
}

inputs = {
  api_invoke_url           = dependency.network.outputs.api_invoke_url
  auth_user_pool_id        = dependency.cognito.outputs.user_pool_id
  auth_user_pool_client_id = dependency.cognito.outputs.user_pool_client_id
  auth_hosted_ui_url       = dependency.cognito.outputs.hosted_ui_url
  auth_readonly_group_name = dependency.cognito.outputs.readonly_group_name
}
