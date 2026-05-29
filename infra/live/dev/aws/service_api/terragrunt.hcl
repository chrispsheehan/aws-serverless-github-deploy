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

dependency "cluster" {
  config_path = "${get_original_terragrunt_dir()}/../cluster"

  mock_outputs = {
    cluster_id   = "mock-cluster-id"
    cluster_name = "mock-cluster"
  }

  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "destroy", "init", "show", "graph-dependencies", "output-module-groups"]
}

dependency "network" {
  config_path = "${get_original_terragrunt_dir()}/../network"

  mock_outputs = {
    default_target_group_arn  = "arn:aws:elasticloadbalancing:eu-west-2:111111111111:targetgroup/mock-default/1234567890abcdef"
    load_balancer_arn         = "arn:aws:elasticloadbalancing:eu-west-2:111111111111:loadbalancer/app/mock-internal/1234567890abcdef"
    default_http_listener_arn = "arn:aws:elasticloadbalancing:eu-west-2:111111111111:listener/app/mock-internal/1234567890abcdef/abcdef1234567890"
    load_balancer_arn_suffix  = "app/mock-internal/1234567890abcdef"
    target_group_arn_suffix   = "targetgroup/mock-default/1234567890abcdef"
    internal_invoke_url       = "http://mock-internal-123456.eu-west-2.elb.amazonaws.com"
    api_id                    = "mockapi123"
    api_invoke_url            = "https://mockapi123.execute-api.eu-west-2.amazonaws.com"
    api_execution_arn         = "arn:aws:execute-api:eu-west-2:111111111111:mockapi123"
    api_stage_name            = "$default"
    vpc_link_id               = "vpclink-mock123"
    http_api_authorizer_id    = "auth-mock123"
  }

  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "destroy", "init", "show", "graph-dependencies", "output-module-groups"]
}

terraform {
  source = "../../../../modules//aws//service_api"
}

inputs = merge(
  {
    ecs_security_group_id = dependency.security.outputs.ecs_sg
    assign_public_ip      = true
  },
  {
    cluster_id   = dependency.cluster.outputs.cluster_id
    cluster_name = dependency.cluster.outputs.cluster_name
  },
  {
    network_default_target_group_arn  = dependency.network.outputs.default_target_group_arn
    network_load_balancer_arn         = dependency.network.outputs.load_balancer_arn
    network_default_http_listener_arn = dependency.network.outputs.default_http_listener_arn
    network_load_balancer_arn_suffix  = dependency.network.outputs.load_balancer_arn_suffix
    network_target_group_arn_suffix   = dependency.network.outputs.target_group_arn_suffix
    network_internal_invoke_url       = dependency.network.outputs.internal_invoke_url
    network_api_id                    = dependency.network.outputs.api_id
    network_api_invoke_url            = dependency.network.outputs.api_invoke_url
    network_api_execution_arn         = dependency.network.outputs.api_execution_arn
    network_api_stage_name            = dependency.network.outputs.api_stage_name
    network_vpc_link_id               = dependency.network.outputs.vpc_link_id
    network_http_api_authorizer_id    = dependency.network.outputs.http_api_authorizer_id
  },
)
