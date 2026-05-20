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

  mock_outputs_allowed_terraform_commands = ["validate", "plan", "destroy", "init", "show", "graph-dependencies", "output-module-groups"]
}
