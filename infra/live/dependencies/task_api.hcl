dependency "task_api" {
  config_path = "${get_original_terragrunt_dir()}/../task_api"

  mock_outputs = {
    task_definition_arn = "arn:aws:ecs:eu-west-2:111111111111:task-definition/mock-task-api:1"
  }

  mock_outputs_allowed_terraform_commands = ["validate", "plan", "destroy", "init", "show"]
}

inputs = {
  task_definition_arn = dependency.task_api.outputs.task_definition_arn
}
