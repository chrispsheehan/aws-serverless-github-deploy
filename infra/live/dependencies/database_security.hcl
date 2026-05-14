dependency "security" {
  config_path = "${get_original_terragrunt_dir()}/../security"

  mock_outputs = {
    postgres_sg = "sg-00000000000000006"
  }

  mock_outputs_allowed_terraform_commands = ["validate", "plan", "destroy", "init", "show"]
}

inputs = {
  database_security_group_id = dependency.security.outputs.postgres_sg
}
