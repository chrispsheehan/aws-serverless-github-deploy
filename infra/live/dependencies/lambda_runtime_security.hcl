dependency "security" {
  config_path = "${get_original_terragrunt_dir()}/../security"

  mock_outputs = {
    runtime_sg = "sg-00000000000000005"
  }

  mock_outputs_allowed_terraform_commands = ["validate", "plan", "destroy", "init", "show"]
}

inputs = {
  runtime_security_group_id = dependency.security.outputs.runtime_sg
}
