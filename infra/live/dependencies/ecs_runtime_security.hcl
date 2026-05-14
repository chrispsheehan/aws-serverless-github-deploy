dependency "security" {
  config_path = "${get_original_terragrunt_dir()}/../security"

  mock_outputs = {
    ecs_sg = "sg-00000000000000004"
  }

  mock_outputs_allowed_terraform_commands = ["validate", "plan", "destroy", "init", "show"]
}

inputs = {
  ecs_security_group_id = dependency.security.outputs.ecs_sg
}
